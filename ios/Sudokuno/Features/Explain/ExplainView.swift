import SwiftUI
import SudokuKit

/// Résolution expliquée pas à pas : à chaque étape, la grille avec ses candidats, le motif repéré,
/// la technique utilisée et pourquoi elle marche.
struct ExplainView: View {
    let givens: SudokuKit.Grid

    /// Étapes déjà calculées : elles arrivent une à une, la suite se calcule pendant qu'on lit le début.
    @State private var steps: [ExplainedStep] = []
    /// Résolution complète, une fois le calcul terminé.
    @State private var explanation: Explanation?
    @State private var solution: SudokuKit.Grid?
    @State private var failed = false
    /// Étape affichée ; `steps.count` = la grille résolue.
    @State private var index = 0
    /// Dérouler les suppositions imbriquées des preuves par l'absurde.
    @State private var detailed = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let solution, !steps.isEmpty {
                    let step = index < steps.count ? steps[index] : nil
                    ExplainBoard(givens: givens, step: step, solution: solution)
                    stepCard(step)
                    controls
                    if let explanation { techniquesCard(explanation) }
                } else if failed {
                    Label(L("Cette grille n'a pas de solution unique : impossible de l'expliquer."), systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Palette.secondaryText)
                        .card()
                } else {
                    ProgressView(L("Analyse de la grille…")).padding(.top, 80)
                }
            }
            .padding(16)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .background(Palette.background.ignoresSafeArea())
        .navigationTitle(L("Explication pas à pas"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let g = givens
            // Le calcul tourne hors de l'écran et envoie chaque étape ; il s'arrête si on quitte l'écran.
            let stream = AsyncStream<Progress> { continuation in
                let work = Task.detached(priority: .userInitiated) {
                    guard let sols = Solver.solutions(g, limit: 2), sols.count == 1 else {
                        continuation.yield(.failed)
                        continuation.finish()
                        return
                    }
                    continuation.yield(.solution(sols[0]))
                    let result = Explainer.explain(g, solution: sols[0]) { step in
                        continuation.yield(.step(step))
                        return !Task.isCancelled
                    }
                    if let result { continuation.yield(.done(result)) }
                    continuation.finish()
                }
                continuation.onTermination = { _ in work.cancel() }
            }
            for await event in stream {
                switch event {
                case .failed: failed = true
                case .solution(let s): solution = s
                case .step(let s): steps.append(s)
                case .done(let e): explanation = e
                }
            }
        }
    }

    private enum Progress: Sendable {
        case failed
        case solution(SudokuKit.Grid)
        case step(ExplainedStep)
        case done(Explanation)
    }

    /// Le calcul est terminé et toutes les étapes sont là.
    private var isComplete: Bool { explanation != nil }

    // MARK: - Étape

    private func stepCard(_ step: ExplainedStep?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(step == nil ? L("Grille résolue") : L("Étape %1$@ sur %2$@", "\(index + 1)", isComplete ? "\(steps.count)" : "…"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
                    .monospacedDigit()
                    .accessibilityIdentifier("explainProgress")
                Spacer()
                if let t = step?.technique { LevelPill(level: t.level) }
            }
            if let step {
                Text(step.technique?.name ?? L("Au-delà des techniques classiques"))
                    .font(.title3.weight(.bold))
                    .accessibilityIdentifier("explainTechnique")
                Text(StepText.reason(step))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("explainReason")
                if let proof = step.step?.proof { proofList(proof) }
                let outcome = StepText.outcome(step)
                if !outcome.isEmpty {
                    Text(outcome)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.accent)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                Label(L("Tu as vu toute la résolution, en %@ étapes.", "\(steps.count)"), systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(Palette.success)
                    .accessibilityIdentifier("explainDone")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    /// Preuve par l'absurde : une ligne par conséquence, les suppositions imbriquées en retrait.
    @ViewBuilder
    private func proofList(_ proof: ForcingProof) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(StepText.proofLines(proof, detailed: detailed)) { line in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(line.isConclusion ? "⇒" : "•").foregroundStyle(line.isConclusion ? Palette.error : Palette.secondaryText)
                    Text(line.text)
                        .fontWeight(line.isConclusion ? .semibold : .regular)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.subheadline)
                .padding(.leading, CGFloat(line.indent) * 16)
            }
        }
        .accessibilityIdentifier("explainProof")
        if proof.isNested {
            Button(detailed ? L("Masquer les preuves imbriquées") : L("Détailler les preuves imbriquées")) { detailed.toggle() }
                .font(.subheadline.weight(.semibold))
                .accessibilityIdentifier("explainProofDetail")
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            if !isComplete {
                // Grilles très dures : la suite se calcule pendant qu'on lit.
                HStack(spacing: 8) {
                    ProgressView()
                    Text(L("Calcul de la suite…")).font(.subheadline).foregroundStyle(Palette.secondaryText)
                }
                .accessibilityIdentifier("explainComputing")
            }
            HStack(spacing: 10) {
                Button {
                    withAnimation(.snappy) { index -= 1 }
                } label: {
                    Label(L("Précédent"), systemImage: "chevron.left").frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.glass)
                .disabled(index == 0)
                .accessibilityIdentifier("explainPrevious")
                Button {
                    withAnimation(.snappy) { index += 1 }
                } label: {
                    Label(L("Suivant"), systemImage: "chevron.right").labelStyle(.titleAndIcon).frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.glassProminent)
                .tint(Palette.accentStrong)
                .disabled(index >= (isComplete ? steps.count : steps.count - 1))
                .accessibilityIdentifier("explainNext")
            }
            // Saute les singletons pour aller au prochain coup qui fait la difficulté de la grille.
            if let next = steps.indices.first(where: { $0 > index && steps[$0].isKey }) {
                Button {
                    withAnimation(.snappy) { index = next }
                } label: {
                    Label(L("Étape clé suivante"), systemImage: "forward.end").frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.glass)
                .accessibilityIdentifier("explainNextKey")
            }
            if index > 0 {
                Button(L("Revenir au début")) { withAnimation(.snappy) { index = 0 } }
                    .font(.subheadline)
            }
        }
    }

    // MARK: - Techniques

    private func techniquesCard(_ e: Explanation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L("Techniques utilisées"), systemImage: "graduationcap").font(.headline)
            ForEach(e.techniques, id: \.technique) { item in
                // Touche une technique pour aller à sa première utilisation.
                Button {
                    if let i = e.steps.firstIndex(where: { $0.technique == item.technique }) {
                        withAnimation(.snappy) { index = i }
                    }
                } label: {
                    HStack {
                        Circle().fill(item.technique.level.tint).frame(width: 8, height: 8)
                        Text(item.technique.name)
                        Spacer()
                        Text("× \(item.count)").foregroundStyle(Palette.secondaryText).monospacedDigit()
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            if e.reveals > 0 {
                HStack {
                    Circle().fill(Level.legende.tint).frame(width: 8, height: 8)
                    Text(L("Au-delà des techniques classiques"))
                    Spacer()
                    Text("× \(e.reveals)").foregroundStyle(Palette.secondaryText).monospacedDigit()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

/// La grille d'une étape : chiffres posés, candidats restants, motif et effets du coup mis en couleur.
private struct ExplainBoard: View {
    let givens: SudokuKit.Grid
    /// `nil` : grille résolue.
    let step: ExplainedStep?
    let solution: SudokuKit.Grid

    var body: some View {
        let marks = step.map(Marks.init)
        BoardFrame { i, size in
            let value = step?.values[i] ?? solution[i]
            ZStack {
                marks?.background(i) ?? .clear
                if value != 0 {
                    Text("\(value)")
                        .font(.gridDigit(size: size * 0.58, given: givens[i] != 0))
                        .foregroundStyle(givens[i] != 0 ? Palette.given : Palette.entry)
                } else if let step, let marks {
                    NotesView(notes: step.candidates[i], size: size) { marks.color(i, $0) }
                }
            }
            .frame(width: size, height: size)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L("Explication pas à pas"))
        .accessibilityIdentifier("explainBoard")
    }

    /// Couleurs d'une étape, calculées une fois.
    struct Marks {
        private var region = Set<Int>()
        private var focus = Set<Int>()
        private var target = Set<Int>()
        private var removedCells = Set<Int>()
        /// Clé = case * 9 + chiffre - 1.
        private var colors: [Int: Color] = [:]

        init(_ s: ExplainedStep) {
            if let step = s.step {
                for u in [step.unit].compactMap({ $0 }) + step.units { region.formUnion(Sudoku.units[u]) }
                focus = Set(step.focus)
                for c in step.focus { for d in step.digits { colors[c * 9 + Int(d) - 1] = Palette.accent } }
                // Maillons de la chaîne en deux couleurs alternées : si l'un est faux, le suivant est vrai.
                for (k, n) in step.chain.enumerated() { colors[n.cell * 9 + Int(n.digit) - 1] = k % 2 == 0 ? Palette.freeze : Palette.success }
                // Preuve par l'absurde : les chiffres imposés par l'hypothèse, et l'endroit où elle casse.
                if let proof = step.proof {
                    for link in proof.links {
                        switch link {
                        case .placement(let p, _): colors[p.cell * 9 + Int(p.digit) - 1] = Palette.freeze
                        case .exclusion(let inner): colors[inner.assumption.cell * 9 + Int(inner.assumption.digit) - 1] = Palette.flameStart
                        }
                    }
                    if case .emptyCell(let c) = proof.contradiction { removedCells.insert(c) }
                }
            }
            for e in s.eliminations {
                removedCells.insert(e.cell)
                colors[e.cell * 9 + Int(e.digit) - 1] = Palette.error
            }
            for p in s.placements {
                target.insert(p.cell)
                colors[p.cell * 9 + Int(p.digit) - 1] = Palette.success
            }
        }

        func color(_ cell: Int, _ digit: UInt8) -> Color? { colors[cell * 9 + Int(digit) - 1] }

        func background(_ i: Int) -> Color {
            if target.contains(i) { return Palette.hintCell }
            if focus.contains(i) { return Palette.hintCell.opacity(0.45) }
            if removedCells.contains(i) { return Palette.errorFill }
            if region.contains(i) { return Palette.hintRegion }
            return .clear
        }
    }
}
