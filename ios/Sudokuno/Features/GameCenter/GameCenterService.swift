@preconcurrency import GameKit
import Observation
import SudokuKit
import UIKit

/// Identifiants à créer à l'identique dans App Store Connect (voir docs/GAME_CENTER.md).
enum LeaderboardID {
    static let daily = "sudokuno.daily"
    static let dailyNoHint = "sudokuno.daily.nohint"
    static let streak = "sudokuno.streak"
    static func best(_ level: Level) -> String { "sudokuno.best.\(level.servicesLetter)" }
}

enum AchievementID {
    static let perfect = "sudokuno.perfect"
    static let firstDiabolique = "sudokuno.diabolique.first"
    static let firstChallengeWon = "sudokuno.challenge.won"
    static func unlocked(_ level: Level) -> String { "sudokuno.unlock.\(level.servicesLetter)" }
    static func streak(_ days: Int) -> String { "sudokuno.streak.\(days)" }
}

/// Le champ `context` d'un score (64 bits) transporte les indices et les erreurs,
/// pour les afficher dans le classement de l'app.
struct ScoreContext: Hashable {
    var hints: Int
    var hintsEnabled: Bool
    var mistakes: Int

    var rawValue: Int {
        (hints & 0xFF) | ((hintsEnabled ? 0 : 1) << 8) | ((min(mistakes, 0xFFFF) & 0xFFFF) << 16)
    }

    init(hints: Int, hintsEnabled: Bool, mistakes: Int) {
        self.hints = hints
        self.hintsEnabled = hintsEnabled
        self.mistakes = mistakes
    }

    init(rawValue: Int) {
        hints = rawValue & 0xFF
        hintsEnabled = (rawValue >> 8) & 1 == 0
        mistakes = (rawValue >> 16) & 0xFFFF
    }
}

struct LeaderboardRow: Identifiable, Hashable {
    let id: String
    let rank: Int
    let name: String
    let seconds: Int
    let context: ScoreContext
    let isLocalPlayer: Bool
}

@Observable
final class GameCenterService {
    private(set) var isAuthenticated = false
    private(set) var playerName: String?
    private(set) var lastError: String?

    func authenticate() {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "debugNoGameCenter") { return }
        #endif
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                guard let self else { return }
                if let viewController {
                    Self.topViewController()?.present(viewController, animated: true)
                    return
                }
                self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                self.playerName = self.isAuthenticated ? GKLocalPlayer.local.displayName : nil
                self.lastError = error?.localizedDescription
                GKAccessPoint.shared.isActive = false
            }
        }
    }

    func submit(seconds: Int, level: Level, hints: Int, hintsEnabled: Bool, mistakes: Int, leaderboards: [String]) {
        guard isAuthenticated, seconds >= level.minimumPlausibleSeconds else { return }
        let context = ScoreContext(hints: hints, hintsEnabled: hintsEnabled, mistakes: mistakes).rawValue
        Task {
            try? await GKLeaderboard.submitScore(seconds, context: context, player: GKLocalPlayer.local,
                                                 leaderboardIDs: leaderboards)
        }
    }

    func submitStreak(_ days: Int) {
        guard isAuthenticated, days > 0 else { return }
        Task {
            try? await GKLeaderboard.submitScore(days, context: 0, player: GKLocalPlayer.local,
                                                 leaderboardIDs: [LeaderboardID.streak])
        }
    }

    func report(achievements ids: [String]) {
        guard isAuthenticated, !ids.isEmpty else { return }
        let achievements = ids.map { id in
            let a = GKAchievement(identifier: id)
            a.percentComplete = 100
            a.showsCompletionBanner = true
            return a
        }
        Task { try? await GKAchievement.report(achievements) }
    }

    /// Les 50 premiers d'un classement (pour le classement du jour, la période en cours).
    func loadTop(_ leaderboardID: String) async throws -> [LeaderboardRow] {
        guard isAuthenticated else { return [] }
        let boards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])
        guard let board = boards.first else { return [] }
        let (_, entries, _) = try await board.loadEntries(for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 50))
        let localID = GKLocalPlayer.local.gamePlayerID
        return entries.map { e in
            LeaderboardRow(id: e.player.gamePlayerID, rank: e.rank, name: e.player.displayName, seconds: e.score,
                           context: ScoreContext(rawValue: e.context), isLocalPlayer: e.player.gamePlayerID == localID)
        }
    }

    func showDashboard() {
        GKAccessPoint.shared.trigger(state: .dashboard) {}
    }

    func showAchievements() {
        GKAccessPoint.shared.trigger(state: .achievements) {}
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        var vc = scene?.keyWindow?.rootViewController
        while let presented = vc?.presentedViewController { vc = presented }
        return vc
    }
}
