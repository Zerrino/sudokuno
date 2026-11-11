import SwiftUI
import SudokuKit

/// Classement affiché dans l'app : contrairement à l'interface Game Center standard,
/// il montre les indices utilisés par chaque joueur (lus dans le champ `context` du score).
struct LeaderboardView: View {
    @Environment(AppModel.self) private var model

    enum Board: Hashable {
        case daily, dailyNoHint, level(Level), streak

        var id: String {
            switch self {
            case .daily: LeaderboardID.daily
            case .dailyNoHint: LeaderboardID.dailyNoHint
            case .level(let l): LeaderboardID.best(l)
            case .streak: LeaderboardID.streak
            }
        }

        var title: String {
            switch self {
            case .daily: L("Du jour")
            case .dailyNoHint: L("Du jour, sans indice")
            case .level(let l): L("Record %@", l.name)
            case .streak: L("Plus longue série")
            }
        }
    }

    @State private var board: Board = .daily
    @State private var rows: [LeaderboardRow] = []
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        List {
            Section {
                Picker(L("Classement"), selection: $board) {
                    Text(Board.daily.title).tag(Board.daily)
                    Text(Board.dailyNoHint.title).tag(Board.dailyNoHint)
                    ForEach(Level.generated) { Text(Board.level($0).title).tag(Board.level($0)) }
                    Text(Board.streak.title).tag(Board.streak)
                }
            } footer: {
                if board == .daily || board == .dailyNoHint {
                    Text(L("Remis à zéro chaque jour à minuit UTC, avec la grille du jour."))
                }
            }

            if !model.gameCenter.isAuthenticated {
                Section {
                    Label(L("Connecte-toi à Game Center (Réglages › Game Center) pour voir les classements."), systemImage: "person.crop.circle.badge.exclamationmark")
                        .foregroundStyle(.secondary)
                }
            } else if loading {
                Section { HStack { Spacer(); ProgressView(); Spacer() } }
            } else if let error {
                Section { Text(error).foregroundStyle(.secondary) }
            } else if rows.isEmpty {
                Section { Text(L("Aucun score pour l'instant. Sois le premier !")).foregroundStyle(.secondary) }
            } else {
                Section {
                    ForEach(rows) { row in
                        HStack(spacing: 12) {
                            Text("\(row.rank)")
                                .font(.headline.monospacedDigit())
                                .frame(width: 32)
                                .foregroundStyle(row.rank <= 3 ? Palette.flameEnd : .secondary)
                            Text(row.name)
                                .fontWeight(row.isLocalPlayer ? .bold : .regular)
                                .lineLimit(1)
                            Spacer()
                            if board == .streak {
                                Label("\(row.seconds)", systemImage: "flame.fill").foregroundStyle(Palette.flameStart)
                            } else {
                                Text(ShareContent.hintsText(row.context.hints, enabled: row.context.hintsEnabled))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(TimeFormat.clock(row.seconds)).font(.body.monospacedDigit().weight(.semibold))
                            }
                        }
                        .listRowBackground(row.isLocalPlayer ? Palette.accent.opacity(0.1) : nil)
                    }
                }
            }

            if model.gameCenter.isAuthenticated {
                Section {
                    Button(L("Ouvrir Game Center")) { model.gameCenter.showDashboard() }
                    Button(L("Voir mes succès")) { model.gameCenter.showAchievements() }
                }
            }
        }
        .navigationTitle(L("Classements"))
        .task(id: board) { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        guard model.gameCenter.isAuthenticated else { return }
        loading = true
        defer { loading = false }
        do {
            rows = try await model.gameCenter.loadTop(board.id)
            error = nil
        } catch {
            rows = []
            self.error = L("Classement indisponible pour le moment.")
        }
    }
}
