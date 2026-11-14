import SwiftUI
import SudokuKit

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @AppStorage(SettingKey.theme) private var theme = AppTheme.system.rawValue
    @AppStorage(AppLanguage.storageKey) private var language = AppLanguage.system.rawValue
    @AppStorage(SettingKey.hintsEnabled) private var hintsEnabled = true
    @AppStorage(SettingKey.highlightConflicts) private var highlightConflicts = true
    @AppStorage(SettingKey.highlightSameDigits) private var highlightSame = true
    @AppStorage(SettingKey.highlightRelated) private var highlightRelated = true
    @AppStorage(SettingKey.autoRemoveNotes) private var autoRemoveNotes = true
    @AppStorage(SettingKey.showMistakes) private var showMistakes = true
    @AppStorage(SettingKey.showTimer) private var showTimer = true
    @AppStorage(SettingKey.showScore) private var showScore = true
    @AppStorage(SettingKey.haptics) private var haptics = true
    @AppStorage(SettingKey.hardMode) private var hardMode = false
    @AppStorage(SettingKey.bigScreen) private var bigScreen = false
    @AppStorage(SettingKey.reminderEnabled) private var reminderEnabled = false
    @AppStorage(SettingKey.reminderMinutes) private var reminderMinutes = 20 * 60
    @State private var confirmReset = false

    /// Site hébergé sur GitHub Pages (dossier `site/` du dépôt).
    static let siteURL = URL(string: "https://zerrino.github.io/sudokuno/")!
    static let privacyURL = URL(string: "https://zerrino.github.io/sudokuno/privacy.html")!
    static let legalURL = URL(string: "https://zerrino.github.io/sudokuno/legal.html")!

    var body: some View {
        Form {
            Section(L("Apparence")) {
                Picker(L("Thème"), selection: $theme) {
                    ForEach(AppTheme.allCases) { Text($0.label).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Picker(L("Langue"), selection: Binding(get: { language }, set: { new in
                    // Charger les traductions AVANT que l'interface se reconstruise.
                    L10n.apply(AppLanguage(rawValue: new) ?? .system)
                    language = new
                })) {
                    ForEach(AppLanguage.allCases) { Text($0.nativeName).tag($0.rawValue) }
                }
            } header: {
                Text(L("Langue"))
            } footer: {
                Text(L("Change la langue de Sudokuno sans modifier celle de ton iPhone."))
            }

            Section {
                Toggle(L("Indices (3 par grille)"), isOn: $hintsEnabled)
            } header: {
                Text(L("Indices"))
            } footer: {
                Text(L("Le nombre d'indices utilisés apparaît à la fin de la partie et dans les messages partagés. Tu peux changer ce réglage en cours de partie, tant qu'aucun indice n'y a été utilisé."))
            }

            Section {
                Toggle(L("Mode difficile"), isOn: $hardMode)
                    .accessibilityIdentifier("hardModeToggle")
            } header: {
                Text(L("Erreurs"))
            } footer: {
                Text(L("Erreurs tolérées avant qu'une grille soit ratée : 5 en Facile, 3 en Moyen, 1 en Difficile et Expert. En mode difficile, comme toujours en Diabolique et en Légende, aucune erreur n'est signalée : tu valides ta grille une fois remplie, et elle est juste ou ratée. S'applique aux nouvelles parties."))
            }

            Section(L("Aides")) {
                Toggle(L("Afficher les erreurs"), isOn: $showMistakes)
                Toggle(L("Surligner les conflits"), isOn: $highlightConflicts)
                Toggle(L("Surligner les chiffres identiques"), isOn: $highlightSame)
                Toggle(L("Surligner ligne, colonne et bloc"), isOn: $highlightRelated)
                Toggle(L("Effacer les notes automatiquement"), isOn: $autoRemoveNotes)
            }

            Section {
                Toggle(L("Grand écran"), isOn: $bigScreen)
                    .accessibilityIdentifier("bigScreenToggle")
                Toggle(L("Afficher le chrono"), isOn: $showTimer)
                Toggle(L("Afficher le score en jouant"), isOn: $showScore)
                    .accessibilityIdentifier("showScoreToggle")
                Toggle(L("Vibrations"), isOn: $haptics)
            } header: {
                Text(L("Jeu"))
            } footer: {
                Text(L("Le score n'apparaît jamais en mode validation : il trahirait les erreurs."))
            }

            Section {
                Toggle(L("Rappel de série"), isOn: $reminderEnabled)
                    .onChange(of: reminderEnabled) { _, on in
                        Task {
                            if on, !(await ReminderScheduler.requestAuthorization()) { reminderEnabled = false }
                            reschedule()
                        }
                    }
                if reminderEnabled {
                    DatePicker(L("Heure"), selection: reminderTime, displayedComponents: .hourAndMinute)
                }
            } header: {
                Text(L("Notifications"))
            } footer: {
                Text(L("Une notification locale si le Sudoku du jour n'est pas encore fait. Rien n'est envoyé sur Internet."))
            }

            Section(L("Game Center")) {
                if model.gameCenter.isAuthenticated {
                    LabeledContent(L("Connecté"), value: model.gameCenter.playerName ?? "")
                    Button(L("Ouvrir Game Center")) { model.gameCenter.showDashboard() }
                    Button(L("Succès")) { model.gameCenter.showAchievements() }
                } else {
                    Text(L("Non connecté. Connecte-toi dans Réglages › Game Center pour apparaître dans les classements."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            TipJarSection()

            Section(L("À propos")) {
                LabeledContent(L("Version"), value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                Link(L("Aide et contact"), destination: Self.siteURL)
                Link(L("Politique de confidentialité"), destination: Self.privacyURL)
                Link(L("Mentions légales"), destination: Self.legalURL)
                Text(L("Sudokuno est gratuit, sans publicité et sans suivi. Les seuls achats sont des dons facultatifs. Tes données restent sur ton appareil."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button(L("Réinitialiser les statistiques"), role: .destructive) { confirmReset = true }
            }
        }
        .navigationTitle(L("Réglages"))
        .confirmationDialog(L("Tout réinitialiser ?"), isPresented: $confirmReset, titleVisibility: .visible) {
            Button(L("Réinitialiser"), role: .destructive) { model.resetStatistics() }
        } message: {
            Text(L("Série, statistiques, niveaux débloqués et parties en cours seront effacés."))
        }
        .onChange(of: reminderMinutes) { _, _ in reschedule() }
    }

    private var reminderTime: Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: reminderMinutes / 60, minute: reminderMinutes % 60, second: 0, of: .now) ?? .now
        } set: { date in
            let c = Calendar.current.dateComponents([.hour, .minute], from: date)
            reminderMinutes = (c.hour ?? 20) * 60 + (c.minute ?? 0)
        }
    }

    private func reschedule() {
        ReminderScheduler.reschedule(streak: model.state.streak.current,
                                     doneToday: model.state.streak.isCompleted(model.today))
    }
}
