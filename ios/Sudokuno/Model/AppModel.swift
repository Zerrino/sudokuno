import Foundation
import Observation
import SudokuKit

struct LevelStats: Codable, Hashable {
    var started = 0
    var won = 0
    var totalSeconds = 0
    var bestSeconds: Int?
    var perfect = 0

    var averageSeconds: Int? { won > 0 ? totalSeconds / won : nil }
    var winRate: Double? { started > 0 ? Double(won) / Double(started) : nil }
}

struct DailyResult: Codable, Hashable {
    var seconds: Int
    var hints: Int
    var mistakes: Int
    /// Réussie pendant sa journée (compte pour la série et Game Center).
    var onTime: Bool
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

    var isAbandoned: Bool { abandoned != nil }
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
        gameCenter.onAuthenticated = { [weak self] in self?.syncProgressAchievements() }
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
        guard state.created.insert(code.string).inserted else { return }
        persist()
        syncProgressAchievements()
    }

    /// Succès progressifs (grilles résolues, grilles créées), recalculés depuis l'état local.
    func syncProgressAchievements() {
        let solved = state.history.filter { !$0.isAbandoned }.count
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
        return state.history.filter { $0.code == code && !$0.isAbandoned }.map(\.seconds).min()
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

    func sharedGame(code: PuzzleCode, challenge: Challenge?) async -> GameSession {
        if case .daily(let day) = code, day <= today {
            // Un code du jour partagé ouvre la grille du jour correspondante (qui compte pour la série si c'est aujourd'hui).
            return await dailyGame(for: day)
        }
        if let saved = state.saved[code.string], saved.mode.challenge == challenge { return resume(saved) }
        let puzzle = await Self.generate(code)
        return makeSession(puzzle, mode: .shared(challenge), saved: nil)
    }

    func savedDaily(_ day: DayStamp) -> SavedGame? { state.saved[PuzzleCode.daily(day).string] }
    func dailyResult(_ day: DayStamp) -> DailyResult? { state.dailyResults[day.dayNumber] }

    private func makeSession(_ puzzle: Puzzle, mode: GameMode, saved: SavedGame?) -> GameSession {
        let session = GameSession(puzzle: puzzle, mode: mode, hintsEnabled: SettingKey.bool(SettingKey.hintsEnabled), saved: saved)
        #if DEBUG
        let keep = UserDefaults.standard.integer(forKey: "debugPrefillAllBut")
        if saved == nil, keep > 0 { session.debugPrefill(keepEmpty: keep) }
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
        guard !session.isComplete, !session.isAbandoned else { return }
        state.saved[session.puzzle.code.string] = session.snapshot
        persist()
    }

    // MARK: - Fin de partie

    func complete(_ session: GameSession) -> CompletionSummary {
        let code = session.puzzle.code
        let level = session.puzzle.level
        state.saved[code.string] = nil
        if state.currentLevelGame == code.string { state.currentLevelGame = nil }

        var summary = CompletionSummary(seconds: session.elapsed, mistakes: session.mistakes, hints: session.hintsUsed,
                                        hintsEnabled: session.hintsEnabled, level: level, code: code, mode: session.mode)
        var newAchievements: [String] = []

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
            state.stats[level] = s
            if let unlocked = state.progress.recordWin(level) {
                summary.unlocked = unlocked
                newAchievements.append(AchievementID.unlocked(unlocked))
            }
            if level != .legende { // pas de classement : chaque Légende est une grille différente
                gameCenter.submit(seconds: session.elapsed, level: level, hints: session.hintsUsed,
                                  hintsEnabled: session.hintsEnabled, mistakes: session.mistakes,
                                  leaderboards: [LeaderboardID.best(level)])
            }

        case .daily:
            if case .daily(let day) = code {
                let onTime = day == today
                if state.dailyResults[day.dayNumber] == nil || onTime {
                    state.dailyResults[day.dayNumber] = DailyResult(seconds: session.elapsed, hints: session.hintsUsed,
                                                                    mistakes: session.mistakes, onTime: onTime)
                }
                if onTime {
                    summary.countsForDaily = true
                    summary.milestone = state.streak.recordCompletion(day: day)
                    summary.streak = state.streak.current
                    var boards = [LeaderboardID.daily]
                    if session.hintsUsed == 0 { boards.append(LeaderboardID.dailyNoHint) }
                    gameCenter.submit(seconds: session.elapsed, level: level, hints: session.hintsUsed,
                                      hintsEnabled: session.hintsEnabled, mistakes: session.mistakes, leaderboards: boards)
                    gameCenter.submitStreak(state.streak.longest)
                    for m in AchievementID.streaks where state.streak.current >= m {
                        newAchievements.append(AchievementID.streak(m))
                    }
                }
            }

        case .shared(let challenge):
            if let challenge, session.elapsed < challenge.seconds {
                state.challengesWon += 1
                newAchievements.append(AchievementID.firstChallengeWon)
            }
        }

        state.history.insert(HistoryEntry(code: code, mode: session.mode, level: level, seconds: session.elapsed,
                                          hints: session.hintsUsed, mistakes: session.mistakes,
                                          hintsEnabled: session.hintsEnabled, completedAt: .now), at: 0)
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
