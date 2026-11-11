import SwiftUI
import SudokuKit

/// Messages et liens de partage. Tout passe par le code de la grille : aucun serveur.
enum ShareContent {
    struct Link: Hashable {
        var code: PuzzleCode
        var challenge: Challenge?
    }

    /// sudokuno://p/SKN1-D-XXXX-XXXX-XXXX-XX?t=402&h=1
    static func url(code: PuzzleCode, challenge: Challenge?) -> URL {
        var comps = URLComponents()
        comps.scheme = "sudokuno"
        comps.host = "p"
        comps.path = "/" + code.string
        if let challenge {
            comps.queryItems = [URLQueryItem(name: "t", value: String(challenge.seconds)),
                                URLQueryItem(name: "h", value: String(challenge.hints))]
        }
        return comps.url!
    }

    static func parse(url: URL) -> Link? {
        guard url.scheme == "sudokuno", url.host == "p",
              let code = PuzzleCode(string: url.lastPathComponent) else { return nil }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let t = items.first { $0.name == "t" }?.value.flatMap(Int.init)
        let h = items.first { $0.name == "h" }?.value.flatMap(Int.init)
        return Link(code: code, challenge: t.map { Challenge(seconds: $0, hints: h ?? 0) })
    }

    /// Lit un message partagé collé : le code, et le défi s'il y en a un.
    static func parse(text: String) -> Link? {
        guard let code = PuzzleCode.find(in: text) else { return nil }
        var challenge: Challenge?
        if let match = text.firstMatch(of: /t=(\d+)&h=(\d+)/), let t = Int(match.1), let h = Int(match.2) {
            challenge = Challenge(seconds: t, hints: h)
        }
        return Link(code: code, challenge: challenge)
    }

    static func hintsText(_ hints: Int, enabled: Bool) -> String {
        if !enabled { return L("🚫 sans aide") }
        return hints == 0 ? L("💡 sans indice") : L("💡 %lld indices", hints)
    }

    /// Message envoyé après une victoire (ne dévoile rien de la grille).
    static func resultMessage(_ s: CompletionSummary, streak: Int) -> String {
        let label = s.code.isDaily ? L("Sudoku du jour · %@", s.level.name) : s.level.name
        let flame = s.countsForDaily && streak > 0 ? " 🔥\(streak)" : ""
        let link = url(code: s.code, challenge: Challenge(seconds: s.seconds, hints: s.hints))
        return "Sudokuno · \(label)\(flame)\n"
            + "⏱ \(TimeFormat.clock(s.seconds)) · \(hintsText(s.hints, enabled: s.hintsEnabled))\n"
            + L("À toi de battre mon temps ! Code : %@", s.code.string) + "\n"
            + link.absoluteString
    }

    /// Invitation à jouer une grille (sans résultat).
    static func inviteMessage(code: PuzzleCode, level: Level) -> String {
        L("Essaie cette grille Sudokuno (%@) !", level.name) + "\n"
            + L("Code : %@", code.string) + "\n"
            + url(code: code, challenge: nil).absoluteString
    }
}

/// Carte image partagée avec le message.
struct ShareCardView: View {
    let summary: CompletionSummary
    let streak: Int

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(L("Sudokuno")).font(.title2.weight(.heavy))
                Spacer()
                if summary.countsForDaily && streak > 0 {
                    Label("\(streak)", systemImage: "flame.fill")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Palette.flameStart)
                }
            }
            Text(summary.code.isDaily ? L("Sudoku du jour") : L("Défi %@", summary.level.name))
                .font(.headline)
                .foregroundStyle(summary.level.tint)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 24) {
                stat(TimeFormat.clock(summary.seconds), L("temps"))
                stat(summary.hintsEnabled ? "\(summary.hints)" : "–", L("indices"))
                stat("\(summary.mistakes)", L("erreurs"))
            }
            MiniGridPattern()
                .frame(height: 90)
            Text(summary.code.string)
                .font(.footnote.monospaced().weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 340)
        .background(Palette.card)
        .environment(\.colorScheme, .light)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title.weight(.bold)).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Motif décoratif (aucune information sur la grille réelle).
struct MiniGridPattern: View {
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<9, id: \.self) { k in
                RoundedRectangle(cornerRadius: 6)
                    .fill(k == 4 ? AnyShapeStyle(Palette.flame) : AnyShapeStyle(Palette.accent.opacity(k % 2 == 0 ? 0.35 : 0.18)))
            }
        }
    }
}
