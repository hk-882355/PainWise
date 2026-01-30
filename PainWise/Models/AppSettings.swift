import Foundation
import SwiftData

@Model
final class AppSettings {
    var id: UUID

    // Notification Settings
    var morningNotificationEnabled: Bool
    var morningNotificationTime: Date
    var afternoonNotificationEnabled: Bool
    var afternoonNotificationTime: Date
    var eveningNotificationEnabled: Bool
    var eveningNotificationTime: Date

    // HealthKit Settings
    var sleepDataEnabled: Bool
    var stepCountEnabled: Bool
    var heartRateEnabled: Bool
    var locationEnabled: Bool

    // Cloud Sync
    var cloudSyncEnabled: Bool
    var lastSyncDate: Date?

    // User Profile
    var userName: String

    init(
        id: UUID = UUID(),
        morningNotificationEnabled: Bool = true,
        morningNotificationTime: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date(),
        afternoonNotificationEnabled: Bool = false,
        afternoonNotificationTime: Date = Calendar.current.date(from: DateComponents(hour: 13, minute: 0)) ?? Date(),
        eveningNotificationEnabled: Bool = true,
        eveningNotificationTime: Date = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date(),
        sleepDataEnabled: Bool = true,
        stepCountEnabled: Bool = true,
        heartRateEnabled: Bool = false,
        locationEnabled: Bool = true,
        cloudSyncEnabled: Bool = true,
        lastSyncDate: Date? = nil,
        userName: String = ""
    ) {
        self.id = id
        self.morningNotificationEnabled = morningNotificationEnabled
        self.morningNotificationTime = morningNotificationTime
        self.afternoonNotificationEnabled = afternoonNotificationEnabled
        self.afternoonNotificationTime = afternoonNotificationTime
        self.eveningNotificationEnabled = eveningNotificationEnabled
        self.eveningNotificationTime = eveningNotificationTime
        self.sleepDataEnabled = sleepDataEnabled
        self.stepCountEnabled = stepCountEnabled
        self.heartRateEnabled = heartRateEnabled
        self.locationEnabled = locationEnabled
        self.cloudSyncEnabled = cloudSyncEnabled
        self.lastSyncDate = lastSyncDate
        self.userName = userName
    }
}
