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

            Section(L("Terminées")) {
                if model.state.history.isEmpty {
                    Text(L("Les grilles que tu termines apparaîtront ici.")).foregroundStyle(.secondary)
                }
                ForEach(model.state.history) { entry in
                    Button {
                        router.play { await model.replay(entry) }
                    } label: {
                        row(title: GameMode.title(entry.mode, code: entry.code, level: entry.level), level: entry.level,
                            detail: "⏱ \(TimeFormat.clock(entry.seconds)) · " + ShareContent.hintsText(entry.hints, enabled: entry.hintsEnabled),
                            date: entry.completedAt, symbol: "checkmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        ShareLink(item: ShareContent.inviteMessage(code: entry.code, level: entry.level)) {
                            Label(L("Partager cette grille"), systemImage: "square.and.arrow.up")
                        }
                        Button {
                            router.play { await model.replay(entry) }
                        } label: {
                            Label(L("Rejouer"), systemImage: "arrow.counterclockwise")
                        }
                    }
                }
            }
        }
        .navigationTitle(L("Historique"))
    }

    private func row(title: String, level: Level, detail: String, date: Date, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(level.tint)
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
}
