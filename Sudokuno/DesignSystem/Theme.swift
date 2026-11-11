import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
    }
}

extension Color {
    /// Couleur qui s'adapte au mode clair / sombre.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
}

/// Couleurs sémantiques de Sudokuno (clair / sombre).
enum Palette {
    static let background = Color(light: 0xF3F2FA, dark: 0x0F0F17)
    static let card = Color(light: 0xFFFFFF, dark: 0x1B1A27)
    static let board = Color(light: 0xFFFFFF, dark: 0x1B1A27)
    static let gridLine = Color(light: 0xD6D4E6, dark: 0x34334A)
    static let gridBold = Color(light: 0x3A3D9E, dark: 0x7C77E6)
    static let given = Color(light: 0x17172B, dark: 0xEDECFA)
    static let entry = Color(light: 0x4B3FD9, dark: 0xA49DFF)
    static let note = Color(light: 0x6E6C85, dark: 0x9C9AB5)
    static let selection = Color(light: 0xC9C4FF, dark: 0x463F9C)
    static let related = Color(light: 0xEFEDFB, dark: 0x24233A)
    static let sameDigit = Color(light: 0xDDD9FF, dark: 0x343070)
    static let error = Color(light: 0xD93A40, dark: 0xFF6B70)
    static let errorFill = Color(light: 0xFDE3E4, dark: 0x4A1D22)
    static let hintRegion = Color(light: 0xFFF3DC, dark: 0x3A2F17)
    static let hintCell = Color(light: 0xFFD27A, dark: 0x8A6118)
    static let accent = Color(light: 0x4B3FD9, dark: 0xA49DFF)
    /// Fond des boutons pleins : assez foncé pour un texte blanc lisible, même en mode sombre.
    static let accentStrong = Color(light: 0x4B3FD9, dark: 0x5B4FE6)
    static let secondaryText = Color(light: 0x6B6982, dark: 0x9C9AB5)
    static let flameStart = Color(light: 0xFF4D2E, dark: 0xFF5A3C)
    static let flameEnd = Color(light: 0xFFB23F, dark: 0xFFC05A)
    static let freeze = Color(light: 0x2E9BE6, dark: 0x5DB8FF)
    static let success = Color(light: 0x1F9D55, dark: 0x4ADE80)

    static var flame: LinearGradient {
        LinearGradient(colors: [flameEnd, flameStart], startPoint: .top, endPoint: .bottom)
    }
}

extension Font {
    /// Chiffres de la grille : SF Pro Rounded, chasse fixe.
    static func gridDigit(size: CGFloat, given: Bool) -> Font {
        .system(size: size, weight: given ? .semibold : .medium, design: .rounded).monospacedDigit()
    }
}

/// Carte arrondie utilisée sur l'accueil.
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Palette.card, in: .rect(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}

extension String {
    /// « mardi 10 novembre 2026 » → « Mardi 10 novembre 2026 » (seule la première lettre).
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

enum TimeFormat {
    /// 402 → « 6:42 », 3725 → « 1:02:05 »
    static func clock(_ seconds: Int) -> String {
        let h = seconds / 3600, m = (seconds % 3600) / 60, s = seconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}
