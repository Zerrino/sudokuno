import SwiftUI
import SudokuKit

/// Classement affiché dans l'app : contrairement à l'interface Game Center standard,
/// il montre les indices utilisés par chaque joueur (lus dans le champ `context` du score).
struct LeaderboardView: View {
    @Environment(AppModel.self) private var model

    enum Board: Hashable {
        case daily, best, total, level(Level), streak

        var id: String {
            switch self {
            case .daily: LeaderboardID.daily
            case .best: LeaderboardID.best
            case .total: LeaderboardID.total
            case .level(let l): LeaderboardID.level(l)
            case .streak: LeaderboardID.streak
            }
        }

        var title: String {
            switch self {
            case .daily: L("Du jour")
            case .best: L("Meilleure partie")
            case .total: L("Total des scores")
            case .level(let l): L("Record %@", l.name)
            case .streak: L("Plus longue série")
            }
        }

        /// Classements de parties parfaites (le total et la série comptent tout).
        var perfectOnly: Bool { self != .total && self != .streak }
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
                    Text(Board.best.title).tag(Board.best)
                    Text(Board.total.title).tag(Board.total)
                    ForEach(Level.allCases) { Text(Board.level($0).title).tag(Board.level($0)) }
                    Text(Board.streak.title).tag(Board.streak)
                }
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    if board != .streak {
                        Text(L("Classement au score : chaque chiffre rapporte selon la technique qu'il demandait et le temps mis à le trouver."))
                    }
                    if board.perfectOnly {
                        Text(L("Seules les grilles parfaites sont classées : sans indice, sans erreur et du premier coup."))
                    }
                    if board == .total {
                        Text(L("Le meilleur score de chaque grille réussie, additionné."))
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
                                if board.perfectOnly {
                                    Text(ShareContent.hintsText(row.context.hints, enabled: row.context.hintsEnabled))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if board == .streak {
                                Image(systemName: "flame.fill").foregroundStyle(Palette.flameStart)
                                Text("\(row.value)").font(.headline.monospacedDigit())
                            } else {
                                Text(L("%@ pts", row.value.formatted(.number.locale(L10n.locale)))).font(.headline.monospacedDigit())
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
