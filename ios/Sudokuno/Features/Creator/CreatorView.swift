import SwiftUI
import SudokuKit

/// Créer sa propre grille : analyse en direct (jouable ou non, difficulté), puis partage par code.
struct CreatorView: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @AppStorage("creatorDraft") private var draft = String(repeating: ".", count: 81)

    @State private var grid = Grid()
    @State private var selected: Int? = 0
    @State private var analysis: PuzzleAnalysis?
    @State private var analyzing = false
    @State private var confirmClear = false
    @State private var codeCopied = false
    @State private var loaded = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                board
                pad
                analysisCard
                if let analysis, case .unique(let level, _, _) = analysis.status {
                    shareCard(level: level)
                }
            }
            .padding(16)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .background(Palette.background.ignoresSafeArea())
        .navigationTitle(L("Créer une grille"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L("Tout effacer"), role: .destructive) { confirmClear = true }
                    .disabled(grid.clueCount == 0)
            }
        }
        .confirmationDialog(L("Effacer toute la grille ?"), isPresented: $confirmClear, titleVisibility: .visible) {
            Button(L("Tout effacer"), role: .destructive) { grid = Grid(); selected = 0 }
        }
        .alert(L("Code copié"), isPresented: $codeCopied) {
            Button(L("OK"), role: .cancel) {}
        }
        .onAppear {
            guard !loaded else { return }
            loaded = true
            grid = Grid(string: draft) ?? Grid()
        }
        .task(id: grid) {
            draft = grid.string
            analyzing = true
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            let g = grid
            let result = await Task.detached(priority: .userInitiated) { PuzzleAnalysis.analyze(g) }.value
            guard !Task.isCancelled else { return }
            analysis = result
            analyzing = false
        }
    }

    // MARK: - Grille

    private var conflictCells: Set<Int> {
        if case .conflict(let cells) = analysis?.status { return Set(cells) }
        return []
    }

    private var board: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = side / 9
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { r in
                        HStack(spacing: 0) {
                            ForEach(0..<9, id: \.self) { c in
                                let i = r * 9 + c
                                CellView(value: grid[i], notes: 0, isGiven: true, isError: conflictCells.contains(i),
                                         background: background(i), size: cell)
                                    .onTapGesture { selected = i; Haptics.tap() }
                                    .accessibilityElement()
                                    .accessibilityLabel(L("Ligne %1$lld, colonne %2$lld", r + 1, c + 1) + ", "
                                                        + (grid[i] == 0 ? L("vide") : "\(grid[i])"))
                                    .accessibilityAddTraits(selected == i ? [.isButton, .isSelected] : .isButton)
                                    .accessibilityIdentifier("create-\(i)")
                            }
                        }
                    }
                }
                GridLines().allowsHitTesting(false)
            }
            .frame(width: side, height: side)
            .background(Palette.board)
            .clipShape(.rect(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.gridBold, lineWidth: 2.5))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func background(_ i: Int) -> Color {
        if selected == i { return Palette.selection }
        if conflictCells.contains(i) { return Palette.errorFill }
        if let s = selected, grid[s] != 0, grid[i] == grid[s] { return Palette.sameDigit }
        if let s = selected, Sudoku.row(i) == Sudoku.row(s) || Sudoku.col(i) == Sudoku.col(s) || Sudoku.box(i) == Sudoku.box(s) {
            return Palette.related
        }
        return .clear
    }

    private var pad: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(1...9, id: \.self) { d in
                    Button {
                        guard let i = selected else { return }
                        grid[i] = grid[i] == UInt8(d) ? 0 : UInt8(d)
                        Haptics.tap()
                    } label: {
                        Text("\(d)")
                            .font(.system(size: 26, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.entry)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .background(Palette.card, in: .rect(cornerRadius: 12, style: .continuous))
                    .accessibilityIdentifier("createKey-\(d)")
                }
            }
            Button {
                if let i = selected { grid[i] = 0 }
            } label: {
                Label(L("Effacer"), systemImage: "eraser")
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(.glass)
        }
    }

    // MARK: - Analyse

    private var analysisCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(L("Analyse"), systemImage: "checklist").font(.headline)
                Spacer()
                Text(L("%lld chiffres", grid.clueCount))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
                    .monospacedDigit()
            }
            if analyzing && analysis == nil {
                ProgressView()
            } else if let analysis {
                status(analysis)
            }
            if grid.clueCount < 17 {
                Text(L("Il faut au moins 17 chiffres pour qu'une grille ait une solution unique."))
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    @ViewBuilder
    private func status(_ a: PuzzleAnalysis) -> some View {
        switch a.status {
        case .conflict:
            statusLine(L("Conflit : un chiffre apparaît deux fois dans une ligne, une colonne ou un bloc."),
                       "exclamationmark.triangle.fill", Palette.error)
        case .noSolution:
            statusLine(L("Aucune solution : cette grille est impossible. Retire ou change un chiffre."),
                       "xmark.octagon.fill", Palette.error)
        case .undetermined:
            statusLine(L("Pas encore assez de chiffres pour conclure. Continue à remplir."),
                       "hourglass", Palette.secondaryText)
        case .multipleSolutions(let suggestion):
            VStack(alignment: .leading, spacing: 8) {
                statusLine(L("Plusieurs solutions possibles : ajoute des chiffres pour qu'il n'y en ait qu'une."),
                           "arrow.triangle.branch", Palette.flameEnd)
                Button {
                    grid[suggestion.cell] = suggestion.digit
                    selected = suggestion.cell
                    Haptics.tap()
                } label: {
                    Label(L("Ajouter un chiffre suggéré"), systemImage: "wand.and.stars")
                }
                .buttonStyle(.glass)
                .accessibilityIdentifier("addSuggestion")
            }
        case .unique(let level, let hardest, _):
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    statusLine(L("Grille valide : solution unique"), "checkmark.seal.fill", Palette.success)
                        .accessibilityIdentifier("validPuzzle")
                    Spacer()
                    LevelPill(level: level)
                }
                Text(hardest.map { L("Technique la plus difficile : %@", $0.name) }
                     ?? L("Demande des techniques au-delà des classiques."))
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
            }
        }
    }

    private func statusLine(_ text: String, _ symbol: String, _ color: Color) -> some View {
        Label(text, systemImage: symbol)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Partage

    private func shareCard(level: Level) -> some View {
        let code = PuzzleCode.custom(grid)
        return VStack(alignment: .leading, spacing: 12) {
            Label(L("Code de ta grille"), systemImage: "number").font(.headline)
            Text(code.string)
                .font(.footnote.monospaced().weight(.semibold))
                .textSelection(.enabled)
                .accessibilityIdentifier("customCode")
            HStack(spacing: 10) {
                ShareLink(item: ShareContent.inviteMessage(code: code, level: level)) {
                    Label(L("Partager"), systemImage: "square.and.arrow.up").frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.glassProminent)
                .tint(Palette.accentStrong)
                .simultaneousGesture(TapGesture().onEnded { model.recordCreated(code) })
                Button {
                    model.recordCreated(code)
                    UIPasteboard.general.string = code.string
                    codeCopied = true
                } label: {
                    Label(L("Copier"), systemImage: "doc.on.doc").frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.glass)
            }
            Button {
                model.recordCreated(code)
                router.play { await model.sharedGame(code: code, challenge: nil) }
            } label: {
                Label(L("Jouer cette grille"), systemImage: "play.fill").frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(.glass)
            .accessibilityIdentifier("playCustom")
            Text(L("Le code contient toute ta grille : tes amis retrouvent exactement la même, même hors ligne."))
                .font(.caption)
                .foregroundStyle(Palette.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}
