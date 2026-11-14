import Foundation
import Observation
import SudokuKit

/// Défi reçu par un lien ou un message partagé.
struct Challenge: Codable, Hashable {
    var seconds: Int
    var hints: Int
}

enum GameMode: Codable, Hashable {
    /// Partie de niveau : compte pour le déblocage et les meilleurs temps.
    case level
    /// Grille du jour (`DayStamp` de la grille).
    case daily
    /// Grille ouverte depuis un code partagé, éventuellement avec un défi.
    case shared(Challenge?)

    var challenge: Challenge? {
        if case .shared(let c) = self { return c }
        return nil
    }
}

/// État sauvegardé d'une partie en cours.
struct SavedGame: Codable, Hashable {
    var code: PuzzleCode
    var mode: GameMode
    var level: Level
    var givens: Grid
    var solution: Grid
    var values: [UInt8]
    var notes: [UInt16]
    var elapsed: Int
    var mistakes: Int
    var hintsUsed: Int
    var hintsEnabled: Bool
    var updatedAt: Date
    /// Journal des coups (`Move.packed`). Absent des sauvegardes d'avant le replay.
    var moves: [Int]?
    /// Partie en mode validation (voir `GameSession.strict`). Absent des anciennes sauvegardes : mode normal.
    var strict: Bool?
    /// Entraînement (voir `GameSession.practice`). Absent = non.
    var practice: Bool?
}

extension SavedGame {
    var title: String { GameMode.title(mode, code: code, level: level) }
}

extension GameMode {
    static func title(_ mode: GameMode, code: PuzzleCode, level: Level) -> String {
        switch mode {
        case .level:
            if case .custom(let grid) = code, let legend = Legends.find(grid) { return legend.name }
            return level.name
        case .daily: return L("Du jour · %@", level.name)
        case .shared(let c):
            if case .custom(let grid) = code, let legend = Legends.find(grid) { return L("Légende · %@", legend.name) }
            if case .custom = code { return L("Grille créée · %@", level.name) }
            return c == nil ? L("Grille partagée · %@", level.name) : L("Défi · %@", level.name)
        }
    }
}

/// Une partie en cours : toute la logique de jeu, sans interface.
@Observable
final class GameSession: Identifiable {
    let id = UUID()
    let puzzle: Puzzle
    let mode: GameMode
    /// Suit le réglage tant qu'aucun indice n'a été utilisé dans cette partie ; ensuite les indices restent activés.
    private(set) var hintsEnabled: Bool
    /// Mode validation : aucune erreur n'est signalée pendant la partie, la grille se valide d'un coup une fois remplie.
    /// Toujours actif à partir de Diabolique, et à tous les niveaux avec le réglage « Mode difficile ». Fixé au début
    /// (levé seulement quand on continue une grille ratée).
    private(set) var strict: Bool
    /// Entraînement : grille déjà jouée, ou grille ratée qu'on continue. Rien ne compte (score total, classements,
    /// statistiques, déblocage, série, succès), pour qu'on ne puisse pas apprendre une grille par cœur à force d'essais.
    private(set) var practice: Bool

    private(set) var values: [UInt8]
    private(set) var notes: [UInt16]
    var selected: Int?
    var notesMode = false
    private(set) var mistakes: Int
    private(set) var hintsUsed: Int
    private(set) var elapsed: Int
    private(set) var isComplete = false
    /// Grille ratée : trop d'erreurs, ou validation d'une grille fausse. La partie est terminée.
    private(set) var isFailed = false
    /// Abandonnée : plus aucune sauvegarde en tant que partie en cours.
    var isAbandoned = false

    private(set) var activeHint: Hint?
    /// 1 = zone et technique, 2 = case, (3 = appliqué → l'indice disparaît)
    private(set) var hintStage = 0

    /// Dernier évènement, pour l'animation et l'haptique.
    private(set) var lastEvent: Event?
    /// Journal des coups, pour revoir la partie depuis l'historique. `nil` : partie reprise d'une ancienne
    /// sauvegarde sans journal (le début manque, donc pas de replay).
    private(set) var moves: [Int]?
    private var applyingHint = false

    static let maxHints = 3

    enum Event: Equatable {
        case placed(cell: Int, correct: Bool, completedUnits: Int, nonce: Int)
        case completed
        case failed
    }
    private var eventNonce = 0

    /// Appelé après chaque modification (sauvegarde).
    var onChange: (() -> Void)?

    /// Score en direct : points des chiffres justes posés (sans les erreurs). `nil` tant qu'il n'est pas calculé,
    /// et toujours en mode validation (il trahirait les erreurs).
    private(set) var liveEarned: Int?
    /// Le dernier coup qui a rapporté des points, pour l'afficher un instant (« +30 »).
    private(set) var lastGain: Gain?
    struct Gain: Equatable {
        let points: Int
        let lucky: Bool
        let nonce: Int
    }
    var liveScore: Int? { liveEarned.map { max(0, $0 - mistakes * Scoring.mistakePenalty) } }
    /// Les coups partent vers un seul calcul en arrière-plan, dans l'ordre (juger un coup peut prendre un instant).
    @ObservationIgnored private var scoreFeed: AsyncStream<ScoredMove>.Continuation?

    init(puzzle: Puzzle, mode: GameMode, hintsEnabled: Bool, strict: Bool, practice: Bool = false, saved: SavedGame? = nil) {
        self.puzzle = puzzle
        self.mode = mode
        self.hintsEnabled = (saved?.hintsUsed ?? 0) > 0 || hintsEnabled
        // Une partie reprise garde les règles avec lesquelles elle a commencé.
        self.strict = saved.map { $0.strict ?? false } ?? strict
        self.practice = saved.map { $0.practice ?? false } ?? practice
        values = saved?.values ?? puzzle.givens.cells
        notes = saved?.notes ?? [UInt16](repeating: 0, count: 81)
        mistakes = saved?.mistakes ?? 0
        hintsUsed = saved?.hintsUsed ?? 0
        elapsed = saved?.elapsed ?? 0
        moves = saved == nil ? [] : saved?.moves
        isComplete = values == puzzle.solution.cells
        startLiveScore()
    }

    // Pas de deinit : quand la partie disparaît, `scoreFeed` aussi, et le flux (donc le calcul) s'arrête.

    private func startLiveScore() {
        guard !strict, let moves else { return }
        let (stream, feed) = AsyncStream.makeStream(of: ScoredMove.self)
        scoreFeed = feed
        let replayed = moves.compactMap(Move.init(packed:)).filter(\.isDigit)
        for m in replayed { feed.yield(m.scored) }
        let (givens, solution, level) = (puzzle.givens, puzzle.solution, puzzle.level)
        let replayedCount = replayed.count
        Task.detached(priority: .userInitiated) { [weak self] in
            var tracker = ScoreTracker(givens: givens, solution: solution, level: level)
            var count = 0
            for await move in stream {
                let verdict = tracker.record(move)
                count += 1
                let earned = tracker.earned
                // Pas d'annonce pour les coups d'une partie reprise.
                let gain = count > replayedCount && verdict.points > 0 ? verdict : nil
                await MainActor.run {
                    guard let self else { return }
                    self.liveEarned = earned
                    if let gain {
                        self.eventNonce += 1
                        self.lastGain = Gain(points: gain.points, lucky: gain.judgement == .guessed || gain.judgement == .corrected, nonce: self.eventNonce)
                    }
                }
            }
        }
        if moves.isEmpty { liveEarned = 0 }
    }

    var snapshot: SavedGame {
        SavedGame(code: puzzle.code, mode: mode, level: puzzle.level, givens: puzzle.givens, solution: puzzle.solution,
                  values: values, notes: notes, elapsed: elapsed, mistakes: mistakes, hintsUsed: hintsUsed,
                  hintsEnabled: hintsEnabled, updatedAt: .now, moves: moves, strict: strict,
                  practice: practice ? true : nil)
    }

    /// La partie telle qu'elle a été jouée, si son journal est complet.
    var playback: Playback? { moves.map { Playback(givens: puzzle.givens, solution: puzzle.solution, moves: $0) } }

    private func log(_ cell: Int, _ digit: UInt8, _ kind: Move.Kind) {
        let move = Move(cell: cell, digit: digit, kind: kind, time: elapsed)
        moves?.append(move.packed)
        if move.isDigit { scoreFeed?.yield(move.scored) }
    }

    /// Change les notes d'une case et inscrit chaque note ajoutée ou retirée au journal (pour le replay).
    private func setNotes(_ i: Int, _ mask: UInt16) {
        let old = notes[i]
        guard old != mask else { return }
        for d in Sudoku.digits(old & ~mask) { log(i, d, .noteOff) }
        for d in Sudoku.digits(mask & ~old) { log(i, d, .noteOn) }
        notes[i] = mask
    }

    // MARK: - Lecture

    func isGiven(_ i: Int) -> Bool { puzzle.givens[i] != 0 }
    func isWrong(_ i: Int) -> Bool { values[i] != 0 && values[i] != puzzle.solution[i] }

    func hasConflict(_ i: Int) -> Bool {
        let v = values[i]
        return v != 0 && Sudoku.peers[i].contains { values[$0] == v }
    }

    /// Nombre d'exemplaires d'un chiffre placés : à 9, la touche est grisée. On ne compte que les justes,
    /// sauf en mode validation où rien ne doit trahir une erreur.
    func placedCount(_ d: UInt8) -> Int {
        (0..<81).reduce(0) { $0 + (values[$1] == d && (strict || puzzle.solution[$1] == d) ? 1 : 0) }
    }

    var hintsRemaining: Int { hintsEnabled ? max(0, Self.maxHints - hintsUsed) : 0 }
    /// La partie est finie, gagnée ou ratée : plus aucune saisie.
    var isOver: Bool { isComplete || isFailed }
    /// Erreurs tolérées (`nil` en mode validation) : une de plus et la grille est ratée.
    var mistakeLimit: Int? { strict || practice ? nil : puzzle.level.mistakeLimit }
    /// Les chiffres faux peuvent-ils être montrés ? Jamais en mode validation, sauf une fois la grille ratée.
    var revealsMistakes: Bool { !strict || isFailed }
    /// Mode validation : la grille est pleine, le joueur peut la faire vérifier.
    var canValidate: Bool { strict && !isOver && !values.contains(0) }

    /// Le réglage des indices a changé : il s'applique tout de suite, sauf si un indice a déjà servi dans cette partie.
    func syncHints(_ enabled: Bool) {
        guard hintsUsed == 0, hintsEnabled != enabled else { return }
        hintsEnabled = enabled
        if !enabled { clearHint() }
        changed()
    }
    var filledCount: Int { values.filter { $0 != 0 }.count }

    // MARK: - Actions

    func select(_ i: Int) {
        selected = i
    }

    func moveSelection(dRow: Int, dCol: Int) {
        let current = selected ?? 40
        let r = (Sudoku.row(current) + dRow + 9) % 9
        let c = (Sudoku.col(current) + dCol + 9) % 9
        selected = r * 9 + c
    }

    func input(_ d: UInt8) {
        guard let i = selected, !isGiven(i), !isOver else { return }
        if notesMode && values[i] == 0 {
            setNotes(i, notes[i] ^ Sudoku.bit(d))
            changed()
        } else {
            place(i, d)
        }
    }

    private func place(_ i: Int, _ d: UInt8) {
        guard values[i] != d else { return }
        values[i] = d
        log(i, d, applyingHint ? .hint : .player)
        setNotes(i, 0)
        let correct = d == puzzle.solution[i]
        // En mode validation, un chiffre faux se comporte exactement comme un chiffre juste.
        let looksRight = strict || correct
        if looksRight && SettingKey.bool(SettingKey.autoRemoveNotes) {
            for p in Sudoku.peers[i] { setNotes(p, notes[p] & ~Sudoku.bit(d)) }
        }
        if !correct && !strict { mistakes += 1 }
        if activeHint?.cell == i { clearHint() }

        let completedUnits = looksRight
            ? Sudoku.unitsOfCell[i].filter { u in Sudoku.units[u].allSatisfy { strict ? values[$0] != 0 : values[$0] == puzzle.solution[$0] } }.count
            : 0
        eventNonce += 1
        lastEvent = .placed(cell: i, correct: looksRight, completedUnits: completedUnits, nonce: eventNonce)

        if !strict && values == puzzle.solution.cells {
            win()
        } else if let limit = mistakeLimit, mistakes > limit {
            fail()
        }
        changed()
    }

    /// Mode validation : vérifie la grille pleine. Juste, la partie est gagnée ; sinon elle est ratée,
    /// et les chiffres faux sont enfin montrés et comptés.
    func validate() {
        guard canValidate else { return }
        if values == puzzle.solution.cells {
            win()
        } else {
            mistakes = (0..<81).filter { values[$0] != puzzle.solution[$0] }.count
            fail()
        }
        changed()
    }

    private func win() {
        isComplete = true
        selected = nil
        clearHint()
        lastEvent = .completed
    }

    /// Grille ratée qu'on veut finir quand même : elle reste ratée, la suite est un entraînement sans limite d'erreurs,
    /// erreurs montrées (même si la partie était en mode validation).
    func continueAfterFailure() {
        guard isFailed else { return }
        isFailed = false
        practice = true
        strict = false
        lastEvent = nil
        changed()
    }

    private func fail() {
        isFailed = true
        selected = nil
        clearHint()
        lastEvent = .failed
    }

    func erase() {
        guard let i = selected, !isGiven(i), !isOver, values[i] != 0 || notes[i] != 0 else { return }
        if values[i] != 0 { log(i, 0, .player) }
        values[i] = 0
        setNotes(i, 0)
        changed()
    }

    func tick() {
        guard !isOver else { return }
        elapsed += 1
    }

    // MARK: - Indices

    /// 1er appui : consomme un indice et montre la zone. Appuis suivants : montre la case, puis joue le coup.
    func advanceHint() {
        guard !isOver else { return }
        if let hint = activeHint {
            hintStage += 1
            if hintStage >= 3 { applyHint(hint) }
            return
        }
        guard hintsRemaining > 0, let hint = HintEngine.hint(values: values, solution: puzzle.solution) else { return }
        hintsUsed += 1
        activeHint = hint
        hintStage = 1
        changed()
    }

    private func applyHint(_ hint: Hint) {
        clearHint()
        selected = hint.cell
        switch hint.kind {
        case .mistake:
            log(hint.cell, 0, .hint)
            values[hint.cell] = 0
            setNotes(hint.cell, 0)
            changed()
        case .placement, .revelation:
            applyingHint = true
            place(hint.cell, hint.digit)
            applyingHint = false
        }
    }

    func clearHint() {
        activeHint = nil
        hintStage = 0
    }

    #if DEBUG
    /// Tests d'interface : remplit la grille avec la solution sauf `keepEmpty` cases.
    func debugPrefill(keepEmpty: Int) {
        let empties = (0..<81).filter { values[$0] == 0 }
        for i in empties.dropFirst(keepEmpty) {
            values[i] = puzzle.solution[i]
            log(i, values[i], .player)
        }
    }

    /// Tests d'interface : remplit toute la grille, avec un chiffre faux dans la dernière case vide.
    func debugFillWithError() {
        let empties = (0..<81).filter { values[$0] == 0 }
        for i in empties {
            values[i] = i == empties.last ? puzzle.solution[i] % 9 + 1 : puzzle.solution[i]
            log(i, values[i], .player)
        }
    }

    func debugSetElapsed(_ seconds: Int) { elapsed = seconds }

    /// Captures et tests : chaque case vide reçoit en notes tous ses candidats possibles.
    func debugFillNotes() {
        for i in 0..<81 where values[i] == 0 {
            var used: UInt16 = 0
            for p in Sudoku.peers[i] where values[p] != 0 { used |= Sudoku.bit(values[p]) }
            setNotes(i, ~used & Sudoku.allDigits)
        }
    }
    #endif

    // MARK: - Privé

    private func changed() { onChange?() }
}
