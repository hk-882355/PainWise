import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext

    // Services
    private let healthKitService = HealthKitService.shared
    private let weatherService = WeatherService.shared
    @StateObject private var notificationService = NotificationService.shared

    // Notification Settings
    @State private var morningNotificationEnabled = true
    @State private var morningTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var afternoonNotificationEnabled = false
    @State private var afternoonTime = Calendar.current.date(from: DateComponents(hour: 13, minute: 0)) ?? Date()
    @State private var eveningNotificationEnabled = true
    @State private var eveningTime = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()

    // Time Picker Sheet
    @State private var showMorningTimePicker = false
    @State private var showAfternoonTimePicker = false
    @State private var showEveningTimePicker = false

    // Alert
    @State private var showNotificationAlert = false

    // HealthKit Settings
    @State private var sleepDataEnabled = true
    @State private var stepCountEnabled = true
    @State private var heartRateEnabled = false
    @State private var locationEnabled = true
    @State private var isRequestingHealthKit = false

    // Cloud Sync
    @State private var cloudSyncEnabled = true
    @State private var lastSyncText = L10n.settingsJustNow

    // Profile
    @State private var showProfile = false

    // Premium
    @State private var showPremium = false
    @StateObject private var storeKit = StoreKitManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Premium Section
                    premiumSection

                    // Notification Settings
                    notificationSection

                    // HealthKit Settings
                    healthKitSection

                    // Account & Sync
                    accountSection

                    // Version
                    Text("PainWise v1.0.0 (Build 1)")
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .sheet(isPresented: $showPremium) {
                PremiumView()
            }
            .background(colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(L10n.settingsTitle)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Profile Button
                    Button {
                        showProfile = true
                    } label: {
                        Circle()
                            .fill(Color.surfaceHighlight)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.appPrimary)
                            )
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
        }
    }

    // MARK: - Premium Section
    private var premiumSection: some View {
        Button {
            showPremium = true
        } label: {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appPrimary.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Image(systemName: "crown.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(storeKit.isPremium ? L10n.settingsPremiumTitle : L10n.settingsPremiumUpgrade)
                            .font(.headline)
                            .fontWeight(.bold)

                        if !storeKit.isPremium {
                            Text(L10n.settingsPremiumRecommended)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.appPrimary)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }

                    Text(storeKit.isPremium ? L10n.settingsPremiumUnlocked : L10n.settingsPremiumFeatures)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if storeKit.isPremium {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.appPrimary)
                        .font(.title2)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        storeKit.isPremium ? Color.appPrimary.opacity(0.3) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Notification Section
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(L10n.settingsNotifications)

            VStack(spacing: 0) {
                NotificationRow(
                    icon: "sun.max.fill",
                    iconColor: .orange,
                    title: L10n.settingsMorningNotification,
                    subtitle: L10n.settingsMorningSubtitle,
                    time: timeString(from: morningTime),
                    isEnabled: $morningNotificationEnabled,
                    onToggle: { enabled in
                        handleNotificationToggle(type: .morning, enabled: enabled)
                    },
                    onTimeTap: { showMorningTimePicker = true }
                )

                Divider()
                    .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.1))

                NotificationRow(
                    icon: "cloud.sun.fill",
                    iconColor: .blue,
                    title: L10n.settingsAfternoonNotification,
                    subtitle: nil,
                    time: timeString(from: afternoonTime),
                    isEnabled: $afternoonNotificationEnabled,
                    onToggle: { enabled in
                        handleNotificationToggle(type: .afternoon, enabled: enabled)
                    },
                    onTimeTap: { showAfternoonTimePicker = true }
                )

                Divider()
                    .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.1))

                NotificationRow(
                    icon: "moon.fill",
                    iconColor: .purple,
                    title: L10n.settingsEveningNotification,
                    subtitle: nil,
                    time: timeString(from: eveningTime),
                    isEnabled: $eveningNotificationEnabled,
                    onToggle: { enabled in
                        handleNotificationToggle(type: .evening, enabled: enabled)
                    },
                    onTimeTap: { showEveningTimePicker = true }
                )
            }
            .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .alert(L10n.settingsNotificationPermissionTitle, isPresented: $showNotificationAlert) {
            Button(L10n.settingsOpenSettings) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(L10n.commonCancel, role: .cancel) {}
        } message: {
            Text(L10n.settingsNotificationPermissionMessage)
        }
        .sheet(isPresented: $showMorningTimePicker) {
            TimePickerSheet(
                title: L10n.settingsMorningNotification,
                time: $morningTime,
                onSave: {
                    if morningNotificationEnabled {
                        handleNotificationToggle(type: .morning, enabled: true)
                    }
                }
            )
            .presentationDetents([.height(300)])
        }
        .sheet(isPresented: $showAfternoonTimePicker) {
            TimePickerSheet(
                title: L10n.settingsAfternoonNotification,
                time: $afternoonTime,
                onSave: {
                    if afternoonNotificationEnabled {
                        handleNotificationToggle(type: .afternoon, enabled: true)
                    }
                }
            )
            .presentationDetents([.height(300)])
        }
        .sheet(isPresented: $showEveningTimePicker) {
            TimePickerSheet(
                title: L10n.settingsEveningNotification,
                time: $eveningTime,
                onSave: {
                    if eveningNotificationEnabled {
                        handleNotificationToggle(type: .evening, enabled: true)
                    }
                }
            )
            .presentationDetents([.height(300)])
        }
        .task {
            notificationService.setupNotificationCategories()
            await notificationService.checkAuthorizationStatus()
        }
    }

    private enum NotificationType {
        case morning, afternoon, evening
    }

    private func handleNotificationToggle(type: NotificationType, enabled: Bool) {
        Task {
            if enabled {
                // Request authorization if not already authorized
                if !notificationService.isAuthorized {
                    let granted = await notificationService.requestAuthorization()
                    if !granted {
                        showNotificationAlert = true
                        // Revert toggle
                        await MainActor.run {
                            switch type {
                            case .morning: morningNotificationEnabled = false
                            case .afternoon: afternoonNotificationEnabled = false
                            case .evening: eveningNotificationEnabled = false
                            }
                        }
                        return
                    }
                }

                // Schedule notification
                let components: DateComponents
                switch type {
                case .morning:
                    components = Calendar.current.dateComponents([.hour, .minute], from: morningTime)
                    await notificationService.scheduleMorningReminder(at: components)
                case .afternoon:
                    // Use tracking reminder for afternoon
                    await notificationService.scheduleTrackingReminder(afterHours: 4)
                case .evening:
                    components = Calendar.current.dateComponents([.hour, .minute], from: eveningTime)
                    await notificationService.scheduleEveningReminder(at: components)
                }
            } else {
                // Cancel notification
                switch type {
                case .morning:
                    await notificationService.cancelNotification(identifier: "morning_reminder")
                case .afternoon:
                    await notificationService.cancelNotification(identifier: "tracking_reminder")
                case .evening:
                    await notificationService.cancelNotification(identifier: "evening_reminder")
                }
            }
        }
    }

    // MARK: - HealthKit Section
    private var healthKitSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(L10n.settingsDataIntegration)

            VStack(spacing: 0) {
                HealthKitRow(
                    icon: "bed.double.fill",
                    iconColor: .indigo,
                    title: L10n.settingsSleepData,
                    isEnabled: $sleepDataEnabled,
                    onToggle: { enabled in
                        if enabled { requestHealthKitAuthorization() }
                    }
                )

                Divider()
                    .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.1))

                HealthKitRow(
                    icon: "figure.walk",
                    iconColor: .green,
                    title: L10n.settingsStepCount,
                    isEnabled: $stepCountEnabled,
                    onToggle: { enabled in
                        if enabled { requestHealthKitAuthorization() }
                    }
                )

                Divider()
                    .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.1))

                HealthKitRow(
                    icon: "heart.fill",
                    iconColor: .red,
                    title: L10n.settingsHeartRate,
                    isEnabled: $heartRateEnabled,
                    onToggle: { enabled in
                        if enabled { requestHealthKitAuthorization() }
                    }
                )

                Divider()
                    .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.1))

                HealthKitRow(
                    icon: "location.fill",
                    iconColor: .teal,
                    title: L10n.settingsLocationWeather,
                    isEnabled: $locationEnabled,
                    onToggle: { enabled in
                        if enabled { requestLocationAuthorization() }
                    }
                )
            }
            .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }

    // MARK: - Authorization Requests
    private func requestHealthKitAuthorization() {
        guard !isRequestingHealthKit else { return }
        isRequestingHealthKit = true

        Task {
            do {
                try await healthKitService.requestAuthorization()
            } catch {
                print("HealthKit authorization failed: \(error)")
            }
            isRequestingHealthKit = false
        }
    }

    private func requestLocationAuthorization() {
        weatherService.requestLocationAuthorization()
    }

    // MARK: - Account Section
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(L10n.settingsAccountSync)

            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.cyan.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: "arrow.triangle.2.circlepath.icloud.fill")
                        .foregroundStyle(Color.cyan)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.settingsCloudSync)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(L10n.settingsLastSync(lastSyncText))
                        .font(.caption)
                        .foregroundStyle(Color.appPrimary)
                }

                Spacer()

                // Toggle
                Toggle("", isOn: $cloudSyncEnabled)
                    .labelsHidden()
                    .tint(Color.appPrimary)
            }
            .padding(16)
            .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }

    // MARK: - Helpers
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(Color.gray)
            .textCase(.uppercase)
            .tracking(1)
            .padding(.leading, 8)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let time: String
    @Binding var isEnabled: Bool
    var onToggle: ((Bool) -> Void)?
    var onTimeTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                }
            }

            Spacer()

            // Time Badge (tappable)
            Button {
                onTimeTap?()
            } label: {
                Text(time)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.appPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.appPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)

            // Toggle
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(Color.appPrimary)
                .onChange(of: isEnabled) { _, newValue in
                    onToggle?(newValue)
                }
        }
        .padding(16)
    }
}

// MARK: - Time Picker Sheet
struct TimePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    let title: String
    @Binding var time: Date
    var onSave: (() -> Void)?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                DatePicker(
                    "",
                    selection: $time,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Button {
                    onSave?()
                    dismiss()
                } label: {
                    Text(String(localized: "common_save"))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.appPrimary)
                        .foregroundStyle(Color.backgroundDark)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.commonCancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - HealthKit Row
struct HealthKitRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isEnabled: Bool
    var onToggle: ((Bool) -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }

            // Title
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            // Toggle
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(Color.appPrimary)
                .onChange(of: isEnabled) { _, newValue in
                    onToggle?(newValue)
                }
        }
        .padding(16)
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
