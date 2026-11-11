import SwiftUI
import SudokuKit

struct EnterCodeView: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @State private var text = ""
    @State private var link: ShareContent.Link?
    @FocusState private var fieldFocused: Bool

    var body: some View {
        Form {
            Section {
                TextField("SKN1-D-XXXX-XXXX-XXXX-XX", text: $text, axis: .vertical)
                    .font(.body.monospaced())
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused($fieldFocused)
                    .onChange(of: text) { _, new in link = ShareContent.parse(text: new) }
                PasteButton(payloadType: String.self) { strings in
                    if let s = strings.first {
                        Task { @MainActor in text = s }
                    }
                }
            } header: {
                Text(L("Code de la grille"))
            } footer: {
                Text(L("Colle le message reçu ou tape le code. On retrouve exactement la même grille, et le défi s'il y en a un."))
            }

            if let link {
                Section(L("Grille trouvée")) {
                    LabeledContent(L("Code"), value: link.code.string)
                    if case .custom(let grid) = link.code {
                        let analysis = PuzzleAnalysis.analyze(grid)
                        if let legend = Legends.find(grid) {
                            LabeledContent(L("Légende"), value: legend.name)
                        } else if case .unique(let level, _, _) = analysis.status {
                            LabeledContent(L("Grille créée par un joueur"), value: level.name)
                        } else {
                            Label(L("Cette grille n'a pas de solution unique."), systemImage: "exclamationmark.triangle")
                                .foregroundStyle(Palette.error)
                        }
                    } else if let level = link.code.level {
                        LabeledContent(L("Niveau"), value: level.name)
                    } else if case .daily(let day) = link.code {
                        LabeledContent(L("Sudoku du jour"), value: day.date.formatted(Date.FormatStyle(date: .long, time: .omitted, locale: L10n.locale, timeZone: .gmt)))
                    }
                    if let c = link.challenge {
                        LabeledContent(L("Défi"), value: "\(TimeFormat.clock(c.seconds)) · \(ShareContent.hintsText(c.hints, enabled: true))")
                    }
                    Button {
                        let l = link
                        router.play { await model.sharedGame(code: l.code, challenge: l.challenge) }
                    } label: {
                        Label(link.challenge == nil ? L("Jouer") : L("Relever le défi"), systemImage: "play.fill")
                            .font(.headline)
                    }
                    .disabled(isFutureDaily(link.code) || !PuzzleAnalysis.isPlayable(link.code))
                }
            } else if !text.isEmpty {
                Section {
                    Label(L("Code invalide. Vérifie qu'il commence par SKN1."), systemImage: "exclamationmark.triangle")
                        .foregroundStyle(Palette.error)
                }
            }
        }
        .navigationTitle(L("Entrer un code"))
        .onAppear { fieldFocused = true }
    }

    private func isFutureDaily(_ code: PuzzleCode) -> Bool {
        if case .daily(let day) = code { return day > model.today }
        return false
    }
}
