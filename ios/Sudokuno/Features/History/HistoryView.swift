import SwiftUI
import SudokuKit

/// Parties en cours (à reprendre, plusieurs à la fois) et grilles terminées (à rejouer ou partager).
struct HistoryView: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    var body: some View {
        List {
            Section {
                if model.inProgress.isEmpty {
                    Text(L("Aucune partie en cours.")).foregroundStyle(.secondary)
                }
                ForEach(model.inProgress, id: \.code) { saved in
                    Button {
                        router.activeGame = model.resume(saved)
                    } label: {
                        row(title: saved.title, level: saved.level,
                            detail: L("%lld/81 cases · %@", saved.values.filter { $0 != 0 }.count, TimeFormat.clock(saved.elapsed)),
                            date: saved.updatedAt, symbol: "play.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(L("Supprimer"), role: .destructive) { model.deleteSaved(saved) }
                    }
                }
            } header: {
                Text(L("En cours"))
            } footer: {
                if !model.inProgress.isEmpty { Text(L("Glisse vers la gauche pour supprimer une partie.")) }
            }

            Section {
                if model.state.history.isEmpty {
                    Text(L("Les grilles que tu termines apparaîtront ici.")).foregroundStyle(.secondary)
                }
                ForEach(model.state.history) { entry in
                    HStack(spacing: 8) {
                        // Toucher une partie finie montre la grille telle qu'elle a été jouée ; une partie abandonnée reprend.
                        Button {
                            open(entry)
                        } label: {
                            row(title: GameMode.title(entry.mode, code: entry.code, level: entry.level), level: entry.level,
                                detail: detail(entry), date: entry.completedAt,
                                symbol: entry.isAbandoned ? "flag.fill" : (entry.isFailed ? "xmark.circle.fill" : "checkmark.circle.fill"),
                                tint: entry.isAbandoned ? .gray : (entry.isFailed ? Palette.error : nil))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("historyEntry")
                        // À côté de la ligne, jamais dedans : revoir une partie abandonnée, ou rejouer une grille finie.
                        if entry.isAbandoned {
                            if entry.review != nil { sideButton("play.rectangle.fill", L("Revoir la partie"), id: "reviewGame") { router.path.append(.playback(entry)) } }
                        } else {
                            sideButton("arrow.counterclockwise", L("Rejouer"), id: "replayGrid") { router.play { await model.replay(entry) } }
                        }
                    }
                    .contextMenu {
                        if entry.review != nil {
                            Button {
                                router.path.append(.playback(entry))
                            } label: {
                                Label(L("Revoir la partie"), systemImage: "play.rectangle")
                            }
                        }
                        Button {
                            if entry.isAbandoned { router.activeGame = model.resumeAbandoned(entry) } else { router.play { await model.replay(entry) } }
                        } label: {
                            if entry.isAbandoned {
                                Label(L("Reprendre"), systemImage: "play.fill")
                            } else {
                                Label(L("Rejouer"), systemImage: "arrow.counterclockwise")
                            }
                        }
                        ShareLink(item: ShareContent.inviteMessage(code: entry.code, level: entry.level)) {
                            Label(L("Partager cette grille"), systemImage: "square.and.arrow.up")
                        }
                    }
                }
            } header: {
                Text(L("Terminées"))
            } footer: {
                if model.state.history.contains(where: \.isAbandoned) {
                    Text(L("Touche une partie abandonnée pour la reprendre où tu l'avais laissée."))
                } else if !model.state.history.isEmpty {
                    Text(L("Touche une partie pour revoir ta grille et tes coups."))
                }
            }
        }
        .navigationTitle(L("Historique"))
    }

    private func open(_ entry: HistoryEntry) {
        if entry.isAbandoned {
            router.activeGame = model.resumeAbandoned(entry)
        } else if entry.review != nil {
            router.path.append(.playback(entry))
        } else {
            // Partie d'avant le replay : on ne peut que rejouer la grille.
            router.play { await model.replay(entry) }
        }
    }

    /// Temps, indices, erreurs et score d'une partie ; état d'une partie abandonnée ou ratée.
    private func detail(_ entry: HistoryEntry) -> String {
        if let saved = entry.abandoned {
            return L("Abandonnée") + " · " + L("%lld/81 cases · %@", saved.values.filter { $0 != 0 }.count, TimeFormat.clock(saved.elapsed))
        }
        var parts = ["⏱ \(TimeFormat.clock(entry.seconds))", ShareContent.hintsText(entry.hints, enabled: entry.hintsEnabled),
                     L("%lld erreurs", entry.mistakes)]
        if entry.isFailed { parts.insert(L("Ratée"), at: 0) }
        if let score = entry.score { parts.append(L("%@ pts", score.total.formatted(.number.locale(L10n.locale)))) }
        return parts.joined(separator: " · ")
    }

    private func row(title: String, level: Level, detail: String, date: Date, symbol: String, tint: Color? = nil) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(tint ?? level.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary).monospacedDigit()
            }
            Spacer()
            Text(date.formatted(Date.RelativeFormatStyle(presentation: .named, unitsStyle: .abbreviated, locale: L10n.locale)))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .contentShape(.rect)
    }

    private func sideButton(_ symbol: String, _ label: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.title3).foregroundStyle(Palette.accent)
                .frame(minWidth: 36, minHeight: 36)
                .contentShape(.rect)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(label)
        .accessibilityIdentifier(id)
    }
}
