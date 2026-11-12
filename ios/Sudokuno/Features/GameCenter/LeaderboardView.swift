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
                    ForEach(Level.generated) { Text(Board.level($0).title).tag(Board.level($0)) }
                    Text(Board.streak.title).tag(Board.streak)
                }
            } footer: {
                // Pas de choix « Du jour, sans indice » : seules les grilles parfaites sont classées, il ferait doublon.
                VStack(alignment: .leading, spacing: 4) {
                    if board != .streak {
                        Text(L("Seules les grilles parfaites sont classées : sans indice, sans erreur et du premier coup."))
                    }
                    if board == .daily {
                        Text(L("Remis à zéro chaque jour à minuit UTC, avec la grille du jour."))
                    }
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
                                .font((row.rank > 99 ? Font.caption : Font.subheadline).weight(.bold).monospacedDigit())
                                .foregroundStyle(Self.medal(row.rank) == nil ? AnyShapeStyle(.secondary) : AnyShapeStyle(.white))
                                .frame(width: 32, height: 32)
                                .background(Self.medal(row.rank) ?? .clear, in: .circle)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.name)
                                    .fontWeight(row.isLocalPlayer ? .bold : .medium)
                                    .foregroundStyle(row.isLocalPlayer ? AnyShapeStyle(Palette.accent) : AnyShapeStyle(.primary))
                                    .lineLimit(1)
                                if board != .streak {
                                    Text(ShareContent.hintsText(row.context.hints, enabled: row.context.hintsEnabled))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if board == .streak {
                                Image(systemName: "flame.fill").foregroundStyle(Palette.flameStart)
                                Text("\(row.seconds)").font(.headline.monospacedDigit())
                            } else {
                                Text(TimeFormat.clock(row.seconds)).font(.headline.monospacedDigit())
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

    /// Or, argent, bronze pour les trois premiers.
    private static func medal(_ rank: Int) -> Color? {
        switch rank {
        case 1: Color(red: 0.886, green: 0.639, blue: 0)
        case 2: Color(red: 0.557, green: 0.592, blue: 0.659)
        case 3: Color(red: 0.749, green: 0.478, blue: 0.271)
        default: nil
        }
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
