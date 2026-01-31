import SwiftUI

struct OnboardingView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("userName") private var userName: String = ""

    @State private var currentPage = 0
    @State private var inputName = ""
    @State private var notificationsEnabled = false
    @State private var healthKitEnabled = false
    @State private var showHealthKitUnavailableAlert = false

    private let notificationService = NotificationService.shared
    private let healthKitService = HealthKitService.shared

    var body: some View {
        ZStack {
            // Background
            (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index == currentPage ? Color.appPrimary : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 60)

                // Content
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    profilePage.tag(1)
                    permissionsPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Navigation Buttons
                navigationButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
            .alert(String(localized: "healthkit_unavailable_title"), isPresented: $showHealthKitUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(String(localized: "healthkit_unavailable_message"))
            }
        }
    }

    // MARK: - Welcome Page
    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.appPrimary)
            }

            VStack(spacing: 16) {
                Text(String(localized: "onboarding_welcome_title"))
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(String(localized: "onboarding_welcome_description"))
                    .font(.body)
                    .foregroundStyle(Color.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Profile Page
    private var profilePage: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "person.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.blue)
            }

            VStack(spacing: 16) {
                Text(String(localized: "onboarding_profile_title"))
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                TextField(String(localized: "onboarding_profile_placeholder"), text: $inputName)
                    .textFieldStyle(.plain)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 48)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Permissions Page
    private var permissionsPage: some View {
        VStack(spacing: 24) {
            Spacer()

            // Notification Permission
            permissionCard(
                icon: "bell.fill",
                iconColor: .orange,
                title: String(localized: "onboarding_notifications_title"),
                description: String(localized: "onboarding_notifications_description"),
                isEnabled: $notificationsEnabled,
                action: requestNotifications
            )

            // HealthKit Permission
            permissionCard(
                icon: "heart.fill",
                iconColor: .red,
                title: String(localized: "onboarding_health_title"),
                description: String(localized: "onboarding_health_description"),
                isEnabled: $healthKitEnabled,
                action: requestHealthKit
            )

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func permissionCard(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        isEnabled: Binding<Bool>,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color.gray)
            }

            Spacer()

            if isEnabled.wrappedValue {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.appPrimary)
            } else {
                Button(String(localized: "onboarding_enable")) {
                    action()
                }
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.appPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.appPrimary.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentPage > 0 {
                Button {
                    withAnimation {
                        currentPage -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.gray)
                        .frame(width: 56, height: 56)
                        .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
                        .clipShape(Circle())
                }
            }

            Spacer()

            if currentPage < 2 {
                Button {
                    // Save name if on profile page
                    if currentPage == 1 && !inputName.isEmpty {
                        userName = inputName
                    }
                    withAnimation {
                        currentPage += 1
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(String(localized: "onboarding_next"))
                            .fontWeight(.bold)
                        Image(systemName: "chevron.right")
                    }
                    .foregroundStyle(Color.backgroundDark)
                    .padding(.horizontal, 32)
                    .frame(height: 56)
                    .background(Color.appPrimary)
                    .clipShape(Capsule())
                }
            } else {
                Button {
                    completeOnboarding()
                } label: {
                    HStack(spacing: 8) {
                        Text(String(localized: "onboarding_start"))
                            .fontWeight(.bold)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(Color.backgroundDark)
                    .padding(.horizontal, 32)
                    .frame(height: 56)
                    .background(Color.appPrimary)
                    .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Actions
    private func requestNotifications() {
        Task {
            let granted = await notificationService.requestAuthorization()
            await MainActor.run {
                notificationsEnabled = granted
            }
        }
    }

    private func requestHealthKit() {
        // Check if HealthKit is available first
        guard healthKitService.isHealthKitAvailable else {
            showHealthKitUnavailableAlert = true
            return
        }

        Task {
            do {
                try await healthKitService.requestAuthorization()
                await MainActor.run {
                    healthKitEnabled = true
                }
            } catch {
                print("HealthKit authorization failed: \(error)")
                await MainActor.run {
                    showHealthKitUnavailableAlert = true
                }
            }
        }
    }

    private func completeOnboarding() {
        // Save name if entered
        if !inputName.isEmpty {
            userName = inputName
        }
        // Mark onboarding as complete
        hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingView()
        .preferredColorScheme(.dark)
}
