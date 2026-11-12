import SwiftUI
import SudokuKit

/// Revoir une partie de l'historique : chaque chiffre posé, effacé ou annulé, dans l'ordre et avec son instant.
struct PlaybackView: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    let entry: HistoryEntry
    private let playback: Playback
    private let moves: [Move]
    private let states: [[UInt8]]
    /// Nombre de coups déjà joués à l'écran (0 = grille de départ). On ouvre sur la grille telle qu'elle a été laissée.
    @State private var index: Int
    @State private var playing = false

    init(entry: HistoryEntry) {
        self.entry = entry
        let playback = entry.review ?? Playback(givens: SudokuKit.Grid(), solution: SudokuKit.Grid(), moves: [])
        self.playback = playback
        moves = playback.decoded
        states = playback.states
        _index = State(initialValue: playback.moves.count)
    }

    private var current: Move? { index > 0 ? moves[index - 1] : nil }
    /// Erreurs de la partie (celles comptées en jeu ; en mode validation, les chiffres faux à la fin).
    private var mistakes: Int { max(entry.mistakes, moves.filter(playback.isMistake).count) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                board
                card
                controls
                actions
            }
            .padding(16)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .background(Palette.background.ignoresSafeArea())
        .navigationTitle(L("Revoir la partie"))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: playing) {
            // Lecture automatique : un coup toutes les 0,6 s.
            while playing && !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(600))
                guard playing, !Task.isCancelled else { return }
                if index < moves.count { withAnimation(.snappy) { index += 1 } }
                if index >= moves.count { playing = false }
            }
        }
    }

    private var board: some View {
        let values = states[index]
        return BoardFrame { i, size in
            let wrong = values[i] != 0 && values[i] != playback.solution[i]
            CellView(value: values[i], notes: 0, isGiven: playback.givens[i] != 0, isError: wrong,
                     background: current?.cell == i ? (wrong ? Palette.errorFill : Palette.selection) : .clear, size: size)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L("Revoir la partie"))
        .accessibilityIdentifier("playbackBoard")
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L("Coup %1$@ sur %2$@", "\(index)", "\(moves.count)"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
                    .monospacedDigit()
                    .accessibilityIdentifier("playbackProgress")
                Spacer()
                if let current {
                    Label(TimeFormat.clock(current.time), systemImage: "timer")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.secondaryText)
                        .monospacedDigit()
                }
            }
            Text(current.map(describe) ?? L("Début de la partie"))
                .font(.headline)
                .foregroundStyle(current.map(playback.isMistake) == true ? Palette.error : .primary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("playbackMove")
            Text(L("%lld erreurs", mistakes))
                .font(.subheadline)
                .foregroundStyle(mistakes == 0 ? Palette.success : Palette.error)
                .accessibilityIdentifier("playbackMistakes")
            if moves.count > 1 {
                Slider(value: Binding(get: { Double(index) }, set: { index = Int($0.rounded()); playing = false }),
                       in: 0...Double(moves.count), step: 1)
                    .tint(Palette.accentStrong)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    playing = false
                    withAnimation(.snappy) { index -= 1 }
                } label: {
                    Label(L("Précédent"), systemImage: "chevron.left").labelStyle(.iconOnly).frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.glass)
                .disabled(index == 0)
                .accessibilityIdentifier("playbackPrevious")
                Button {
                    if index >= moves.count { index = 0 }
                    playing.toggle()
                } label: {
                    Label(playing ? L("Pause") : L("Lecture"), systemImage: playing ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.glassProminent)
                .tint(Palette.accentStrong)
                .disabled(moves.isEmpty)
                .accessibilityIdentifier("playbackPlay")
                Button {
                    playing = false
                    withAnimation(.snappy) { index += 1 }
                } label: {
                    Label(L("Suivant"), systemImage: "chevron.right").labelStyle(.iconOnly).frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.glass)
                .disabled(index >= moves.count)
                .accessibilityIdentifier("playbackNext")
            }
            // Depuis la fin de la partie, on repart de la première erreur.
            if let next = moves.indices.first(where: { $0 >= index && playback.isMistake(moves[$0]) })
                ?? moves.indices.first(where: { playback.isMistake(moves[$0]) }) {
                Button {
                    playing = false
                    withAnimation(.snappy) { index = next + 1 }
                } label: {
                    Label(L("Erreur suivante"), systemImage: "xmark.circle").frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.glass)
                .accessibilityIdentifier("playbackNextMistake")
            }
        }
    }

    /// Résultat de la partie, puis ce qu'on peut faire de cette grille.
    private var actions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(summaryLine)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(entry.isFailed ? Palette.error : Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("playbackSummary")
            if !entry.isAbandoned {
                Button {
                    router.play { await model.replay(entry) }
                } label: {
                    Label(L("Rejouer cette grille"), systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.glass)
            }
            Button {
                // Le bac à sable s'ouvre sur les chiffres de départ de cette grille, pour l'analyser.
                UserDefaults.standard.set(playback.givens.string, forKey: "creatorDraft")
                router.path.append(.creator)
            } label: {
                Label(L("Ouvrir dans le bac à sable"), systemImage: "square.and.pencil").frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(.glass)
            .accessibilityIdentifier("playbackSandbox")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var summaryLine: String {
        var parts = [GameMode.title(entry.mode, code: entry.code, level: entry.level), "⏱ \(TimeFormat.clock(entry.seconds))",
                     L("%lld erreurs", mistakes), ShareContent.hintsText(entry.hints, enabled: entry.hintsEnabled)]
        if entry.isFailed { parts.insert(L("Ratée"), at: 1) }
        if entry.isAbandoned { parts.insert(L("Abandonnée"), at: 1) }
        if let score = entry.score { parts.append(L("%@ pts", score.total.formatted(.number.locale(L10n.locale)))) }
        return parts.joined(separator: " · ")
    }

    private func describe(_ m: Move) -> String {
        let cell = StepText.cell(m.cell)
        switch m.kind {
        case .player:
            if m.digit == 0 { return L("Tu effaces la case %@.", cell) }
            return playback.isMistake(m) ? L("Tu places le %1$@ en %2$@ : ce n'est pas le bon chiffre.", "\(m.digit)", cell)
                                         : L("Tu places le %1$@ en %2$@.", "\(m.digit)", cell)
        case .hint:
            return m.digit == 0 ? L("Indice : la case %@ est effacée.", cell) : L("Indice : le %1$@ en %2$@.", "\(m.digit)", cell)
        case .undo:
            return m.digit == 0 ? L("Annulation : la case %@ redevient vide.", cell) : L("Annulation : la case %1$@ revient au %2$@.", cell, "\(m.digit)")
        }
    }
}
