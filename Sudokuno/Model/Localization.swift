import Foundation

/// Langues proposées dans les réglages. `system` suit la langue de l'appareil.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case fr
    case en
    case nl
    case pt = "pt-PT"
    case zh = "zh-Hans"

    var id: String { rawValue }

    /// Nom de la langue dans cette langue (comme dans les Réglages d'iOS).
    var nativeName: String {
        switch self {
        case .system: L("Langue de l'appareil")
        case .fr: "Français"
        case .en: "English"
        case .nl: "Nederlands"
        case .pt: "Português"
        case .zh: "简体中文"
        }
    }

    static let storageKey = "appLanguage"
}

/// Traductions de l'app. On lit le dossier .lproj de la langue choisie, ce qui permet de changer de langue
/// dans l'app sans la relancer. Les textes source sont en français (Localizable.xcstrings).
enum L10n {
    private(set) static var bundle: Bundle = .main
    private(set) static var locale = Locale(identifier: "fr")
    private(set) static var code = "fr"

    static func apply(_ language: AppLanguage) {
        let available = Bundle.main.localizations.filter { $0 != "Base" }
        let resolved: String
        if language == .system {
            resolved = Bundle.preferredLocalizations(from: available, forPreferences: Locale.preferredLanguages).first ?? "fr"
        } else {
            resolved = language.rawValue
        }
        code = resolved
        locale = Locale(identifier: resolved)
        if let path = Bundle.main.path(forResource: resolved, ofType: "lproj"), let b = Bundle(path: path) {
            bundle = b
        } else {
            bundle = .main
        }
    }

    static func applyStored() {
        let raw = UserDefaults.standard.string(forKey: AppLanguage.storageKey) ?? AppLanguage.system.rawValue
        apply(AppLanguage(rawValue: raw) ?? .system)
    }
}

/// Texte traduit.
func L(_ key: String) -> String {
    L10n.bundle.localizedString(forKey: key, value: key, table: nil)
}

/// Texte traduit avec paramètres (et règles de pluriel du catalogue).
func L(_ key: String, _ args: any CVarArg...) -> String {
    String(format: L(key), locale: L10n.locale, arguments: args)
}
