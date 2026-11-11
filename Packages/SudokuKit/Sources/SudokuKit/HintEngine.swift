/// Un indice, présenté au joueur en 3 étapes :
/// 1. la zone (`region`) et la technique ; 2. la case et le motif (`cell`, `focus`) ; 3. le coup appliqué.
public struct Hint: Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        /// Un chiffre placé par le joueur est faux : l'étape 3 l'efface.
        case mistake
        /// Un chiffre peut être placé logiquement.
        case placement
        /// Aucune de nos techniques ne trouve de coup : on révèle une case.
        case revelation
    }

    public let kind: Kind
    public let cell: Int
    public let digit: UInt8
    /// Technique qui permet de placer le chiffre.
    public let technique: Technique?
    /// Technique d'élimination la plus difficile utilisée avant (ex. une paire), s'il y en a une.
    public let supportingTechnique: Technique?
    public let region: [Int]
    public let focus: [Int]
}

public enum HintEngine {

    /// Calcule un indice à partir de l'état ACTUEL de la grille du joueur (sans tenir compte de ses notes).
    public static func hint(values: [UInt8], solution: Grid) -> Hint? {
        if let wrong = (0..<81).first(where: { values[$0] != 0 && values[$0] != solution[$0] }) {
            return Hint(kind: .mistake, cell: wrong, digit: solution[wrong], technique: nil, supportingTechnique: nil,
                        region: Sudoku.units[18 + Sudoku.box(wrong)], focus: [wrong])
        }
        guard values.contains(0) else { return nil }

        var solver = LogicalSolver(Grid(cells: values))
        var supporting: Technique?
        while let step = solver.nextStep() {
            if let p = step.placements.first {
                let region = step.unit.map { Sudoku.units[$0] } ?? Sudoku.units[18 + Sudoku.box(p.cell)]
                return Hint(kind: .placement, cell: p.cell, digit: p.digit, technique: step.technique,
                            supportingTechnique: supporting, region: region, focus: step.focus)
            }
            supporting = max(supporting ?? step.technique, step.technique)
            solver.apply(step)
        }

        // Bloqué : on révèle la case vide la plus contrainte.
        let cell = (0..<81).filter { values[$0] == 0 }
            .min { solver.candidates[$0].nonzeroBitCount < solver.candidates[$1].nonzeroBitCount }!
        return Hint(kind: .revelation, cell: cell, digit: solution[cell], technique: nil, supportingTechnique: nil,
                    region: Sudoku.units[18 + Sudoku.box(cell)], focus: [cell])
    }
}
