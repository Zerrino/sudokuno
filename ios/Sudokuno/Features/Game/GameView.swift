import SwiftUI
import SudokuKit

struct GameView: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var session: GameSession

    @AppStorage(SettingKey.showTimer) private var showTimer = true
    @AppStorage(SettingKey.showScore) private var showScore = true
    @AppStorage(SettingKey.showMistakes) private var showMistakes = true
    @AppStorage(SettingKey.hintsEnabled) private var hintsSetting = true
    @AppStorage(SettingKey.bigScreen) private var bigScreen = false
    @State private var summary: CompletionSummary?
    /// Grille ratée : l'écran d'échec est affiché (on peut le fermer pour regarder ses erreurs).
    @State private var showFailure = false
    @State private var codeCopied = false
    @State private var confirmAbandon = false

    private var timerRunning: Bool { scenePhase == .active && !session.isOver }

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
                            validateButton
                            ControlsView(session: session, big: bigScreen)
                            NumberPad(session: session, layout: .grid, big: bigScreen)
                                .frame(maxWidth: 360)
                        }
                        .frame(width: min(400, geo.size.width * 0.38))
                    }
                    .padding(bigScreen ? 10 : 24)
                } else {
                    VStack(spacing: 14) {
                        header
                        infoRow
                        Spacer(minLength: 0)
                        BoardView(session: session)
                        hintBanner
                        Spacer(minLength: 0)
                        validateButton
                        ControlsView(session: session, big: bigScreen)
                        NumberPad(session: session, layout: .row, big: bigScreen)
                    }
                    // Grand écran : la grille va d'un bord à l'autre, sans largeur maximale.
                    .padding(.horizontal, bigScreen ? 4 : 16)
                    .padding(.vertical, bigScreen ? 4 : 8)
                    .frame(maxWidth: bigScreen ? .infinity : (geo.size.width > 700 ? 820 : 640))
                    .frame(maxWidth: .infinity)
                }

                if let summary {
                    CompletionView(summary: summary, givens: session.puzzle.givens)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                if showFailure {
                    FailureView(session: session) { withAnimation { showFailure = false } }
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
            case .failed:
                Haptics.error()
                model.fail(session)
                withAnimation(.spring(duration: 0.5)) { showFailure = true }
            case nil:
                break
            }
        }
        .onDisappear { model.save(session) }
        // Le réglage des indices s'applique tout de suite à la partie, sauf si un indice y a déjà servi.
        .onAppear { session.syncHints(hintsSetting) }
        .onChange(of: hintsSetting) { _, on in session.syncHints(on) }
    }

    /// Mode validation : quand la grille est pleine, c'est au joueur de la faire vérifier.
    @ViewBuilder
    private var validateButton: some View {
        if session.canValidate {
            Button {
                withAnimation(.snappy) { session.validate() }
            } label: {
                Label(L("Valider la grille"), systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 46)
            }
            .buttonStyle(.glassProminent)
            .tint(Palette.accentStrong)
            .accessibilityIdentifier("validateButton")
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else if session.isFailed && !showFailure {
            Button {
                withAnimation { showFailure = true }
            } label: {
                Label(L("Grille ratée"), systemImage: "xmark.octagon.fill").frame(maxWidth: .infinity, minHeight: 46)
            }
            .buttonStyle(.glass)
            .tint(Palette.error)
            .accessibilityIdentifier("failureReopen")
        }
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
                HStack(spacing: 10) {
                    if showTimer {
                        Text(TimeFormat.clock(session.elapsed))
                            .font(.subheadline.weight(.medium))
                            .monospacedDigit()
                            .foregroundStyle(Palette.secondaryText)
                            .contentTransition(.numericText())
                    }
                    if showScore, !session.strict, let score = session.liveScore {
                        LiveScoreLabel(score: score, gain: session.lastGain)
                    }
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
                if !session.isOver {
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
            if session.strict && !session.isFailed {
                // Mode validation : aucun compteur, rien n'est signalé avant la fin.
                Label(L("Validation à la fin"), systemImage: "checkmark.shield")
                    .foregroundStyle(Palette.secondaryText)
                    .accessibilityIdentifier("strictMode")
            } else if showMistakes || session.mistakeLimit != nil || session.isFailed {
                // Erreurs commises, et le maximum toléré à ce niveau.
                Label(session.mistakeLimit.map { "\(session.mistakes)/\($0)" } ?? "\(session.mistakes)", systemImage: "xmark.circle")
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
    /// Mode grand écran : boutons plus hauts.
    var big = false

    var body: some View {
        HStack(spacing: 10) {
            control(L("Effacer"), "eraser", id: "eraseButton", enabled: !session.isOver) { session.erase() }
                .keyboardShortcut(.delete, modifiers: [])
            control(session.notesMode ? L("Notes : oui") : L("Notes"), session.notesMode ? "pencil.circle.fill" : "pencil", id: "notesButton",
                    enabled: !session.isOver, active: session.notesMode) {
                session.notesMode.toggle()
            }
            .keyboardShortcut("n", modifiers: [])
            if session.hintsEnabled {
                control(L("Indice"), "lightbulb", id: "hintButton", enabled: (session.hintsRemaining > 0 || session.activeHint != nil) && !session.isOver,
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
                Text(title).font((big ? Font.subheadline : .caption).weight(.medium))
            }
            .frame(maxWidth: .infinity, minHeight: big ? 64 : 50)
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
    /// Mode grand écran : touches plus grandes.
    var big = false

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
                    .font(.system(size: (layout == .grid ? 34 : 28) + (big ? 6 : 0), weight: session.notesMode ? .regular : .semibold, design: .rounded))
                    .foregroundStyle(session.notesMode ? Palette.note : Palette.entry)
                if !done {
                    Text("\(9 - session.placedCount(d))")
                        .font(.caption2)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, minHeight: (layout == .grid ? 72 : 58) + (big ? 14 : 0))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .background(Palette.card, in: .rect(cornerRadius: 12, style: .continuous))
        .opacity(done ? 0.3 : 1)
        .disabled(done || session.isOver)
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

/// Score en direct, avec les points du dernier chiffre (« +30 ») qui apparaissent un instant.
private struct LiveScoreLabel: View {
    let score: Int
    let gain: GameSession.Gain?
    @State private var shown: GameSession.Gain?

    var body: some View {
        HStack(spacing: 4) {
            Text(L("%@ pts", score.formatted(.number.locale(L10n.locale))))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(Palette.accent)
                .contentTransition(.numericText())
                .animation(.snappy, value: score)
                .accessibilityIdentifier("liveScore")
            if let shown {
                Text(shown.lucky ? L("+%@ (chance)", "\(shown.points)") : "+\(shown.points)")
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(shown.lucky ? Palette.secondaryText : Palette.success)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task(id: gain?.nonce) {
            guard let gain else { return }
            withAnimation(.snappy) { shown = gain }
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut) { shown = nil }
        }
    }
}
