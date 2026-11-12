import SwiftUI
import SudokuKit

@main
struct SudokunoApp: App {
    @State private var model: AppModel
    @State private var router = Router()
    @AppStorage(SettingKey.theme) private var theme = AppTheme.system.rawValue
    @AppStorage(AppLanguage.storageKey) private var language = AppLanguage.system.rawValue

    init() {
        SettingKey.registerDefaults()
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "debugReset") {
            UserDefaults.standard.removeObject(forKey: AppLanguage.storageKey)
            UserDefaults.standard.removeObject(forKey: "creatorDraft")
        }
        #endif
        L10n.applyStored()
        _model = State(initialValue: AppModel())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(router)
                .environment(\.locale, L10n.locale)
                .id(language) // reconstruit l'interface dans la nouvelle langue
                .preferredColorScheme(AppTheme(rawValue: theme)?.colorScheme)
                .tint(Palette.accent)
        }
    }
}

enum Route: Hashable {
    case streak, stats, settings, leaderboard, enterCode, creator, history, legends, myGrids
    /// Résolution expliquée pas à pas d'une grille (ses chiffres de départ).
    case explain(SudokuKit.Grid)
}

/// Navigation et lancement des parties.
@Observable
final class Router {
    var path: [Route] = []
    var activeGame: GameSession?
    var loadingMessage: String?

    func play(_ message: String? = nil, _ make: @escaping () async -> GameSession) {
        guard loadingMessage == nil else { return }
        loadingMessage = message ?? L("Préparation de la grille…")
        Task {
            let session = await make()
            loadingMessage = nil
            activeGame = session
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .streak: StreakView()
                    case .stats: StatsView()
                    case .settings: SettingsView()
                    case .leaderboard: LeaderboardView()
                    case .enterCode: EnterCodeView()
                    case .creator: CreatorView()
                    case .history: HistoryView()
                    case .legends: LegendsView()
                    case .myGrids: MyGridsView()
                    case .explain(let grid): ExplainView(givens: grid)
                    }
                }
        }
        .fullScreenCover(item: $router.activeGame) { session in
            GameView(session: session)
                .environment(model)
                .environment(router)
        }
        .overlay {
            if let message = router.loadingMessage {
                LoadingOverlay(message: message)
            }
        }
        .onOpenURL { url in
            guard let link = ShareContent.parse(url: url), model.canOpen(link.code) else { return }
            router.activeGame = nil
            router.play { await model.sharedGame(code: link.code, challenge: link.challenge) }
        }
        .task {
            model.gameCenter.authenticate()
            model.tipJar.start()
            model.prepareUnlockedLevels()
            #if DEBUG
            // Tests manuels : xcrun simctl launch <udid> com.alexafer.sudokuno -debugOpenURL "sudokuno://p/…"
            if let s = UserDefaults.standard.string(forKey: "debugOpenURL"), let url = URL(string: s),
               let link = ShareContent.parse(url: url), model.canOpen(link.code) {
                router.play { await model.sharedGame(code: link.code, challenge: link.challenge) }
            }
            #endif
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.refreshStreak() }
            if phase == .background {
                if let game = router.activeGame { model.save(game) }
                ReminderScheduler.reschedule(streak: model.state.streak.current,
                                             doneToday: model.state.streak.isCompleted(model.today))
            }
        }
    }
}

struct LoadingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView().controlSize(.large)
                Text(message).font(.subheadline.weight(.medium))
            }
            .padding(28)
            .glassEffect(.regular, in: .rect(cornerRadius: 24))
        }
        .transition(.opacity)
    }
}
