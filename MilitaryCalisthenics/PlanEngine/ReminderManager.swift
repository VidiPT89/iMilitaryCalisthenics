import Foundation
import UserNotifications

@Observable
final class ReminderManager {
    static let shared = ReminderManager()

    /// Set when the user declines the system notification permission prompt,
    /// so the UI can explain why the toggle reverted instead of failing silently.
    var permissionDenied = false

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "reminders.enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "reminders.enabled") }
    }

    var hour: Int {
        get { UserDefaults.standard.object(forKey: "reminders.hour") as? Int ?? 18 }
        set { UserDefaults.standard.set(newValue, forKey: "reminders.hour") }
    }

    var minute: Int {
        get { UserDefaults.standard.object(forKey: "reminders.minute") as? Int ?? 0 }
        set { UserDefaults.standard.set(newValue, forKey: "reminders.minute") }
    }

    private static let weekdaySpread: [Int: [Int]] = [
        3: [2, 4, 6],
        4: [2, 3, 5, 6],
        5: [2, 3, 4, 5, 6],
        6: [2, 3, 4, 5, 6, 7],
    ]

    func requestAuthorizationAndSchedule(daysPerWeek: Int) async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            permissionDenied = !granted
            guard granted else { return false }
            await reschedule(daysPerWeek: daysPerWeek)
            return true
        } catch {
            permissionDenied = true
            return false
        }
    }

    func reschedule(daysPerWeek: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: (1...7).map { "workout-reminder-\($0)" })
        guard isEnabled else { return }

        let weekdays = Self.weekdaySpread[max(3, min(6, daysPerWeek))] ?? [2, 4, 6]
        for weekday in weekdays {
            let content = UNMutableNotificationContent()
            content.title = t("app.name")
            content.body = t("reminders.body")
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.weekday = weekday
            dateComponents.hour = hour
            dateComponents.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "workout-reminder-\(weekday)", content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    func disable() {
        isEnabled = false
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: (1...7).map { "workout-reminder-\($0)" })
    }
}
