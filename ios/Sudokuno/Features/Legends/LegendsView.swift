import SwiftUI
import SudokuKit

/// Niveau Légende : les grilles célèbres pour leur difficulté, à jouer telles quelles.
struct LegendsView: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(L("Ces grilles sont célèbres dans le monde entier pour leur difficulté. Aucune technique de Sudokuno n'en vient à bout : il faudra de très longues chaînes de raisonnement, ou des essais."))
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
                    .padding(.horizontal, 4)
                ForEach(Legends.all) { legend in
                    LegendRow(legend: legend, best: model.legendBest(legend), inProgress: model.legendInProgress(legend)) {
                        router.play { await model.newLegendGame(legend) }
                    }
                    .accessibilityIdentifier("legend-\(legend.id)")
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .background(Palette.background.ignoresSafeArea())
        .navigationTitle(L("Légende"))
    }
}

private struct LegendRow: View {
    let legend: LegendPuzzle
    let best: Int?
    let inProgress: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: best != nil ? "star.fill" : "star")
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(Level.legende.tint.opacity(0.16), in: .rect(cornerRadius: 12))
                    .foregroundStyle(Level.legende.tint)
                VStack(alignment: .leading, spacing: 4) {
                    Text(legend.name).font(.headline)
                    if let credit = LegendText.credit(legend) {
                        Text(credit).font(.caption.weight(.semibold)).foregroundStyle(Palette.secondaryText)
                    }
                    Text(LegendText.story(legend))
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(status)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Level.legende.tint.opacity(0.16), in: .capsule)
                        .foregroundStyle(Level.legende.tint)
                        .padding(.top, 2)
                }
                Spacer(minLength: 0)
            }
            .card()
        }
        .buttonStyle(.plain)
        .accessibilityHint(inProgress ? L("Reprendre") : L("Lance la grille"))
    }

    private var status: String {
        if inProgress { return L("En cours") }
        if let best { return L("Résolue · record %@", TimeFormat.clock(best)) }
        return L("Pas encore résolue")
    }
}

/// Textes des grilles de la Légende (traduits).
enum LegendText {
    static func credit(_ legend: LegendPuzzle) -> String? {
        switch (legend.author, legend.year) {
        case let (author?, year?): "\(author) · \(year)"
        case let (author?, nil): author
        default: L("Forums de passionnés")
        }
    }

    static func story(_ legend: LegendPuzzle) -> String {
        switch legend.id {
        case "escargot": L("Publiée en 2006 par le mathématicien finlandais Arto Inkala, qui la présentait comme la grille la plus difficile du monde.")
        case "inkala2010": L("Arto Inkala dit avoir mis trois mois à créer cette grille, encore plus dure qu'AI Escargot.")
        case "inkala2012": L("La « grille la plus difficile du monde » qui a fait le tour de la presse en juin 2012.")
        case "easter-monster": L("Célèbre chez les spécialistes pour son motif presque symétrique en croix : l'une des grilles les plus dures connues.")
        case "golden-nugget": L("Longtemps en tête des classements de difficulté établis par les passionnés.")
        case "platinum-blonde": L("Jugée la plus difficile par les chercheurs Ercsey-Ravasz et Toroczkai, qui mesurent la difficulté comme du chaos.")
        case "unsolvable28", "unsolvable49": L("Une des grilles « insolubles » de SudokuWiki : aucune technique logique classique n'en vient à bout.")
        default: ""
        }
    }
}
