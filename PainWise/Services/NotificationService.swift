import Foundation
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            print("Notification authorization failed: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Schedule Daily Reminders

    func scheduleMorningReminder(at time: DateComponents) async {
        await cancelNotification(identifier: "morning_reminder")

        let content = UNMutableNotificationContent()
        content.title = L10n.notificationMorningTitle
        content.body = L10n.notificationMorningBody
        content.sound = .default
        content.badge = 1

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(identifier: "morning_reminder", content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
            print("Morning reminder scheduled")
        } catch {
            print("Failed to schedule morning reminder: \(error)")
        }
    }

    func scheduleEveningReminder(at time: DateComponents) async {
        await cancelNotification(identifier: "evening_reminder")

        let content = UNMutableNotificationContent()
        content.title = L10n.notificationEveningTitle
        content.body = L10n.notificationEveningBody
        content.sound = .default
        content.badge = 1

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(identifier: "evening_reminder", content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
            print("Evening reminder scheduled")
        } catch {
            print("Failed to schedule evening reminder: \(error)")
        }
    }

    // MARK: - Weather Alert Notification

    func scheduleWeatherAlert(pressureChange: Double, date: Date) async {
        guard abs(pressureChange) > 5 else { return }

        let content = UNMutableNotificationContent()
        content.title = pressureChange < 0 ? L10n.notificationWeatherPressureDropTitle : L10n.notificationWeatherPressureRiseTitle
        content.body = pressureChange < 0 ? L10n.notificationWeatherPressureDropBody : L10n.notificationWeatherPressureRiseBody
        content.sound = .default
        content.categoryIdentifier = "WEATHER_ALERT"

        // Schedule for 8 PM the day before
        var triggerDate = Calendar.current.dateComponents([.year, .month, .day], from: date)
        triggerDate.hour = 20
        triggerDate.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let identifier = "weather_alert_\(date.timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
            print("Weather alert scheduled")
        } catch {
            print("Failed to schedule weather alert: \(error)")
        }
    }

    // MARK: - Pain Tracking Reminder

    func scheduleTrackingReminder(afterHours hours: Int = 4) async {
        let content = UNMutableNotificationContent()
        content.title = L10n.notificationTrackingTitle
        content.body = L10n.notificationTrackingBody
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(hours * 3600), repeats: false)
        let request = UNNotificationRequest(identifier: "tracking_reminder", content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
            print("Tracking reminder scheduled for \(hours) hours")
        } catch {
            print("Failed to schedule tracking reminder: \(error)")
        }
    }

    // MARK: - Cancel Notifications

    func cancelNotification(identifier: String) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    func cancelDailyReminders() async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [
            "morning_reminder",
            "evening_reminder"
        ])
    }

    // MARK: - Get Pending Notifications

    func fetchPendingNotifications() async {
        pendingNotifications = await notificationCenter.pendingNotificationRequests()
    }

    // MARK: - Setup Notification Categories

    func setupNotificationCategories() {
        // Weather alert category with actions
        let viewAction = UNNotificationAction(
            identifier: "VIEW_FORECAST",
            title: L10n.notificationActionViewForecast,
            options: [.foreground]
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: L10n.notificationActionDismiss,
            options: [.destructive]
        )

        let weatherAlertCategory = UNNotificationCategory(
            identifier: "WEATHER_ALERT",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        // Record reminder category
        let recordAction = UNNotificationAction(
            identifier: "QUICK_RECORD",
            title: L10n.notificationActionRecordNow,
            options: [.foreground]
        )

        let laterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: L10n.notificationActionRemindLater,
            options: []
        )

        let recordCategory = UNNotificationCategory(
            identifier: "RECORD_REMINDER",
            actions: [recordAction, laterAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([weatherAlertCategory, recordCategory])
    }

    // MARK: - Configure from Settings

    func configureFromSettings(
        morningEnabled: Bool,
        morningTime: Date,
        eveningEnabled: Bool,
        eveningTime: Date
    ) async {
        // Cancel existing daily reminders
        await cancelDailyReminders()

        // Schedule new reminders if enabled
        if morningEnabled {
            let morningComponents = Calendar.current.dateComponents([.hour, .minute], from: morningTime)
            await scheduleMorningReminder(at: morningComponents)
        }

        if eveningEnabled {
            let eveningComponents = Calendar.current.dateComponents([.hour, .minute], from: eveningTime)
            await scheduleEveningReminder(at: eveningComponents)
        }
    }
}
