import SudokuKit
import UIKit
import UserNotifications

/// Retours haptiques (désactivables dans les réglages).
enum Haptics {
    static func tap() {
        guard SettingKey.bool(SettingKey.haptics) else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func error() {
        guard SettingKey.bool(SettingKey.haptics) else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func success() {
        guard SettingKey.bool(SettingKey.haptics) else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func unit() {
        guard SettingKey.bool(SettingKey.haptics) else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.8)
    }
}

/// Rappel local de la série (aucune donnée ne quitte l'appareil).
enum ReminderScheduler {
    static let prefix = "sudokuno.reminder."

    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Replanifie les 7 prochains rappels. Pas de rappel aujourd'hui si la grille du jour est faite.
    static func reschedule(streak: Int, doneToday: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: (0..<8).map { prefix + String($0) })
        guard SettingKey.bool(SettingKey.reminderEnabled) else { return }

        let minutes = UserDefaults.standard.integer(forKey: SettingKey.reminderMinutes)
        let cal = Calendar.current
        let now = Date()
        for offset in 0..<8 {
            guard let day = cal.date(byAdding: .day, value: offset, to: now),
                  let fire = cal.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day),
                  fire > now
            else { continue }
            if offset == 0 && doneToday { continue }

            let content = UNMutableNotificationContent()
            content.title = "Sudokuno"
            content.body = streak > 0
                ? L("Ta série de %lld jours t'attend 🔥 Le Sudoku du jour est prêt.", streak)
                : L("Le Sudoku du jour est prêt. Lance ta série 🔥")
            content.sound = .default
            let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            let request = UNNotificationRequest(identifier: prefix + String(offset), content: content,
                                                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
            center.add(request)
        }
    }
}
