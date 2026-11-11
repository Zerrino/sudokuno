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
}

extension SavedGame {
    var title: String { GameMode.title(mode, code: code, level: level) }
}

extension GameMode {
    static func title(_ mode: GameMode, code: PuzzleCode, level: Level) -> String {
        switch mode {
        case .level: return level.name
        case .daily: return L("Du jour · %@", level.name)
        case .shared(let c):
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
    /// Fixé au début de la partie : changer le réglage n'affecte que les parties suivantes.
    let hintsEnabled: Bool

    private(set) var values: [UInt8]
    private(set) var notes: [UInt16]
    var selected: Int?
    var notesMode = false
    private(set) var mistakes: Int
    private(set) var hintsUsed: Int
    private(set) var elapsed: Int
    private(set) var isComplete = false

    private(set) var activeHint: Hint?
    /// 1 = zone et technique, 2 = case, (3 = appliqué → l'indice disparaît)
    private(set) var hintStage = 0

    /// Dernier évènement, pour l'animation et l'haptique.
    private(set) var lastEvent: Event?
    private var undoStack: [(values: [UInt8], notes: [UInt16])] = []

    static let maxHints = 3

    enum Event: Equatable {
        case placed(cell: Int, correct: Bool, completedUnits: Int, nonce: Int)
        case completed
    }
    private var eventNonce = 0

    /// Appelé après chaque modification (sauvegarde).
    var onChange: (() -> Void)?

    init(puzzle: Puzzle, mode: GameMode, hintsEnabled: Bool, saved: SavedGame? = nil) {
        self.puzzle = puzzle
        self.mode = mode
        self.hintsEnabled = saved?.hintsEnabled ?? hintsEnabled
        values = saved?.values ?? puzzle.givens.cells
        notes = saved?.notes ?? [UInt16](repeating: 0, count: 81)
        mistakes = saved?.mistakes ?? 0
        hintsUsed = saved?.hintsUsed ?? 0
        elapsed = saved?.elapsed ?? 0
        isComplete = values == puzzle.solution.cells
    }

    var snapshot: SavedGame {
        SavedGame(code: puzzle.code, mode: mode, level: puzzle.level, givens: puzzle.givens, solution: puzzle.solution,
                  values: values, notes: notes, elapsed: elapsed, mistakes: mistakes, hintsUsed: hintsUsed,
                  hintsEnabled: hintsEnabled, updatedAt: .now)
    }

    // MARK: - Lecture

    func isGiven(_ i: Int) -> Bool { puzzle.givens[i] != 0 }
    func isWrong(_ i: Int) -> Bool { values[i] != 0 && values[i] != puzzle.solution[i] }

    func hasConflict(_ i: Int) -> Bool {
        let v = values[i]
        return v != 0 && Sudoku.peers[i].contains { values[$0] == v }
    }

    /// Nombre d'exemplaires d'un chiffre placés (justes) : à 9, la touche est grisée.
    func placedCount(_ d: UInt8) -> Int {
        (0..<81).reduce(0) { $0 + (values[$1] == d && puzzle.solution[$1] == d ? 1 : 0) }
    }

    var hintsRemaining: Int { hintsEnabled ? max(0, Self.maxHints - hintsUsed) : 0 }
    var canUndo: Bool { !undoStack.isEmpty && !isComplete }
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
        guard let i = selected, !isGiven(i), !isComplete else { return }
        if notesMode && values[i] == 0 {
            pushUndo()
            notes[i] ^= Sudoku.bit(d)
            changed()
        } else {
            place(i, d)
        }
    }

    private func place(_ i: Int, _ d: UInt8) {
        guard values[i] != d else { return }
        pushUndo()
        values[i] = d
        notes[i] = 0
        let correct = d == puzzle.solution[i]
        if correct && SettingKey.bool(SettingKey.autoRemoveNotes) {
            for p in Sudoku.peers[i] { notes[p] &= ~Sudoku.bit(d) }
        }
        if !correct { mistakes += 1 }
        if activeHint?.cell == i { clearHint() }

        let completedUnits = correct
            ? Sudoku.unitsOfCell[i].filter { u in Sudoku.units[u].allSatisfy { values[$0] == puzzle.solution[$0] } }.count
            : 0
        eventNonce += 1
        lastEvent = .placed(cell: i, correct: correct, completedUnits: completedUnits, nonce: eventNonce)

        if values == puzzle.solution.cells {
            isComplete = true
            selected = nil
            clearHint()
            lastEvent = .completed
        }
        changed()
    }

    func erase() {
        guard let i = selected, !isGiven(i), !isComplete, values[i] != 0 || notes[i] != 0 else { return }
        pushUndo()
        values[i] = 0
        notes[i] = 0
        changed()
    }

    func undo() {
        guard let last = undoStack.popLast(), !isComplete else { return }
        values = last.values
        notes = last.notes
        changed()
    }

    func tick() {
        guard !isComplete else { return }
        elapsed += 1
    }

    // MARK: - Indices

    /// 1er appui : consomme un indice et montre la zone. Appuis suivants : montre la case, puis joue le coup.
    func advanceHint() {
        guard !isComplete else { return }
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
            pushUndo()
            values[hint.cell] = 0
            notes[hint.cell] = 0
            changed()
        case .placement, .revelation:
            place(hint.cell, hint.digit)
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
        for i in empties.dropFirst(keepEmpty) { values[i] = puzzle.solution[i] }
    }

    func debugSetElapsed(_ seconds: Int) { elapsed = seconds }
    #endif

    // MARK: - Privé

    private func pushUndo() {
        undoStack.append((values, notes))
        if undoStack.count > 500 { undoStack.removeFirst() }
    }

    private func changed() { onChange?() }
}
