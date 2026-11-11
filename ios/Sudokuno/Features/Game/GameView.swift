import SwiftUI
import SudokuKit

struct GameView: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var session: GameSession

    @AppStorage(SettingKey.showTimer) private var showTimer = true
    @AppStorage(SettingKey.showMistakes) private var showMistakes = true
    @State private var summary: CompletionSummary?
    @State private var codeCopied = false
    @State private var confirmAbandon = false

    private var timerRunning: Bool { scenePhase == .active && !session.isComplete }

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height && geo.size.width > 700
            ZStack {
                Palette.background.ignoresSafeArea()
                if wide {
                    HStack(spacing: 28) {
                        BoardView(session: session)
                            .frame(maxHeight: .infinity)
                        VStack(spacing: 18) {
                            header
                            infoRow
                            hintBanner
                            Spacer(minLength: 0)
                            ControlsView(session: session)
                            NumberPad(session: session, layout: .grid)
                                .frame(maxWidth: 360)
                        }
                        .frame(width: min(400, geo.size.width * 0.38))
                    }
                    .padding(24)
                } else {
                    VStack(spacing: 14) {
                        header
                        infoRow
                        Spacer(minLength: 0)
                        BoardView(session: session)
                        hintBanner
                        Spacer(minLength: 0)
                        ControlsView(session: session)
                        NumberPad(session: session, layout: .row)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(maxWidth: geo.size.width > 700 ? 820 : 640)
                    .frame(maxWidth: .infinity)
                }

                if let summary {
                    CompletionView(summary: summary)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
        .background { ArrowKeyShortcuts(session: session) }
        .task(id: timerRunning) {
            guard timerRunning else { return }
            var ticks = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { break }
                session.tick()
                ticks += 1
                if ticks % 10 == 0 { model.save(session) }
            }
        }
        .onChange(of: session.lastEvent) { _, event in
            switch event {
            case .placed(_, let correct, let units, _):
                if !correct { Haptics.error() } else if units > 0 { Haptics.unit() } else { Haptics.tap() }
            case .completed:
                Haptics.success()
                withAnimation(.spring(duration: 0.5)) { summary = model.complete(session) }
            case nil:
                break
            }
        }
        .onDisappear { model.save(session) }
    }

    // MARK: - En-tête

    private var header: some View {
        HStack {
            Button {
                model.save(session)
                router.activeGame = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel(L("Fermer"))
            .accessibilityIdentifier("closeGame")

            Spacer()
            VStack(spacing: 2) {
                Text(title).font(.headline)
                if showTimer {
                    Text(TimeFormat.clock(session.elapsed))
                        .font(.subheadline.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(Palette.secondaryText)
                        .contentTransition(.numericText())
                }
            }
            Spacer()

            Menu {
                Button {
                    UIPasteboard.general.string = session.puzzle.code.string
                    codeCopied = true
                } label: {
                    Label(L("Copier le code %@", session.puzzle.code.string), systemImage: "doc.on.doc")
                }
                ShareLink(item: ShareContent.inviteMessage(code: session.puzzle.code, level: session.puzzle.level)) {
                    Label(L("Partager cette grille"), systemImage: "square.and.arrow.up")
                }
                if !session.isComplete {
                    Divider()
                    Button(role: .destructive) {
                        confirmAbandon = true
                    } label: {
                        Label(L("Abandonner la partie"), systemImage: "flag")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel(L("Plus d'options"))
        }
        .confirmationDialog(L("Abandonner cette partie ?"), isPresented: $confirmAbandon, titleVisibility: .visible) {
            Button(L("Abandonner"), role: .destructive) {
                model.abandon(session)
                router.activeGame = nil
            }
            Button(L("Annuler"), role: .cancel) {}
        } message: {
            Text(L("Elle sera rangée dans l'historique avec les parties terminées. Tu pourras la reprendre à tout moment."))
        }
        .alert(L("Code copié"), isPresented: $codeCopied) {
            Button(L("OK"), role: .cancel) {}
        } message: {
            Text(session.puzzle.code.string)
        }
    }

    private var title: String {
        GameMode.title(session.mode, code: session.puzzle.code, level: session.puzzle.level)
    }

    private var infoRow: some View {
        HStack(spacing: 14) {
            if showMistakes {
                Label("\(session.mistakes)", systemImage: "xmark.circle")
                    .foregroundStyle(session.mistakes > 0 ? Palette.error : Palette.secondaryText)
                    .accessibilityLabel(L("%lld erreurs", session.mistakes))
                    .accessibilityIdentifier("mistakes")
            }
            if session.hintsEnabled {
                Label("\(session.hintsUsed)/\(GameSession.maxHints)", systemImage: "lightbulb")
                    .foregroundStyle(Palette.secondaryText)
                    .accessibilityLabel(L("%1$lld indices utilisés sur %2$lld", session.hintsUsed, GameSession.maxHints))
            } else {
                Label(L("Sans aide"), systemImage: "lightbulb.slash")
                    .foregroundStyle(Palette.secondaryText)
            }
            Spacer()
            if let challenge = session.mode.challenge {
                Label(L("Battre %1$@ · 💡%2$lld", TimeFormat.clock(challenge.seconds), challenge.hints), systemImage: "flag.checkered")
                    .foregroundStyle(session.elapsed < challenge.seconds ? Palette.accent : Palette.error)
                    .monospacedDigit()
            }
        }
        .font(.subheadline.weight(.semibold))
        .labelStyle(.titleAndIcon)
    }

    @ViewBuilder
    private var hintBanner: some View {
        if let hint = session.activeHint {
            HintBanner(hint: hint, stage: session.hintStage) {
                withAnimation(.snappy) { session.advanceHint() }
            } onClose: {
                withAnimation(.snappy) { session.clearHint() }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Clavier physique (iPad)
}

/// Flèches d'un clavier physique pour déplacer la sélection (boutons invisibles).
/// Les raccourcis SwiftUI ne prennent pas le focus de saisie : pas de clavier virtuel qui s'ouvre.
struct ArrowKeyShortcuts: View {
    let session: GameSession

    var body: some View {
        ZStack {
            shortcut(.upArrow) { session.moveSelection(dRow: -1, dCol: 0) }
            shortcut(.downArrow) { session.moveSelection(dRow: 1, dCol: 0) }
            shortcut(.leftArrow) { session.moveSelection(dRow: 0, dCol: -1) }
            shortcut(.rightArrow) { session.moveSelection(dRow: 0, dCol: 1) }
            shortcut(.deleteForward) { session.erase() }
        }
        .frame(width: 0, height: 0)
        .opacity(0)
        .accessibilityHidden(true)
    }

    private func shortcut(_ key: KeyEquivalent, action: @escaping () -> Void) -> some View {
        Button("", action: action).keyboardShortcut(key, modifiers: [])
    }
}

// MARK: - Contrôles

struct ControlsView: View {
    @Bindable var session: GameSession

    var body: some View {
        HStack(spacing: 10) {
            control(L("Annuler"), "arrow.uturn.backward", id: "undoButton", enabled: session.canUndo) { session.undo() }
                .keyboardShortcut("z", modifiers: .command)
            control(L("Effacer"), "eraser", id: "eraseButton", enabled: !session.isComplete) { session.erase() }
                .keyboardShortcut(.delete, modifiers: [])
            control(session.notesMode ? L("Notes : oui") : L("Notes"), session.notesMode ? "pencil.circle.fill" : "pencil", id: "notesButton",
                    enabled: !session.isComplete, active: session.notesMode) {
                session.notesMode.toggle()
            }
            .keyboardShortcut("n", modifiers: [])
            if session.hintsEnabled {
                control(L("Indice"), "lightbulb", id: "hintButton", enabled: (session.hintsRemaining > 0 || session.activeHint != nil) && !session.isComplete,
                        badge: session.hintsRemaining) {
                    withAnimation(.snappy) { session.advanceHint() }
                }
                .keyboardShortcut("h", modifiers: [])
            }
        }
    }

    private func control(_ title: String, _ symbol: String, id: String, enabled: Bool, active: Bool = false, badge: Int? = nil,
                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.title3)
                    .overlay(alignment: .topTrailing) {
                        if let badge {
                            Text("\(badge)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(minWidth: 16, minHeight: 16)
                                .background(badge > 0 ? Palette.accent : .gray, in: .circle)
                                .offset(x: 12, y: -8)
                        }
                    }
                Text(title).font(.caption.weight(.medium))
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(active ? Palette.accent : .primary)
        }
        .buttonStyle(.glass)
        .disabled(!enabled)
        .accessibilityIdentifier(id)
    }
}

struct NumberPad: View {
    enum Layout { case row, grid }
    @Bindable var session: GameSession
    let layout: Layout

    var body: some View {
        switch layout {
        case .row:
            HStack(spacing: 6) {
                ForEach(1...9, id: \.self) { key(UInt8($0)) }
            }
        case .grid:
            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                ForEach(0..<3, id: \.self) { r in
                    GridRow { ForEach(1...3, id: \.self) { key(UInt8(r * 3 + $0)) } }
                }
            }
        }
    }

    private func key(_ d: UInt8) -> some View {
        let done = session.placedCount(d) >= 9
        return Button {
            session.input(d)
        } label: {
            VStack(spacing: 0) {
                Text("\(d)")
                    .font(.system(size: layout == .grid ? 34 : 28, weight: session.notesMode ? .regular : .semibold, design: .rounded))
                    .foregroundStyle(session.notesMode ? Palette.note : Palette.entry)
                if !done {
                    Text("\(9 - session.placedCount(d))")
                        .font(.caption2)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, minHeight: layout == .grid ? 72 : 58)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .background(Palette.card, in: .rect(cornerRadius: 12, style: .continuous))
        .opacity(done ? 0.3 : 1)
        .disabled(done || session.isComplete)
        .keyboardShortcut(KeyEquivalent(Character("\(d)")), modifiers: [])
        .accessibilityLabel(session.notesMode ? L("Note %lld", Int(d)) : "\(d)")
        .accessibilityIdentifier("key-\(d)")
    }
}

// MARK: - Indice

struct HintBanner: View {
    let hint: Hint
    let stage: Int
    let onNext: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: hint.kind == .mistake ? "exclamationmark.triangle.fill" : "lightbulb.fill")
                .font(.title3)
                .foregroundStyle(hint.kind == .mistake ? Palette.error : Palette.flameEnd)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.bold))
                Text(message).font(.subheadline).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button(stage >= 2 ? (hint.kind == .mistake ? L("Effacer l'erreur") : L("Révéler le chiffre")) : L("Montrer la case"),
                       action: onNext)
                    .font(.subheadline.weight(.semibold))
                    .accessibilityIdentifier("hintNext")
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark").font(.caption.weight(.bold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel(L("Fermer l'indice"))
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    private var title: String {
        switch hint.kind {
        case .mistake: L("Il y a une erreur")
        case .revelation: L("Coup difficile")
        case .placement: hint.technique?.name ?? L("Indice")
        }
    }

    private var message: String {
        switch hint.kind {
        case .mistake:
            return stage >= 2 ? L("Ce chiffre ne correspond pas à la solution.") : L("Un des chiffres de ce bloc est faux.")
        case .revelation:
            return stage >= 2 ? L("Cette case est la plus contrainte de la grille.")
                : L("Aucune technique classique ne s'applique ici. Regarde ce bloc.")
        case .placement:
            if stage >= 2 { return detail }
            var text = L("Regarde %@.", regionName)
            if let s = hint.supportingTechnique { text += " " + L("Pense d'abord à éliminer des candidats (%@).", s.name) }
            return text
        }
    }

    private var detail: String {
        switch hint.technique {
        case .nakedSingle: L("Dans cette case, un seul chiffre est encore possible. Lequel ?")
        case .hiddenSingle: L("Dans %@, un des chiffres manquants ne peut aller que dans cette case. Lequel ?", regionName)
        default: L("Cette case n'a plus qu'une possibilité.")
        }
    }

    private var regionName: String {
        let cells = Set(hint.region)
        for u in 0..<27 where Set(Sudoku.units[u]) == cells {
            switch Sudoku.unitName(u) {
            case .row(let r): return L("la ligne %lld", r + 1)
            case .column(let c): return L("la colonne %lld", c + 1)
            case .box(let b): return L("le bloc %lld", b + 1)
            }
        }
        return L("cette zone")
    }
}
