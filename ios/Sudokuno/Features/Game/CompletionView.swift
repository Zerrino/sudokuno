import SwiftUI
import SudokuKit

struct CompletionView: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    let summary: CompletionSummary
    /// Chiffres de départ de la grille, pour en montrer la résolution expliquée.
    let givens: SudokuKit.Grid
    @State private var appeared = false

    var body: some View {
        let streak = model.state.streak.current
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    Image(systemName: summary.isPerfect ? "star.circle.fill" : "checkmark.seal.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(summary.isPerfect ? AnyShapeStyle(Palette.flame) : AnyShapeStyle(Palette.success))
                        .symbolEffect(.bounce, value: appeared)
                    Text(summary.isPerfect ? L("Parfait !") : L("Bravo !"))
                        .font(.largeTitle.weight(.heavy))
                        .accessibilityIdentifier("completionTitle")
                    Text(subtitle).font(.headline).foregroundStyle(Palette.secondaryText)

                    HStack(spacing: 12) {
                        stat(TimeFormat.clock(summary.seconds), L("Temps"), "timer")
                        stat("\(summary.mistakes)", L("Erreurs"), "xmark.circle")
                        stat(summary.hintsEnabled ? "\(summary.hints)" : "–", L("Indices"), "lightbulb")
                    }

                    if summary.isNewRecord, let previous = summary.previousBest {
                        banner(L("Nouveau record ! (avant : %@)", TimeFormat.clock(previous)), "trophy.fill", Palette.flameEnd)
                    }
                    if let challenge = summary.mode.challenge {
                        let won = summary.seconds < challenge.seconds
                        let diff = abs(challenge.seconds - summary.seconds)
                        banner(won ? L("Défi réussi : %@ plus rapide !", TimeFormat.clock(diff)) : L("Défi raté de %@. Retente ta chance !", TimeFormat.clock(diff)),
                               "flag.checkered", won ? Palette.success : Palette.error)
                    }
                    if summary.countsForDaily, let s = summary.streak {
                        HStack(spacing: 12) {
                            FlameBadge(count: s, size: 48)
                            VStack(alignment: .leading) {
                                Text(L("%lld jours de série", s)).font(.headline)
                                if let m = summary.milestone {
                                    Text(L("Jalon atteint : %lld jours 🎉", m)).font(.subheadline).foregroundStyle(Palette.secondaryText)
                                } else {
                                    Text(L("Reviens demain pour la prolonger.")).font(.subheadline).foregroundStyle(Palette.secondaryText)
                                }
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Palette.flameEnd.opacity(0.14), in: .rect(cornerRadius: 16))
                    }
                    if let unlocked = summary.unlocked {
                        banner(L("Niveau %@ débloqué !", unlocked.name), "lock.open.fill", unlocked.tint)
                    }

                    VStack(spacing: 10) {
                        ShareLink(item: ShareContent.resultMessage(summary, streak: streak),
                                  preview: SharePreview(L("Défi Sudokuno"), image: shareImage(streak: streak))) {
                            Label(L("Partager mon temps"), systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(Palette.accentStrong)

                        if summary.mode == .level {
                            Button {
                                router.play { await model.newLevelGame(summary.level) }
                            } label: {
                                Text(L("Nouvelle grille %@", summary.level.name))
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .buttonStyle(.glass)
                        }
                        Button {
                            router.activeGame = nil
                            router.path.append(.explain(givens))
                        } label: {
                            Label(L("Voir la résolution expliquée"), systemImage: "list.number")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.glass)
                        .accessibilityIdentifier("completionExplain")
                        Button {
                            router.activeGame = nil
                        } label: {
                            Text(L("Accueil")).font(.headline).frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.glass)
                        .accessibilityIdentifier("completionHome")
                    }
                    .padding(.top, 4)
                }
                .padding(24)
                .background(Palette.card, in: .rect(cornerRadius: 28, style: .continuous))
                .padding(20)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .onAppear { appeared = true }
    }

    private var subtitle: String {
        switch summary.mode {
        case .daily: summary.countsForDaily ? L("Sudoku du jour réussi") : L("Grille d'un jour passé réussie")
        case .level: L("Grille %@ terminée", summary.level.name)
        case .shared: L("Grille partagée terminée")
        }
    }

    private func stat(_ value: String, _ label: String, _ symbol: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol).foregroundStyle(Palette.accent)
            Text(value).font(.title2.weight(.bold)).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(Palette.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Palette.background, in: .rect(cornerRadius: 14))
    }

    private func banner(_ text: String, _ symbol: String, _ color: Color) -> some View {
        Label(text, systemImage: symbol)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(color.opacity(0.12), in: .rect(cornerRadius: 14))
    }

    private func shareImage(streak: Int) -> Image {
        let renderer = ImageRenderer(content: ShareCardView(summary: summary, streak: streak))
        renderer.scale = 3
        return renderer.uiImage.map(Image.init(uiImage:)) ?? Image(systemName: "square.grid.3x3.fill")
    }
}
