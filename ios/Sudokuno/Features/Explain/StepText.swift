import SudokuKit

/// Rédige en clair un coup de la résolution : ce qu'on observe, pourquoi cela marche, ce qu'on en tire.
/// Même logique et mêmes textes que `StepText.kt` côté Android.
enum StepText {
    /// « L3C7 » : ligne 3, colonne 7 (notation habituelle des solveurs).
    static func cell(_ i: Int) -> String { L("L%1$@C%2$@", "\(Sudoku.row(i) + 1)", "\(Sudoku.col(i) + 1)") }

    static func cells(_ list: [Int]) -> String { list.map(cell).joined(separator: ", ") }

    static func digits(_ list: [UInt8]) -> String { list.map { "\($0)" }.joined(separator: ", ") }

    /// « la ligne 3 », « la colonne 7 », « le bloc 5 ».
    static func unit(_ u: Int) -> String {
        switch Sudoku.unitName(u) {
        case .row(let r): L("la ligne %@", "\(r + 1)")
        case .column(let c): L("la colonne %@", "\(c + 1)")
        case .box(let b): L("le bloc %@", "\(b + 1)")
        }
    }

    /// « les lignes 2, 7 » (unités toutes du même type).
    static func units(_ list: [Int]) -> String {
        let numbers = list.map { "\($0 % 9 + 1)" }.joined(separator: ", ")
        return (list.first ?? 0) < 9 ? L("les lignes %@", numbers) : L("les colonnes %@", numbers)
    }

    /// « 5·L1C2 = 5·L1C8 – 5·L3C9 = 5·L7C9 » : = lien fort, – lien faible.
    static func chain(_ nodes: [CandidateRef]) -> String {
        nodes.enumerated().map { i, n in
            (i == 0 ? "" : (i % 2 == 1 ? " = " : " – ")) + "\(n.digit)·\(cell(n.cell))"
        }.joined()
    }

    /// Le raisonnement.
    static func reason(_ s: ExplainedStep) -> String {
        guard let step = s.step else {
            let p = s.placements[0]
            return L("Aucune des techniques de Sudokuno ne permet d'avancer ici : cette grille demande des méthodes encore plus avancées. On pose le %1$@ en %2$@, tiré de la solution, pour continuer.", "\(p.digit)", cell(p.cell))
        }
        let d = step.digits.first.map { "\($0)" } ?? ""
        switch step.technique {
        case .nakedSingle:
            return L("La case %1$@ n'a plus qu'un candidat : le %2$@. Tous les autres chiffres sont déjà dans sa ligne, sa colonne ou son bloc.", cell(step.focus[0]), d)
        case .hiddenSingle:
            return L("Dans %1$@, le %2$@ ne peut aller qu'en %3$@ : il est exclu de toutes les autres cases.", unit(step.unit ?? 0), d, cell(step.focus[0]))
        case .pointing, .boxLineReduction:
            return L("Dans %1$@, toutes les places possibles du %2$@ se trouvent aussi dans %3$@. Le %2$@ occupera donc l'une d'elles : on le retire des autres cases dans %3$@.", unit(step.unit ?? 0), d, unit(step.units.first ?? 0))
        case .nakedPair, .nakedTriple:
            return L("Dans %1$@, les cases %2$@ ne contiennent ensemble que les candidats %3$@. Ces chiffres leur sont réservés : on les retire des autres cases dans %1$@.", unit(step.unit ?? 0), cells(step.focus), digits(step.digits))
        case .hiddenPair, .hiddenTriple:
            return L("Dans %1$@, les chiffres %2$@ ne peuvent aller que dans les cases %3$@. Ces cases leur sont réservées : on y retire tous les autres candidats.", unit(step.unit ?? 0), digits(step.digits), cells(step.focus))
        case .xWing, .swordfish:
            let n = step.units.count / 2
            return L("Dans %2$@, le %1$@ n'a de place que dans %3$@. Il occupera forcément ces croisements : on le retire de toutes les autres cases dans %3$@.", d, units(Array(step.units.prefix(n))), units(Array(step.units.suffix(n))))
        case .xyWing:
            return L("Le pivot %1$@ n'a que deux candidats. Quel que soit le bon, l'une des deux ailes (%2$@) prendra le %3$@. Une case qui voit les deux ailes ne peut donc pas contenir le %3$@.", cell(step.focus[0]), cells(Array(step.focus.dropFirst())), d)
        case .xyzWing:
            return L("Le pivot %1$@ et ses deux ailes (%2$@) contiennent tous le %3$@, et l'une de ces trois cases le prendra forcément. Une case qui voit les trois ne peut donc pas contenir le %3$@.", cell(step.focus[0]), cells(Array(step.focus.dropFirst())), d)
        case .forcingChain, .forcingNet:
            let a = step.eliminations[0]
            return L("Les techniques classiques ne suffisent plus : on raisonne par l'absurde. Supposons que %1$@ contienne le %2$@. Voici ce que cela impose, coup après coup :", cell(a.cell), "\(a.digit)")
        case .turbotFish, .xChain, .xyChain, .aic:
            return L("Suis la chaîne : %@. Le signe = est un lien fort (si l'un est faux, l'autre est vrai) ; le signe – est un lien faible (si l'un est vrai, l'autre est faux). Si le premier maillon est faux, le dernier est vrai : l'un des deux bouts est donc forcément vrai, et tout candidat incompatible avec les deux est retiré.", chain(step.chain))
        }
    }

    /// Une ligne d'une preuve par l'absurde ; `indent` > 0 pour une supposition imbriquée.
    struct ProofLine: Identifiable, Hashable {
        let id: Int
        let indent: Int
        let text: String
        /// Dernière ligne d'un bloc : la contradiction ou la conclusion.
        let isConclusion: Bool
    }

    /// La preuve, ligne par ligne. `detailed` : dérouler aussi les suppositions imbriquées.
    static func proofLines(_ proof: ForcingProof, detailed: Bool) -> [ProofLine] {
        var lines: [ProofLine] = []
        func add(_ indent: Int, _ text: String, conclusion: Bool = false) {
            lines.append(ProofLine(id: lines.count, indent: indent, text: text, isConclusion: conclusion))
        }
        func walk(_ p: ForcingProof, _ indent: Int) {
            for link in p.links {
                switch link {
                case .placement(let pl, .nakedSingle):
                    add(indent, L("%1$@ = %2$@ : c'est son seul candidat restant.", cell(pl.cell), "\(pl.digit)"))
                case .placement(let pl, .hiddenSingle(let u)):
                    add(indent, L("%1$@ = %2$@ : c'est la seule place du %2$@ dans %3$@.", cell(pl.cell), "\(pl.digit)", unit(u)))
                case .exclusion(let inner):
                    let a = inner.assumption
                    if detailed {
                        add(indent, L("%1$@ ne peut pas contenir le %2$@. En effet, si c'était le cas :", cell(a.cell), "\(a.digit)"))
                        walk(inner, indent + 1)
                    } else {
                        add(indent, L("%1$@ ne peut pas contenir le %2$@ : cela mènerait aussi à une contradiction (preuve imbriquée, %3$@ coups).", cell(a.cell), "\(a.digit)", "\(inner.size)"))
                    }
                }
            }
            switch p.contradiction {
            case .emptyCell(let c):
                add(indent, L("Contradiction : %@ n'a plus aucun candidat.", cell(c)), conclusion: true)
            case .noPlace(let u, let d):
                add(indent, L("Contradiction : le %1$@ n'a plus aucune place dans %2$@.", "\(d)", unit(u)), conclusion: true)
            }
        }
        walk(proof, 0)
        add(0, L("L'hypothèse est donc fausse : %1$@ ne contient pas le %2$@.", cell(proof.assumption.cell), "\(proof.assumption.digit)"), conclusion: true)
        return lines
    }

    /// Ce que le coup change dans la grille.
    static func outcome(_ s: ExplainedStep) -> String {
        var lines = s.step == nil ? [] : s.placements.map { L("On place le %1$@ en %2$@.", "\($0.digit)", cell($0.cell)) }
        let removed = s.eliminations
        if !removed.isEmpty {
            var items = removed.prefix(8).map { "\(cell($0.cell)) ≠ \($0.digit)" }
            if removed.count > 8 { items.append("…") }
            lines.append(L("Candidats retirés : %@.", items.joined(separator: ", ")))
        }
        return lines.joined(separator: "\n")
    }
}
