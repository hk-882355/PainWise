import SwiftUI
import SwiftData
import UserNotifications
import FirebaseCrashlytics

struct DashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PainRecord.timestamp, order: .reverse, animation: .default)
    private var recentRecords: [PainRecord]

    init() {
        var descriptor = FetchDescriptor<PainRecord>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        descriptor.fetchLimit = 30
        _recentRecords = Query(descriptor)
    }

    // Weather Service
    private let weatherService = WeatherService.shared
    @State private var todayForecast: WeatherForecast?
    @State private var isLoadingForecast = false

    @State private var showQuickRecord = false
    @State private var showNotifications = false
    @State private var hasPendingNotifications = false
    @State private var showForecastDetail = false
    @State private var showAdviceDetail = false
    @State private var selectedAdvice: (category: String, title: String, description: String, imageName: String)?
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("locationEnabled") private var locationEnabled = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Today's Forecast Card
                    if let forecast = todayForecast {
                        ForecastCard(
                            alertLevel: alertLevelFromPressureChange(forecast.pressureChange),
                            pressure: Int(forecast.pressure),
                            message: generateForecastMessage(forecast),
                            accuracy: calculateDataRichness(),
                            weatherCondition: forecast.condition,
                            onViewDetail: { showForecastDetail = true }
                        )
                    } else if isLoadingForecast {
                        ForecastCard(
                            alertLevel: .low,
                            pressure: 1013,
                            message: L10n.dashboardLoadingWeather,
                            accuracy: 0,
                            onViewDetail: { showForecastDetail = true }
                        )
                    } else {
                        ForecastCard(
                            alertLevel: .medium,
                            pressure: 1008,
                            message: L10n.dashboardEnableLocation,
                            accuracy: 0,
                            onViewDetail: { showForecastDetail = true }
                        )
                    }

                    // Weekly Chart
                    WeeklyChartSection(records: Array(recentRecords.prefix(7)))

                    // Quick Record Button
                    quickRecordButton

                    // Advice Section
                    adviceSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
            .navigationBarHidden(true)
            .task {
                await loadTodayForecast()
                let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
                hasPendingNotifications = !pending.isEmpty
            }
            .onChange(of: locationEnabled) { _, _ in
                Task { await loadTodayForecast() }
            }
        }
        .sheet(isPresented: $showQuickRecord) {
            QuickRecordView()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationListView()
        }
        .sheet(isPresented: $showForecastDetail) {
            ForecastView()
        }
        .sheet(isPresented: $showAdviceDetail) {
            if let advice = selectedAdvice {
                AdviceDetailView(
                    category: advice.category,
                    title: advice.title,
                    description: advice.description,
                    imageName: advice.imageName
                )
            }
        }
    }

    // MARK: - Forecast Helpers
    private func loadTodayForecast() async {
        guard locationEnabled else {
            todayForecast = nil
            isLoadingForecast = false
            return
        }

        isLoadingForecast = true
        defer { isLoadingForecast = false }
        do {
            let forecasts = try await weatherService.fetchForecast()
            if let today = forecasts.first {
                todayForecast = today
            }
        } catch {
            #if DEBUG
            print("Failed to load forecast: \(error)")
            #endif
            Crashlytics.crashlytics().record(error: error)
        }
    }

    private func alertLevelFromPressureChange(_ change: Double) -> AlertLevel {
        if abs(change) >= 10 { return .high }
        if abs(change) >= 5 { return .medium }
        return .low
    }

    private func generateForecastMessage(_ forecast: WeatherForecast) -> String {
        if forecast.pressureChange < -5 {
            return L10n.forecastLowPressureWarning
        } else if forecast.pressureChange > 5 {
            return L10n.forecastHighPressure
        } else {
            return L10n.forecastStablePressure
        }
    }

    private func calculateDataRichness() -> Int {
        // Data richness score based on record count (0-100)
        // More records = better data for prediction
        return min(100, recentRecords.count * 5)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            HStack(spacing: 12) {
                // Profile Image
                Circle()
                    .fill(Color.appPrimary.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundStyle(Color.appPrimary)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.appPrimary.opacity(0.2), lineWidth: 2)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(greeting)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    Text(userName)
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }

            Spacer()

            // Notification Button
            Button(action: { showNotifications = true }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.title2)
                        .foregroundStyle(colorScheme == .dark ? .white : .gray)

                    if hasPendingNotifications {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 2, y: -2)
                    }
                }
            }
            .frame(width: 40, height: 40)
        }
        .padding(.top, 48)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return L10n.greetingMorning
        case 12..<18: return L10n.greetingAfternoon
        default: return L10n.greetingEvening
        }
    }

    // MARK: - Quick Record Button
    private var quickRecordButton: some View {
        Button(action: { showQuickRecord = true }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.dashboardRecordCurrentState)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .opacity(0.8)
                    Text(L10n.dashboardRecordButton)
                        .font(.title3)
                        .fontWeight(.bold)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.backgroundDark.opacity(0.1))
                        .frame(width: 48, height: 48)

                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            .foregroundStyle(Color.backgroundDark)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.appPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.appPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Advice Section
    private var adviceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.dashboardRecommendedAdvice)
                .font(.headline)
                .fontWeight(.bold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    Button {
                        selectedAdvice = (
                            category: L10n.adviceCategoryRelax,
                            title: L10n.adviceTeaTitle,
                            description: L10n.adviceTeaDescription,
                            imageName: "cup.and.saucer.fill"
                        )
                        showAdviceDetail = true
                    } label: {
                        AdviceCard(
                            category: L10n.adviceCategoryRelax,
                            title: L10n.adviceTeaTitle,
                            description: L10n.adviceTeaDescription,
                            imageName: "cup.and.saucer.fill"
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        selectedAdvice = (
                            category: L10n.adviceCategoryExercise,
                            title: L10n.adviceStretchTitle,
                            description: L10n.adviceStretchDescription,
                            imageName: "figure.flexibility"
                        )
                        showAdviceDetail = true
                    } label: {
                        AdviceCard(
                            category: L10n.adviceCategoryExercise,
                            title: L10n.adviceStretchTitle,
                            description: L10n.adviceStretchDescription,
                            imageName: "figure.flexibility"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Alert Level
enum AlertLevel {
    case low, medium, high

    var text: String {
        switch self {
        case .low: return L10n.alertLevelLow
        case .medium: return L10n.alertLevelMedium
        case .high: return L10n.alertLevelHigh
        }
    }

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
}

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
        .modelContainer(for: PainRecord.self, inMemory: true)
}
