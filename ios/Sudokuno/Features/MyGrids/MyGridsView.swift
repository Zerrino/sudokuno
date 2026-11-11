import SwiftUI
import SudokuKit

/// « Mes grilles » : les grilles créées avec l'éditeur et celles reçues par lien ou par code.
struct MyGridsView: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @State private var tab = Tab.created
    /// Niveau des grilles créées, calculé en arrière-plan (le classement d'une grille prend quelques ms).
    @State private var levels: [String: Level] = [:]

    enum Tab: Hashable { case created, received }

    var body: some View {
        let records = tab == .created ? model.state.createdGrids : model.state.receivedGrids
        List {
            Section {
                Picker(L("Mes grilles"), selection: $tab) {
                    Text(L("Créées")).tag(Tab.created)
                    Text(L("Reçues")).tag(Tab.received)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .accessibilityIdentifier("myGridsTabs")
            }
            Section {
                if records.isEmpty {
                    Text(tab == .created ? L("Aucune grille créée. Crée la tienne avec l'éditeur !")
                                         : L("Les grilles reçues par lien ou par code apparaîtront ici."))
                        .foregroundStyle(.secondary)
                }
                ForEach(records) { record in
                    if let code = record.puzzleCode {
                        row(record, code: code)
                    }
                }
            }
        }
        .navigationTitle(L("Mes grilles"))
        .task(id: tab) { await computeLevels(records) }
    }

    private func row(_ record: GridRecord, code: PuzzleCode) -> some View {
        let level = level(of: code, key: record.code)
        return Button {
            router.play { await model.openGrid(code) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: tab == .created ? "pencil.and.outline" : "tray.and.arrow.down.fill")
                    .font(.title2)
                    .foregroundStyle(level?.tint ?? .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(GameMode.title(.shared(nil), code: code, level: level ?? .facile)).font(.headline)
                    Text(status(record.code)).font(.subheadline).foregroundStyle(.secondary).monospacedDigit()
                }
                Spacer()
                Text(record.date.formatted(Date.RelativeFormatStyle(presentation: .named, unitsStyle: .abbreviated, locale: L10n.locale)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("myGrid-\(record.code)")
        .swipeActions {
            Button(L("Supprimer"), role: .destructive) { model.forget(record, received: tab == .received) }
        }
        .contextMenu {
            ShareLink(item: ShareContent.inviteMessage(code: code, level: level ?? .facile)) {
                Label(L("Partager cette grille"), systemImage: "square.and.arrow.up")
            }
        }
    }

    private func status(_ code: String) -> String {
        if model.isInProgress(code) { return L("En cours") }
        if let best = model.bestTime(code) { return L("Résolue · %@", TimeFormat.clock(best)) }
        return L("Pas encore jouée")
    }

    private func level(of code: PuzzleCode, key: String) -> Level? {
        switch code {
        case .custom: levels[key]
        case .daily(let day): DailySchedule.level(for: day)
        default: code.level
        }
    }

    private func computeLevels(_ records: [GridRecord]) async {
        for record in records where levels[record.code] == nil {
            guard case .custom(let grid) = record.puzzleCode else { continue }
            let level = await Task.detached(priority: .utility) { Grader.grade(grid) }.value
            levels[record.code] = level
        }
    }
}
