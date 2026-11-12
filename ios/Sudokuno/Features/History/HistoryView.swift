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
                    Button {
                        open(entry)
                    } label: {
                        if let saved = entry.abandoned {
                            row(title: GameMode.title(entry.mode, code: entry.code, level: entry.level), level: entry.level,
                                detail: L("Abandonnée") + " · " + L("%lld/81 cases · %@", saved.values.filter { $0 != 0 }.count, TimeFormat.clock(saved.elapsed)),
                                date: entry.completedAt, symbol: "flag.fill", tint: .gray)
                        } else {
                            row(title: GameMode.title(entry.mode, code: entry.code, level: entry.level), level: entry.level,
                                detail: "⏱ \(TimeFormat.clock(entry.seconds)) · " + ShareContent.hintsText(entry.hints, enabled: entry.hintsEnabled)
                                    + " · " + L("%lld erreurs", entry.mistakes),
                                date: entry.completedAt, symbol: "checkmark.circle.fill")
                        }
                    }
                    .buttonStyle(.plain)
                    if let review = entry.review { reviewButton(review) }
                    }
                    .swipeActions(edge: .leading) {
                        if let review = entry.review {
                            Button(L("Revoir la partie"), systemImage: "play.rectangle") { router.path.append(.playback(review)) }
                                .tint(Palette.accentStrong)
                        }
                    }
                    .contextMenu {
                        if let review = entry.review {
                            Button {
                                router.path.append(.playback(review))
                            } label: {
                                Label(L("Revoir la partie"), systemImage: "play.rectangle")
                            }
                        }
                        Button {
                            open(entry)
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
                }
            }
        }
        .navigationTitle(L("Historique"))
    }

    private func open(_ entry: HistoryEntry) {
        if entry.isAbandoned {
            router.activeGame = model.resumeAbandoned(entry)
        } else {
            router.play { await model.replay(entry) }
        }
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

    /// Bouton « Revoir la partie », à côté de la ligne (jamais à l'intérieur de son bouton : les deux touches se mélangeraient).
    private func reviewButton(_ review: Playback) -> some View {
        Button {
            router.path.append(.playback(review))
        } label: {
            Image(systemName: "play.rectangle.fill").font(.title3).foregroundStyle(Palette.accent)
                .frame(minWidth: 36, minHeight: 36)
                .contentShape(.rect)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(L("Revoir la partie"))
        .accessibilityIdentifier("reviewGame")
    }
}
