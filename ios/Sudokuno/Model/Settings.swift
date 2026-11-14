import SwiftUI
import SudokuKit

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: L("Système")
        case .light: L("Clair")
        case .dark: L("Sombre")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Clés des réglages (@AppStorage / UserDefaults).
enum SettingKey {
    static let theme = "theme"
    static let hintsEnabled = "hintsEnabled"
    static let highlightConflicts = "highlightConflicts"
    static let highlightSameDigits = "highlightSameDigits"
    static let highlightRelated = "highlightRelated"
    static let autoRemoveNotes = "autoRemoveNotes"
    static let showMistakes = "showMistakes"
    static let showTimer = "showTimer"
    static let haptics = "haptics"
    static let reminderEnabled = "reminderEnabled"
    static let reminderMinutes = "reminderMinutes"
    /// Mode difficile : aucune erreur signalée, la grille se valide une fois remplie (à tous les niveaux).
    static let hardMode = "hardMode"
    /// Grand écran : la grille et les touches prennent le plus de place possible.
    static let bigScreen = "bigScreen"
    /// Score en direct pendant la partie (jamais en mode validation).
    static let showScore = "showScore"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            theme: AppTheme.system.rawValue,
            hintsEnabled: true,
            highlightConflicts: true,
            highlightSameDigits: true,
            highlightRelated: true,
            autoRemoveNotes: true,
            showMistakes: true,
            showTimer: true,
            haptics: true,
            reminderEnabled: false,
            reminderMinutes: 20 * 60,
            hardMode: false,
            bigScreen: false,
            showScore: true,
        ])
    }

    static func bool(_ key: String) -> Bool { UserDefaults.standard.bool(forKey: key) }
}

extension Level {
    var name: String {
        switch self {
        case .facile: L("Facile")
        case .moyen: L("Moyen")
        case .difficile: L("Difficile")
        case .expert: L("Expert")
        case .diabolique: L("Diabolique")
        case .legende: L("Légende")
        }
    }

    var summary: String {
        switch self {
        case .facile: L("Singletons : idéal pour démarrer")
        case .moyen: L("Paires et interactions bloc-ligne")
        case .difficile: L("Triplets et X-Wing")
        case .expert: "Swordfish, XY-Wing, XYZ-Wing"
        case .diabolique: L("Chaînes : X-Chain, XY-Chain, AIC")
        case .legende: L("Les grilles les plus dures du monde")
        }
    }

    var symbol: String {
        switch self {
        case .facile: "leaf.fill"
        case .moyen: "flame"
        case .difficile: "bolt.fill"
        case .expert: "crown.fill"
        case .diabolique: "theatermasks.fill"
        case .legende: "star.fill"
        }
    }

    var tint: Color {
        switch self {
        case .facile: Color(light: 0x1F9D55, dark: 0x4ADE80)
        case .moyen: Color(light: 0x2E9BE6, dark: 0x5DB8FF)
        case .difficile: Color(light: 0x7B5CF0, dark: 0xA996FF)
        case .expert: Color(light: 0xE08A00, dark: 0xFFB23F)
        case .diabolique: Color(light: 0xD93A40, dark: 0xFF6B70)
        case .legende: Color(light: 0xB0249A, dark: 0xF472D0)
        }
    }
}

extension Technique {
    var name: String {
        switch self {
        case .nakedSingle: L("Singleton nu")
        case .hiddenSingle: L("Singleton caché")
        case .pointing: L("Pointage")
        case .boxLineReduction: L("Réduction bloc-ligne")
        case .nakedPair: L("Paire nue")
        case .hiddenPair: L("Paire cachée")
        case .nakedTriple: L("Triplet nu")
        case .hiddenTriple: L("Triplet caché")
        case .xWing: "X-Wing"
        case .xyWing: "XY-Wing"
        case .swordfish: "Swordfish"
        case .xyzWing: "XYZ-Wing"
        case .turbotFish: "Turbot Fish"
        case .xChain: "X-Chain"
        case .xyChain: "XY-Chain"
        case .aic: L("Chaîne d'inférences (AIC)")
        case .forcingChain: L("Chaîne forcée")
        case .forcingNet: L("Réseau forcé")
        case .skLoop: "SK-Loop"
        case .groupedChain: L("Chaîne groupée")
        }
    }
}
