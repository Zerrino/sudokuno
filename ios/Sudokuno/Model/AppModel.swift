import Foundation
import Observation
import SudokuKit

struct LevelStats: Codable, Hashable {
    var started = 0
    var won = 0
    var totalSeconds = 0
    var bestSeconds: Int?
    var perfect = 0
    /// Meilleur temps d'une grille parfaite (voir `AppModel.complete`) : le seul envoyé aux classements.
    var bestRankedSeconds: Int?

    var averageSeconds: Int? { won > 0 ? totalSeconds / won : nil }
    var winRate: Double? { started > 0 ? Double(won) / Double(started) : nil }
}

/// Une grille de « Mes grilles » (créée avec l'éditeur ou reçue par lien / code).
struct GridRecord: Codable, Hashable, Identifiable {
    var code: String
    var date: Date
    var id: String { code }
    var puzzleCode: PuzzleCode? { PuzzleCode(string: code) }
}

struct DailyResult: Codable, Hashable {
    var seconds: Int
    var hints: Int
    var mistakes: Int
    /// Réussie pendant sa journée (compte pour la série et Game Center).
    var onTime: Bool
    /// Grille parfaite, donc envoyée au classement du jour. Absent des sauvegardes d'avant cette règle.
    var ranked: Bool?
    /// Score de la partie classée (classement du jour au score), une fois calculé.
    var score: Int?
}

/// Une grille terminée, pour l'historique.
struct HistoryEntry: Codable, Hashable, Identifiable {
    var id = UUID()
    var code: PuzzleCode
    var mode: GameMode
    var level: Level
    var seconds: Int
    var hints: Int
    var mistakes: Int
    var hintsEnabled: Bool
    var completedAt: Date
    /// Partie abandonnée : son état complet, pour pouvoir la reprendre. nil = partie réussie.
    var abandoned: SavedGame?
    /// Journal de la partie terminée, pour la revoir coup par coup. Absent des parties d'avant le replay.
    var playback: Playback?
    /// Grille ratée (trop d'erreurs, ou validation d'une grille fausse). Absent = non.
    var failed: Bool?
    /// Score de la partie réussie, calculé juste après la victoire.
    var score: GameScore?
    /// Classements où envoyer le score dès qu'il est calculé (grille parfaite du premier coup). Absent = aucun.
    var boards: [String]?
    /// Partie d'entraînement (grille déjà jouée, ou ratée puis continuée) : elle ne compte nulle part. Absent = non.
    var practice: Bool?

    var isAbandoned: Bool { abandoned != nil }
    var isFailed: Bool { failed == true }
    /// Grille réellement réussie : ni abandonnée, ni ratée.
    var isWin: Bool { !isAbandoned && !isFailed && !isPractice }
    var isPractice: Bool { practice == true }

    /// La partie à revoir : celle d'une grille terminée, ou le début d'une partie abandonnée.
    var review: Playback? {
        if let saved = abandoned { return saved.moves.map { Playback(givens: saved.givens, solution: saved.solution, moves: $0) } }
        return playback
    }
}

/// Tout ce qui est sauvegardé sur l'appareil (fichier JSON local, rien n'est envoyé).
struct PersistedState: Codable {
    var streak = StreakState()
    var progress = LevelProgress()
    var stats: [Level: LevelStats] = [:]
    var saved: [String: SavedGame] = [:]
    var currentLevelGame: String?
    var dailyResults: [Int: DailyResult] = [:]
    var achievements: Set<String> = []
    var challengesWon = 0
    var history: [HistoryEntry] = []
    /// Codes des grilles créées avec l'éditeur (jouées, partagées ou copiées).
    var created: Set<String> = []
    /// « Mes grilles », la plus récente d'abord.
    var createdGrids: [GridRecord] = []
    var receivedGrids: [GridRecord] = []
    /// Meilleur score envoyé à chaque classement (hors classement du jour), pour le renvoyer à la connexion.
    var bestScores: [String: Int] = [:]
    /// Meilleur score de chaque grille réussie : leur somme est le total (`LeaderboardID.total`).
    var scoredCodes: [String: Int] = [:]
    var scoreTotal: Int { scoredCodes.values.reduce(0, +) }

    init() {}

    // Décodage tolérant : un champ ajouté dans une mise à jour ne doit pas effacer la progression.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        streak = try c.decodeIfPresent(StreakState.self, forKey: .streak) ?? StreakState()
        progress = try c.decodeIfPresent(LevelProgress.self, forKey: .progress) ?? LevelProgress()
        stats = try c.decodeIfPresent([Level: LevelStats].self, forKey: .stats) ?? [:]
        saved = try c.decodeIfPresent([String: SavedGame].self, forKey: .saved) ?? [:]
        currentLevelGame = try c.decodeIfPresent(String.self, forKey: .currentLevelGame)
        dailyResults = try c.decodeIfPresent([Int: DailyResult].self, forKey: .dailyResults) ?? [:]
        achievements = try c.decodeIfPresent(Set<String>.self, forKey: .achievements) ?? []
        challengesWon = try c.decodeIfPresent(Int.self, forKey: .challengesWon) ?? 0
        history = try c.decodeIfPresent([HistoryEntry].self, forKey: .history) ?? []
        created = try c.decodeIfPresent(Set<String>.self, forKey: .created) ?? []
        createdGrids = try c.decodeIfPresent([GridRecord].self, forKey: .createdGrids) ?? []
        receivedGrids = try c.decodeIfPresent([GridRecord].self, forKey: .receivedGrids) ?? []
        bestScores = try c.decodeIfPresent([String: Int].self, forKey: .bestScores) ?? [:]
        scoredCodes = try c.decodeIfPresent([String: Int].self, forKey: .scoredCodes) ?? [:]
    }
}

/// Résumé affiché à la fin d'une partie.
struct CompletionSummary: Hashable {
    var seconds: Int
    var mistakes: Int
    var hints: Int
    var hintsEnabled: Bool
    var level: Level
    var code: PuzzleCode
    var mode: GameMode
    var isNewRecord = false
    var previousBest: Int?
    var streak: Int?
    var milestone: Int?
    var unlocked: Level?
    var countsForDaily = false
    /// Entraînement : la partie ne compte pas.
    var practice = false
    /// Ligne de l'historique de cette partie : son score y arrive dès qu'il est calculé.
    var entryID: UUID?

    var isPerfect: Bool { hints == 0 && mistakes == 0 }
}

@Observable
final class AppModel {
    private(set) var state = PersistedState()
    var gameCenter = GameCenterService()
    let tipJar = TipJar()

    /// Grilles générées à l'avance (une par niveau) pour un lancement instantané.
    private var prepared: [Level: Puzzle] = [:]
    private var preparing: Set<Level> = []

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("sudokuno-state.json")
    }()

    init() {
        load()
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "debugReset") { state = PersistedState() }
        if UserDefaults.standard.bool(forKey: "debugDemo") { state = Self.demoState() }
        if UserDefaults.standard.bool(forKey: "debugUnlockAll") {
            for level in Level.generated { for _ in 0..<10 { state.progress.recordWin(level) } }
        }
        #endif
        refreshStreak()
        gameCenter.onAuthenticated = { [weak self] in self?.syncGameCenter() }
        rescoreHistory()
    }

    #if DEBUG
    /// État de démonstration pour les captures App Store : 12 jours de série, niveaux débloqués, records.
    static func demoState() -> PersistedState {
        var s = PersistedState()
        let today = DayStamp.today
        for k in stride(from: 12, through: 1, by: -1) {
            let day = today.adding(days: -k)
            s.streak.recordCompletion(day: day)
            s.dailyResults[day.dayNumber] = DailyResult(seconds: 240 + k * 17, hints: k % 3 == 0 ? 1 : 0, mistakes: 0, onTime: true)
        }
        for _ in 0..<7 { s.progress.recordWin(.facile) }
        for _ in 0..<10 { s.progress.recordWin(.moyen) }
        for _ in 0..<4 { s.progress.recordWin(.difficile) }
        s.stats[.facile] = LevelStats(started: 8, won: 7, totalSeconds: 7 * 251, bestSeconds: 168, perfect: 5)
        s.stats[.moyen] = LevelStats(started: 11, won: 10, totalSeconds: 10 * 402, bestSeconds: 297, perfect: 6)
        s.stats[.difficile] = LevelStats(started: 5, won: 4, totalSeconds: 4 * 655, bestSeconds: 541, perfect: 1)
        return s
    }
    #endif

    // MARK: - Persistance

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(PersistedState.self, from: data) else { return }
        state = decoded
    }

    func persist() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func resetStatistics() {
        state = PersistedState()
        persist()
    }

    // MARK: - Série

    var today: DayStamp { .today }

    func refreshStreak() {
        if state.streak.refresh(today: today) != nil { persist() }
    }

    // MARK: - Génération

    static func generate(_ code: PuzzleCode) async -> Puzzle {
        await Task.detached(priority: .userInitiated) { PuzzleFactory.make(code) }.value
    }

    func prepare(_ level: Level) {
        guard level != .legende, prepared[level] == nil, !preparing.contains(level) else { return }
        preparing.insert(level)
        Task {
            let puzzle = await Self.generate(.level(level, seed: PuzzleFactory.randomSeed()))
            prepared[level] = puzzle
            preparing.remove(level)
        }
    }

    func prepareUnlockedLevels() {
        for level in Level.generated where state.progress.isUnlocked(level) { prepare(level) }
    }

    /// Une grille créée avec l'éditeur est jouée, partagée ou copiée : elle compte pour les succès « créateur ».
    func recordCreated(_ code: PuzzleCode) {
        Self.remember(code, in: &state.createdGrids)
        let isNew = state.created.insert(code.string).inserted
        persist()
        if isNew { syncProgressAchievements() }
    }

    /// Ajoute (ou remonte) une grille en tête d'une liste de « Mes grilles ».
    private static func remember(_ code: PuzzleCode, in list: inout [GridRecord]) {
        list.removeAll { $0.code == code.string }
        list.insert(GridRecord(code: code.string, date: .now), at: 0)
        if list.count > 200 { list.removeLast(list.count - 200) }
    }

    func forget(_ record: GridRecord, received: Bool) {
        if received { state.receivedGrids.removeAll { $0 == record } } else { state.createdGrids.removeAll { $0 == record } }
        persist()
    }

    /// Meilleur temps sur une grille (nil = jamais résolue).
    func bestTime(_ code: String) -> Int? {
        state.history.filter { $0.code.string == code && $0.isWin }.map(\.seconds).min()
    }

    func isInProgress(_ code: String) -> Bool { state.saved[code] != nil }

    /// Ouvre une grille de « Mes grilles » : reprend la partie en cours, sinon la lance.
    func openGrid(_ code: PuzzleCode) async -> GameSession {
        if let saved = state.saved[code.string] { return resume(saved) }
        return await sharedGame(code: code, challenge: nil, record: false)
    }

    /// À chaque connexion : renvoie ce qui a pu être obtenu hors connexion (succès, records, série, grille du jour).
    /// Sans risque : Game Center ignore un succès déjà obtenu et garde le meilleur score.
    func syncGameCenter() {
        gameCenter.report(achievements: Array(state.achievements).sorted())
        // Seulement les scores des grilles parfaites (les classements au score sont partis de zéro).
        for (board, score) in state.bestScores { gameCenter.submit(score: score, hintsEnabled: true, leaderboards: [board]) }
        if let r = state.dailyResults[today.dayNumber], r.onTime, r.ranked == true, let score = r.score {
            gameCenter.submit(score: score, hintsEnabled: true, leaderboards: [LeaderboardID.daily])
        }
        gameCenter.submit(score: state.scoreTotal, hintsEnabled: true, leaderboards: [LeaderboardID.total])
        gameCenter.submitStreak(state.streak.longest)
        syncProgressAchievements()
    }

    /// Succès progressifs (grilles résolues, grilles créées), recalculés depuis l'état local.
    func syncProgressAchievements() {
        let solved = state.history.filter(\.isWin).count
        let made = state.created.count
        var items: [(id: String, percent: Double)] = [(AchievementID.solved100, Double(min(solved, 100)))]
        for n in AchievementID.createdSteps where made > 0 {
            items.append((AchievementID.created(n), Double(min(made, n)) * 100 / Double(n)))
        }
        gameCenter.report(progress: items)
    }

    /// Lance (ou reprend) une grille de la Légende. Elle compte comme une partie du niveau Légende.
    func newLegendGame(_ legend: LegendPuzzle) async -> GameSession {
        let code = PuzzleCode.custom(legend.givens)
        if let saved = state.saved[code.string] { return resume(saved) }
        let puzzle = await Self.generate(code)
        state.stats[.legende, default: LevelStats()].started += 1
        let session = makeSession(puzzle, mode: .level, saved: nil)
        save(session)
        return session
    }

    /// Meilleur temps sur une grille de la Légende (nil = jamais résolue).
    func legendBest(_ legend: LegendPuzzle) -> Int? {
        let code = PuzzleCode.custom(legend.givens)
        return state.history.filter { $0.code == code && $0.isWin }.map(\.seconds).min()
    }

    func legendInProgress(_ legend: LegendPuzzle) -> Bool {
        state.saved[PuzzleCode.custom(legend.givens).string] != nil
    }

    // MARK: - Démarrer une partie

    func newLevelGame(_ level: Level) async -> GameSession {
        let puzzle: Puzzle
        if let ready = prepared.removeValue(forKey: level) {
            puzzle = ready
        } else {
            puzzle = await Self.generate(.level(level, seed: PuzzleFactory.randomSeed()))
        }
        prepare(level)
        state.stats[level, default: LevelStats()].started += 1
        let session = makeSession(puzzle, mode: .level, saved: nil)
        state.currentLevelGame = puzzle.code.string
        save(session)
        return session
    }

    /// Parties en cours, la plus récente d'abord (plusieurs à la fois).
    var inProgress: [SavedGame] {
        state.saved.values.sorted { $0.updatedAt > $1.updatedAt }
    }

    /// Dernière partie en cours, hors grille du jour (qui a sa propre carte).
    var lastInProgress: SavedGame? {
        inProgress.first { $0.code != .daily(today) }
    }

    /// Abandon : la partie quitte « En cours » et rejoint l'historique, avec son état pour une reprise.
    func abandon(_ session: GameSession) {
        let snapshot = session.snapshot
        session.isAbandoned = true
        state.saved[session.puzzle.code.string] = nil
        if state.currentLevelGame == session.puzzle.code.string { state.currentLevelGame = nil }
        state.history.insert(HistoryEntry(code: session.puzzle.code, mode: session.mode, level: session.puzzle.level,
                                          seconds: session.elapsed, hints: session.hintsUsed, mistakes: session.mistakes,
                                          hintsEnabled: session.hintsEnabled, completedAt: .now, abandoned: snapshot), at: 0)
        persist()
    }

    /// Reprendre une partie abandonnée : elle redevient une partie en cours.
    func resumeAbandoned(_ entry: HistoryEntry) -> GameSession? {
        guard let saved = entry.abandoned else { return nil }
        state.history.removeAll { $0.id == entry.id }
        let session = resume(saved)
        save(session)
        return session
    }

    func deleteSaved(_ saved: SavedGame) {
        state.saved[saved.code.string] = nil
        persist()
    }

    /// Rejouer une grille de l'historique (ne compte pas pour les niveaux ni la série).
    func replay(_ entry: HistoryEntry) async -> GameSession {
        if case .daily(let day) = entry.code { return await dailyGame(for: day) }
        let puzzle = await Self.generate(entry.code)
        return makeSession(puzzle, mode: .shared(nil), saved: nil)
    }

    func resume(_ saved: SavedGame) -> GameSession {
        let puzzle = Puzzle(code: saved.code, level: saved.level, givens: saved.givens, solution: saved.solution)
        return makeSession(puzzle, mode: saved.mode, saved: saved)
    }

    func dailyGame(for day: DayStamp) async -> GameSession {
        let code = PuzzleCode.daily(day)
        if let saved = state.saved[code.string] { return resume(saved) }
        let puzzle = await Self.generate(code)
        return makeSession(puzzle, mode: .daily, saved: nil)
    }

    /// Un code reçu peut-il être ouvert ? (solution unique, et pas une grille du jour à venir)
    func canOpen(_ code: PuzzleCode) -> Bool {
        if case .daily(let day) = code, day > today { return false }
        return PuzzleAnalysis.isPlayable(code)
    }

    func sharedGame(code: PuzzleCode, challenge: Challenge?, record: Bool = true) async -> GameSession {
        // Grille reçue (lien, code) : elle rejoint « Mes grilles », sauf si c'est une de mes créations.
        if record, !state.created.contains(code.string) {
            Self.remember(code, in: &state.receivedGrids)
            persist()
        }
        if case .daily(let day) = code, day <= today {
            // Un code du jour partagé ouvre la grille du jour correspondante (qui compte pour la série si c'est aujourd'hui).
            return await dailyGame(for: day)
        }
        if let saved = state.saved[code.string], saved.mode.challenge == challenge { return resume(saved) }
        let puzzle = await Self.generate(code)
        // Une grille partagée compte dans les statistiques de son niveau, comme une partie normale.
        state.stats[puzzle.level, default: LevelStats()].started += 1
        return makeSession(puzzle, mode: .shared(challenge), saved: nil)
    }

    /// Recommencer une grille ratée : même grille, nouvelle partie. La grille du jour reste la grille du jour.
    func retry(_ session: GameSession) async -> GameSession {
        if case .daily(let day) = session.puzzle.code, session.mode == .daily { return await dailyGame(for: day) }
        return await sharedGame(code: session.puzzle.code, challenge: nil, record: false)
    }

    /// Grille ratée : elle quitte les parties en cours et rejoint l'historique, marquée comme telle.
    /// Elle ne compte ni comme victoire, ni pour la série, ni pour les classements.
    /// Continuer une grille ratée : elle reste ratée dans l'historique, la suite ne compte pas.
    func continueAfterFailure(_ session: GameSession) {
        session.continueAfterFailure()
        save(session)
    }

    func fail(_ session: GameSession) {
        let code = session.puzzle.code
        state.saved[code.string] = nil
        if state.currentLevelGame == code.string { state.currentLevelGame = nil }
        state.history.insert(HistoryEntry(code: code, mode: session.mode, level: session.puzzle.level, seconds: session.elapsed,
                                          hints: session.hintsUsed, mistakes: session.mistakes,
                                          hintsEnabled: session.hintsEnabled, completedAt: .now,
                                          playback: session.playback, failed: true,
                                          practice: session.practice ? true : nil), at: 0)
        if state.history.count > 300 { state.history.removeLast(state.history.count - 300) }
        persist()
    }

    /// Calcule le score en arrière-plan (juger chaque coup demande de rejouer la logique de la partie),
    /// puis l'inscrit dans l'historique : l'écran de fin l'affiche dès qu'il arrive.
    /// Fin d'un entraînement : seulement l'historique (avec son score, pour information). Ni statistiques, ni déblocage,
    /// ni série, ni succès, ni total, ni classements.
    private func completePractice(_ session: GameSession) -> CompletionSummary {
        var summary = CompletionSummary(seconds: session.elapsed, mistakes: session.mistakes, hints: session.hintsUsed,
                                        hintsEnabled: session.hintsEnabled, level: session.puzzle.level,
                                        code: session.puzzle.code, mode: session.mode)
        summary.practice = true
        let entry = HistoryEntry(code: session.puzzle.code, mode: session.mode, level: session.puzzle.level, seconds: session.elapsed,
                                 hints: session.hintsUsed, mistakes: session.mistakes, hintsEnabled: session.hintsEnabled,
                                 completedAt: .now, playback: session.playback, practice: true)
        summary.entryID = entry.id
        state.history.insert(entry, at: 0)
        if state.history.count > 300 { state.history.removeLast(state.history.count - 300) }
        scoreWin(entry)
        persist()
        return summary
    }

    private func computeScore(for entry: HistoryEntry, priority: TaskPriority = .userInitiated) async -> GameScore? {
        guard let playback = entry.playback else { return nil }
        let (level, mistakes) = (entry.level, entry.mistakes)
        let (givens, solution) = (playback.givens, playback.solution)
        let moves = playback.decoded.map(\.scored)
        return await Task.detached(priority: priority) {
            Scoring.score(givens: givens, solution: solution, level: level, moves: moves, mistakes: mistakes)
        }.value
    }

    /// Score d'une partie qui vient d'être gagnée : inscrit dans l'historique (l'écran de fin l'affiche dès qu'il arrive),
    /// ajouté au total et envoyé aux classements.
    private func scoreWin(_ entry: HistoryEntry) {
        Task { @MainActor in
            guard let score = await computeScore(for: entry),
                  let i = state.history.firstIndex(where: { $0.id == entry.id }) else { return }
            state.history[i].score = score
            guard !entry.isPractice else { persist(); return }
            let code = entry.code.string
            if score.total > state.scoredCodes[code] ?? 0 { state.scoredCodes[code] = score.total }
            var boards: [String] = []
            for board in entry.boards ?? [] {
                if board == LeaderboardID.daily {
                    if case .daily(let day) = entry.code { state.dailyResults[day.dayNumber]?.score = score.total }
                } else {
                    state.bestScores[board] = max(score.total, state.bestScores[board] ?? 0)
                }
                boards.append(board)
            }
            gameCenter.submit(score: score.total, hintsEnabled: entry.hintsEnabled, leaderboards: boards)
            gameCenter.submit(score: state.scoreTotal, hintsEnabled: true, leaderboards: [LeaderboardID.total])
            persist()
        }
    }

    /// Recalcule en arrière-plan les scores de l'historique faits avec une ancienne version du calcul
    /// (pour l'affichage seulement : les classements au score partent de zéro).
    private func rescoreHistory() {
        let stale = state.history.filter { !$0.isAbandoned && !$0.isFailed && $0.playback != nil && $0.score?.isCurrent != true }
        guard !stale.isEmpty else { return }
        Task { @MainActor in
            for entry in stale {
                guard let score = await computeScore(for: entry, priority: .utility),
                      let i = state.history.firstIndex(where: { $0.id == entry.id }) else { continue }
                state.history[i].score = score
            }
            persist()
        }
    }

    func score(of entryID: UUID?) -> GameScore? { state.history.first { $0.id == entryID }?.score }

    func savedDaily(_ day: DayStamp) -> SavedGame? { state.saved[PuzzleCode.daily(day).string] }
    func dailyResult(_ day: DayStamp) -> DailyResult? { state.dailyResults[day.dayNumber] }

    private func makeSession(_ puzzle: Puzzle, mode: GameMode, saved: SavedGame?) -> GameSession {
        // Mode validation : toujours à partir de Diabolique, ou partout avec le réglage « Mode difficile ».
        let strict = puzzle.level.mistakeLimit == nil || SettingKey.bool(SettingKey.hardMode)
        // Une grille déjà jouée (réussie, ratée ou abandonnée) ne compte plus : entraînement.
        let practice = state.history.contains { $0.code == puzzle.code }
        let session = GameSession(puzzle: puzzle, mode: mode, hintsEnabled: SettingKey.bool(SettingKey.hintsEnabled),
                                  strict: strict, practice: practice, saved: saved)
        #if DEBUG
        let keep = UserDefaults.standard.integer(forKey: "debugPrefillAllBut")
        if saved == nil, keep > 0 { session.debugPrefill(keepEmpty: keep) }
        if saved == nil, UserDefaults.standard.bool(forKey: "debugFillWithError") { session.debugFillWithError() }
        let start = UserDefaults.standard.integer(forKey: "debugElapsed")
        if saved == nil, start > 0 { session.debugSetElapsed(start) }
        if saved == nil, UserDefaults.standard.bool(forKey: "debugFillNotes") { session.debugFillNotes() }
        #endif
        session.onChange = { [weak self, weak session] in
            guard let self, let session, !session.isComplete, !session.isAbandoned else { return }
            self.save(session)
        }
        return session
    }

    func save(_ session: GameSession) {
        guard !session.isOver, !session.isAbandoned else { return }
        state.saved[session.puzzle.code.string] = session.snapshot
        persist()
    }

    // MARK: - Fin de partie

    func complete(_ session: GameSession) -> CompletionSummary {
        let code = session.puzzle.code
        let level = session.puzzle.level
        state.saved[code.string] = nil
        if state.currentLevelGame == code.string { state.currentLevelGame = nil }
        if session.practice { return completePractice(session) }

        var summary = CompletionSummary(seconds: session.elapsed, mistakes: session.mistakes, hints: session.hintsUsed,
                                        hintsEnabled: session.hintsEnabled, level: level, code: code, mode: session.mode)
        var newAchievements: [String] = []
        // Classements : seules les grilles parfaites comptent. Sans indice, sans erreur, et du premier coup
        // (la grille n'a jamais été terminée ni abandonnée puis recommencée).
        // Un temps impossible (grille remplie en quelques secondes) n'est jamais classé.
        let ranked = summary.isPerfect && !state.history.contains { $0.code == code }
            && session.elapsed >= level.minimumPlausibleSeconds
        /// Classements où ira le score, une fois calculé (`scoreWin`).
        var boards: [String] = []

        switch session.mode {
        case .level:
            var s = state.stats[level, default: LevelStats()]
            summary.previousBest = s.bestSeconds
            s.won += 1
            s.totalSeconds += session.elapsed
            if summary.isPerfect { s.perfect += 1 }
            if s.bestSeconds.map({ session.elapsed < $0 }) ?? true {
                summary.isNewRecord = s.bestSeconds != nil
                s.bestSeconds = session.elapsed
            }
            if ranked { s.bestRankedSeconds = min(session.elapsed, s.bestRankedSeconds ?? .max) }
            state.stats[level] = s
            if let unlocked = state.progress.recordWin(level) {
                summary.unlocked = unlocked
                newAchievements.append(AchievementID.unlocked(unlocked))
            }
            // Au score, la Légende a aussi son classement : le score tient compte de la difficulté de chaque chiffre.
            if ranked { boards += [LeaderboardID.level(level), LeaderboardID.best] }

        case .daily:
            if case .daily(let day) = code {
                let onTime = day == today
                // Un résultat classé reste : rejouer la grille du jour ne le remplace pas.
                let previous = state.dailyResults[day.dayNumber]
                if previous == nil || (onTime && previous?.ranked != true) {
                    state.dailyResults[day.dayNumber] = DailyResult(seconds: session.elapsed, hints: session.hintsUsed,
                                                                    mistakes: session.mistakes, onTime: onTime, ranked: ranked && onTime)
                }
                if onTime {
                    summary.countsForDaily = true
                    summary.milestone = state.streak.recordCompletion(day: day)
                    summary.streak = state.streak.current
                    if ranked { boards += [LeaderboardID.daily, LeaderboardID.best] }
                    gameCenter.submitStreak(state.streak.longest)
                    for m in AchievementID.streaks where state.streak.current >= m {
                        newAchievements.append(AchievementID.streak(m))
                    }
                }
            }

        case .shared(let challenge):
            // Une grille partagée réussie compte dans les statistiques de son niveau (pas dans les records ni le déblocage).
            var s = state.stats[level, default: LevelStats()]
            s.won += 1
            s.totalSeconds += session.elapsed
            if summary.isPerfect { s.perfect += 1 }
            state.stats[level] = s
            if let challenge, session.elapsed < challenge.seconds {
                state.challengesWon += 1
                newAchievements.append(AchievementID.firstChallengeWon)
            }
        }

        let entry = HistoryEntry(code: code, mode: session.mode, level: level, seconds: session.elapsed,
                                 hints: session.hintsUsed, mistakes: session.mistakes,
                                 hintsEnabled: session.hintsEnabled, completedAt: .now, playback: session.playback,
                                 boards: boards.isEmpty ? nil : boards)
        summary.entryID = entry.id
        state.history.insert(entry, at: 0)
        scoreWin(entry)
        if state.history.count > 300 { state.history.removeLast(state.history.count - 300) }

        if summary.isPerfect { newAchievements.append(AchievementID.perfect) }
        if level == .diabolique { newAchievements.append(AchievementID.firstDiabolique) }
        if level == .legende { newAchievements.append(AchievementID.firstLegend) }
        let fresh = newAchievements.filter { !state.achievements.contains($0) }
        state.achievements.formUnion(fresh)
        gameCenter.report(achievements: fresh)
        syncProgressAchievements()

        persist()
        prepare(level)
        return summary
    }
}
