import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext

    // Services
    private let healthKitService = HealthKitService.shared
    private let weatherService = WeatherService.shared
    @ObservedObject private var notificationService = NotificationService.shared

    // Notification Settings
    @AppStorage("morningNotificationEnabled") private var morningNotificationEnabled = true
    @AppStorage("morningNotificationMinutes") private var morningNotificationMinutes = 8 * 60
    @State private var morningTime = Date()
    @AppStorage("afternoonNotificationEnabled") private var afternoonNotificationEnabled = false
    @AppStorage("afternoonNotificationMinutes") private var afternoonNotificationMinutes = 13 * 60
    @State private var afternoonTime = Date()
    @AppStorage("eveningNotificationEnabled") private var eveningNotificationEnabled = true
    @AppStorage("eveningNotificationMinutes") private var eveningNotificationMinutes = 21 * 60
    @State private var eveningTime = Date()

    // Time Picker Sheet
    @State private var showMorningTimePicker = false
    @State private var showAfternoonTimePicker = false
    @State private var showEveningTimePicker = false

    // Alert
    @State private var showNotificationAlert = false

    // HealthKit Settings
    @AppStorage("sleepDataEnabled") private var sleepDataEnabled = true
    @AppStorage("stepCountEnabled") private var stepCountEnabled = true
    @AppStorage("heartRateEnabled") private var heartRateEnabled = false
    @AppStorage("locationEnabled") private var locationEnabled = true
    @State private var isRequestingHealthKit = false

    // Cloud Sync
    @AppStorage("cloudSyncEnabled") private var cloudSyncEnabled = false
    @State private var lastSyncText = L10n.settingsJustNow

    // Profile
    @State private var showProfile = false

    // Premium
    @State private var showPremium = false
    @ObservedObject private var storeKit = StoreKitManager.shared

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
                    Text("PainWise v\(Self.appVersionString)")
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
            .onAppear {
                syncStoredTimes()
            }
            .onChange(of: morningTime) { _, newValue in
                morningNotificationMinutes = minutesFromTime(newValue)
            }
            .onChange(of: afternoonTime) { _, newValue in
                afternoonNotificationMinutes = minutesFromTime(newValue)
            }
            .onChange(of: eveningTime) { _, newValue in
                eveningNotificationMinutes = minutesFromTime(newValue)
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
                    components = Calendar.current.dateComponents([.hour, .minute], from: afternoonTime)
                    await notificationService.scheduleAfternoonReminder(at: components)
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
                    await notificationService.cancelNotification(identifier: "afternoon_reminder")
                case .evening:
                    await notificationService.cancelNotification(identifier: "evening_reminder")
                }
            }
        }
    }

    // MARK: - HealthKit Section
    private var healthKitSection: some View {
        let healthKitLocked = !storeKit.isPremium
        return VStack(alignment: .leading, spacing: 8) {
            sectionHeader(L10n.settingsDataIntegration)

            if healthKitLocked {
                PremiumGateCard(
                    title: "HealthKit連携はプレミアム",
                    message: "睡眠・歩数・心拍数を自動取得できます。",
                    buttonTitle: "プレミアムを見る",
                    onUpgrade: { showPremium = true }
                )
            }

            VStack(spacing: 0) {
                HealthKitRow(
                    icon: "bed.double.fill",
                    iconColor: .indigo,
                    title: L10n.settingsSleepData,
                    isEnabled: $sleepDataEnabled,
                    isLocked: healthKitLocked,
                    onToggle: { enabled in
                        if enabled { requestHealthKitAuthorization() }
                    },
                    onLockedTap: { showPremium = true }
                )

                Divider()
                    .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.1))

                HealthKitRow(
                    icon: "figure.walk",
                    iconColor: .green,
                    title: L10n.settingsStepCount,
                    isEnabled: $stepCountEnabled,
                    isLocked: healthKitLocked,
                    onToggle: { enabled in
                        if enabled { requestHealthKitAuthorization() }
                    },
                    onLockedTap: { showPremium = true }
                )

                Divider()
                    .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.1))

                HealthKitRow(
                    icon: "heart.fill",
                    iconColor: .red,
                    title: L10n.settingsHeartRate,
                    isEnabled: $heartRateEnabled,
                    isLocked: healthKitLocked,
                    onToggle: { enabled in
                        if enabled { requestHealthKitAuthorization() }
                    },
                    onLockedTap: { showPremium = true }
                )

                Divider()
                    .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.1))

                HealthKitRow(
                    icon: "location.fill",
                    iconColor: .teal,
                    title: L10n.settingsLocationWeather,
                    isEnabled: $locationEnabled,
                    isLocked: false,
                    onToggle: { enabled in
                        if enabled { requestLocationAuthorization() }
                    },
                    onLockedTap: nil
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
                #if DEBUG
                print("HealthKit authorization failed: \(error)")
                #endif
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
                HStack(spacing: 8) {
                    Text(String(localized: "settings_cloud_sync_coming_soon"))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Capsule())

                    Toggle("", isOn: $cloudSyncEnabled)
                        .labelsHidden()
                        .tint(Color.appPrimary)
                        .disabled(true)
                }
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

    private static let appVersionString: String = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (Build \(build))"
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private func timeString(from date: Date) -> String {
        Self.timeFormatter.string(from: date)
    }

    private func syncStoredTimes() {
        morningTime = timeFromMinutes(morningNotificationMinutes)
        afternoonTime = timeFromMinutes(afternoonNotificationMinutes)
        eveningTime = timeFromMinutes(eveningNotificationMinutes)
    }

    private func timeFromMinutes(_ minutes: Int) -> Date {
        let normalized = (minutes % (24 * 60) + (24 * 60)) % (24 * 60)
        let hour = normalized / 60
        let minute = normalized % 60
        return Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
    }

    private func minutesFromTime(_ date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
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
    let isLocked: Bool
    var onToggle: ((Bool) -> Void)?
    var onLockedTap: (() -> Void)?

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

            if isLocked {
                PremiumBadge(text: "Premium")
            } else {
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                    .tint(Color.appPrimary)
                    .onChange(of: isEnabled) { _, newValue in
                        onToggle?(newValue)
                    }
            }
        }
        .padding(16)
        .contentShape(Rectangle())
        .onTapGesture {
            if isLocked {
                onLockedTap?()
            }
        }
    }
}

// MARK: - Premium Components
struct PremiumGateCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let message: String
    let buttonTitle: String
    let onUpgrade: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Color.appPrimary)
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: onUpgrade) {
                Text(buttonTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.appPrimary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
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

struct PremiumBadge: View {
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.caption2)
            Text(text)
                .font(.caption2)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.appPrimary.opacity(0.12))
        .foregroundStyle(Color.appPrimary)
        .clipShape(Capsule())
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
