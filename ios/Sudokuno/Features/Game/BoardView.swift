import SwiftUI
import SudokuKit

/// La grille 9×9. Elle reste opaque et nette (pas de Liquid Glass sous les chiffres).
struct BoardView: View {
    @Bindable var session: GameSession
    @AppStorage(SettingKey.highlightConflicts) private var highlightConflicts = true
    @AppStorage(SettingKey.highlightSameDigits) private var highlightSame = true
    @AppStorage(SettingKey.highlightRelated) private var highlightRelated = true
    @AppStorage(SettingKey.showMistakes) private var showMistakes = true

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = side / 9
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { r in
                        HStack(spacing: 0) {
                            ForEach(0..<9, id: \.self) { c in
                                let i = r * 9 + c
                                CellView(
                                    value: session.values[i],
                                    notes: session.notes[i],
                                    isGiven: session.isGiven(i),
                                    isError: isError(i),
                                    background: background(i),
                                    size: cell
                                )
                                .onTapGesture {
                                    session.select(i)
                                    Haptics.tap()
                                }
                                .accessibilityElement()
                                .accessibilityLabel(accessibilityLabel(i))
                                .accessibilityAddTraits(session.selected == i ? [.isButton, .isSelected] : .isButton)
                                .accessibilityIdentifier("cell-\(i)")
                            }
                        }
                    }
                }
                GridLines()
                    .allowsHitTesting(false)
            }
            .frame(width: side, height: side)
            .background(Palette.board)
            .clipShape(.rect(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.gridBold, lineWidth: 2.5))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func isError(_ i: Int) -> Bool {
        guard !session.isGiven(i), session.values[i] != 0 else { return false }
        return (showMistakes && session.isWrong(i)) || (highlightConflicts && session.hasConflict(i))
    }

    private func background(_ i: Int) -> Color {
        if let hint = session.activeHint {
            if session.hintStage >= 2 && hint.cell == i { return Palette.hintCell }
            if session.hintStage >= 2 && hint.focus.contains(i) { return Palette.hintCell.opacity(0.45) }
            if hint.region.contains(i) { return Palette.hintRegion }
        }
        guard let s = session.selected else { return .clear }
        if s == i { return Palette.selection }
        let v = session.values[s]
        if highlightSame && v != 0 && session.values[i] == v { return Palette.sameDigit }
        if isError(i) { return Palette.errorFill }
        if highlightRelated && (Sudoku.row(i) == Sudoku.row(s) || Sudoku.col(i) == Sudoku.col(s) || Sudoku.box(i) == Sudoku.box(s)) {
            return Palette.related
        }
        return .clear
    }

    private func accessibilityLabel(_ i: Int) -> String {
        var parts = [L("Ligne %1$lld, colonne %2$lld", Sudoku.row(i) + 1, Sudoku.col(i) + 1)]
        let v = session.values[i]
        if v != 0 {
            parts.append(session.isGiven(i) ? L("%lld, donné", Int(v)) : "\(v)")
            if isError(i) { parts.append(L("erreur")) }
        } else {
            parts.append(L("vide"))
            let n = Sudoku.digits(session.notes[i])
            if !n.isEmpty { parts.append(L("notes %@", n.map(String.init).joined(separator: " "))) }
        }
        return parts.joined(separator: ", ")
    }
}

struct CellView: View {
    let value: UInt8
    let notes: UInt16
    let isGiven: Bool
    let isError: Bool
    let background: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            background
            if value != 0 {
                Text("\(value)")
                    .font(.gridDigit(size: size * 0.58, given: isGiven))
                    .foregroundStyle(isError ? Palette.error : (isGiven ? Palette.given : Palette.entry))
                    .contentTransition(.numericText())
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            } else if notes != 0 {
                NotesView(notes: notes, size: size)
            }
        }
        .frame(width: size, height: size)
        .contentShape(.rect)
        .animation(.spring(duration: 0.25), value: value)
    }
}

struct NotesView: View {
    let notes: UInt16
    let size: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { c in
                        let d = UInt8(r * 3 + c + 1)
                        Text(notes & Sudoku.bit(d) != 0 ? "\(d)" : " ")
                            .font(.system(size: size * 0.27, weight: .medium, design: .rounded))
                            .foregroundStyle(Palette.note)
                            .frame(width: size / 3.2, height: size / 3.2)
                    }
                }
            }
        }
    }
}

/// Traits de la grille : fins entre les cases, épais entre les blocs.
struct GridLines: View {
    var body: some View {
        Canvas { ctx, size in
            let step = size.width / 9
            for k in 1..<9 {
                let bold = k % 3 == 0
                var path = Path()
                path.move(to: CGPoint(x: CGFloat(k) * step, y: 0))
                path.addLine(to: CGPoint(x: CGFloat(k) * step, y: size.height))
                path.move(to: CGPoint(x: 0, y: CGFloat(k) * step))
                path.addLine(to: CGPoint(x: size.width, y: CGFloat(k) * step))
                ctx.stroke(path, with: .color(bold ? Palette.gridBold : Palette.gridLine), lineWidth: bold ? 2 : 0.75)
            }
        }
    }
}
