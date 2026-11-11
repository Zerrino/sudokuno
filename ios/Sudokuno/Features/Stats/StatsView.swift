import SwiftUI
import SudokuKit

struct StatsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        List {
            Section(L("Sudoku du jour")) {
                let results = model.state.dailyResults.values.filter(\.onTime)
                LabeledContent(L("Grilles réussies"), value: "\(results.count)")
                LabeledContent(L("Série actuelle"), value: "\(model.state.streak.current)")
                LabeledContent(L("Plus longue série"), value: "\(model.state.streak.longest)")
                if let best = results.map(\.seconds).min() {
                    LabeledContent(L("Meilleur temps"), value: TimeFormat.clock(best))
                }
                LabeledContent(L("Défis gagnés"), value: "\(model.state.challengesWon)")
            }
            ForEach(Level.allCases) { level in
                let s = model.state.stats[level] ?? LevelStats()
                Section {
                    LabeledContent(L("Parties commencées"), value: "\(s.started)")
                    LabeledContent(L("Victoires"), value: "\(s.won)")
                    if let rate = s.winRate {
                        LabeledContent(L("Taux de réussite"), value: rate.formatted(.percent.precision(.fractionLength(0)).locale(L10n.locale)))
                    }
                    LabeledContent(L("Meilleur temps"), value: s.bestSeconds.map(TimeFormat.clock) ?? "–")
                    LabeledContent(L("Temps moyen"), value: s.averageSeconds.map(TimeFormat.clock) ?? "–")
                    LabeledContent(L("Parfaites (0 indice, 0 erreur)"), value: "\(s.perfect)")
                } header: {
                    Label(level.name, systemImage: model.state.progress.isUnlocked(level) ? level.symbol : "lock.fill")
                        .foregroundStyle(level.tint)
                }
            }
        }
        .monospacedDigit()
        .navigationTitle(L("Statistiques"))
    }
}
