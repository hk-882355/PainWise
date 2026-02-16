import SwiftUI
import SwiftData
import FirebaseCrashlytics

struct ForecastView: View {
    @Environment(\.colorScheme) var colorScheme
    @Query private var records: [PainRecord]

    init() {
        var descriptor = FetchDescriptor<PainRecord>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        descriptor.fetchLimit = 30
        _records = Query(descriptor)
    }

    @State private var selectedDayIndex = 0
    @State private var forecasts: [WeatherForecast] = []
    @State private var isLoading = false
    @State private var fetchError: WeatherError?
    @AppStorage("locationEnabled") private var locationEnabled = true
    @ObservedObject private var storeKit = StoreKitManager.shared
    @State private var showPremium = false

    private let weatherService = WeatherService.shared

    private var preventionTips: [PreventionTipItem] {
        [
            PreventionTipItem(title: L10n.preventionWarmBath, description: L10n.preventionWarmBathDesc),
            PreventionTipItem(title: L10n.preventionStretch, description: L10n.preventionStretchDesc),
            PreventionTipItem(title: L10n.preventionMedication, description: L10n.preventionMedicationDesc)
        ]
    }

    private var selectedForecast: WeatherForecast? {
        guard selectedDayIndex < forecasts.count else { return nil }
        return forecasts[selectedDayIndex]
    }

    private var riskLevel: RiskLevel {
        guard let forecast = selectedForecast else { return .low }
        return calculateRiskLevel(pressureChange: forecast.pressureChange)
    }

    private var riskPercent: Int {
        guard let forecast = selectedForecast else { return 20 }

        // Calculate risk based on pressure change and historical data
        let basePressureRisk = max(0, min(100, Int(abs(forecast.pressureChange) * 8)))

        // Adjust based on historical correlation
        let avgPain = records.isEmpty ? 5.0 : Double(records.prefix(10).map { $0.painLevel }.reduce(0, +)) / min(10.0, Double(records.count))
        let historicalFactor = avgPain / 10.0

        return min(100, basePressureRisk + Int(historicalFactor * 20))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        if forecasts.isEmpty {
                            if locationEnabled {
                                emptyState
                            } else {
                                locationDisabledState
                            }
                        } else {
                            if !storeKit.isPremium {
                                premiumGate
                                    .padding(.horizontal, 20)
                                    .padding(.top, 16)
                            }

                            // Forecast Timeline
                            dayTimeline

                            // Main Risk Display
                            riskDisplay

                            // Alert Card
                            if let forecast = selectedForecast, abs(forecast.pressureChange) > 5 {
                                alertCard(pressure: forecast.pressure, change: forecast.pressureChange)
                            }

                            // Divider
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.2), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 1)
                                .padding(.horizontal, 20)

                            // Prevention Tips
                            preventionSection
                        }
                    }
                    .padding(.bottom, 100)
                }

                if isLoading {
                    loadingOverlay
                }
            }
            .background(colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(L10n.forecastViewTitle)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await loadForecasts() } }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .task {
                await loadForecasts()
            }
            .onChange(of: locationEnabled) { _, _ in
                Task { await loadForecasts() }
            }
            .onChange(of: storeKit.isPremium) { _, newValue in
                if !newValue {
                    selectedDayIndex = 0
                }
            }
        }
        .sheet(isPresented: $showPremium) {
            PremiumView()
        }
    }

    private func loadForecasts() async {
        guard locationEnabled else {
            forecasts = []
            isLoading = false
            return
        }

        isLoading = true
        fetchError = nil
        defer { isLoading = false }

        do {
            let newForecasts = try await weatherService.fetchForecast()
            forecasts = newForecasts
            if !storeKit.isPremium {
                selectedDayIndex = 0
            } else if selectedDayIndex >= newForecasts.count {
                selectedDayIndex = max(0, newForecasts.count - 1)
            }
        } catch let error as WeatherError {
            fetchError = error
            #if DEBUG
            print("Failed to fetch forecast: \(error)")
            #endif
            if error != .missingAPIKey {
                Crashlytics.crashlytics().record(error: error)
            }
        } catch {
            fetchError = .invalidResponse
            #if DEBUG
            print("Failed to fetch forecast: \(error)")
            #endif
            Crashlytics.crashlytics().record(error: error)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(emptyStateTitle)
                .font(.headline)

            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if fetchError != .missingAPIKey {
                Button("再読み込み") {
                    Task { await loadForecasts() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.top, 100)
    }

    private var emptyStateIcon: String {
        switch fetchError {
        case .missingAPIKey: return "key.slash"
        case .locationUnavailable: return "location.slash"
        default: return "cloud.slash"
        }
    }

    private var emptyStateTitle: String {
        switch fetchError {
        case .missingAPIKey: return "天気APIが未設定です"
        case .locationUnavailable: return "位置情報を取得できません"
        default: return "予報を取得できませんでした"
        }
    }

    private var emptyStateMessage: String {
        switch fetchError {
        case .missingAPIKey:
            return "OpenWeatherMap APIキーをSecrets.xcconfigに設定してください。"
        case .locationUnavailable:
            return "設定アプリから位置情報の利用を許可してください。"
        default:
            return "ネットワーク接続を確認して、再度お試しください。"
        }
    }

    private var locationDisabledState: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.slash")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("位置情報がオフです")
                .font(.headline)

            Text(L10n.dashboardEnableLocation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.top, 100)
    }

    private var loadingOverlay: some View {
        ProgressView()
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.black.opacity(0.6) : Color.white.opacity(0.9))
            )
            .shadow(radius: 10)
    }

    private func calculateRiskLevel(pressureChange: Double) -> RiskLevel {
        if abs(pressureChange) >= 10 { return .high }
        if abs(pressureChange) >= 5 { return .medium }
        return .low
    }

    // MARK: - Day Timeline
    private var dayTimeline: some View {
        HStack(spacing: 12) {
            ForEach(0..<forecasts.count, id: \.self) { index in
                let forecast = forecasts[index]
                let isLocked = !storeKit.isPremium && index > 0
                DayCard(
                    date: formatDate(forecast.date),
                    dayOfWeek: index == 0 ? L10n.forecastToday : nil,
                    riskPercent: calculateDayRiskPercent(forecast),
                    weather: forecast.condition,
                    isSelected: index == selectedDayIndex,
                    isLocked: isLocked
                ) {
                    if isLocked {
                        showPremium = true
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDayIndex = index
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private func calculateDayRiskPercent(_ forecast: WeatherForecast) -> Int {
        let basePressureRisk = max(0, min(100, Int(abs(forecast.pressureChange) * 8)))
        return min(100, basePressureRisk + 10)
    }

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        return formatter
    }()

    private func formatDate(_ date: Date) -> String {
        Self.shortDateFormatter.string(from: date)
    }

    private var premiumGate: some View {
        PremiumGateCard(
            title: "5日予報はプレミアム",
            message: "今日以降の予報はプレミアムで解放されます。",
            buttonTitle: "プレミアムを見る",
            onUpgrade: { showPremium = true }
        )
    }

    // MARK: - Risk Display
    private var riskDisplay: some View {
        VStack(spacing: 24) {
            if let forecast = selectedForecast {
                Text(L10n.forecastPredictionFor(formatFullDate(forecast.date)))
                    .font(.title2)
                    .fontWeight(.bold)
            }

            // Circular Gauge
            ZStack {
                // Background Ring
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 192, height: 192)

                // Progress Ring
                Circle()
                    .trim(from: 0, to: CGFloat(riskPercent) / 100.0)
                    .stroke(
                        riskLevel.displayColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 192, height: 192)
                    .rotationEffect(.degrees(-90))

                // Glow Effect
                Circle()
                    .fill(riskLevel.displayColor.opacity(0.05))
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)

                // Center Content
                VStack(spacing: 8) {
                    Text(L10n.forecastPredictedRisk)
                        .font(.caption)
                        .foregroundStyle(Color.gray)

                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("\(riskPercent)")
                            .font(.system(size: 56, weight: .bold))
                        Text("%")
                            .font(.title)
                            .foregroundStyle(riskLevel.displayColor)
                    }

                    // Risk Badge
                    HStack(spacing: 4) {
                        Image(systemName: riskLevel.displayIcon)
                            .font(.caption)
                        Text(riskLevel.displayText)
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(riskLevel.displayColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(riskLevel.displayColor.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            // Pressure Info
            if let forecast = selectedForecast {
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text(L10n.forecastCardPressure)
                            .font(.caption)
                            .foregroundStyle(Color.gray)
                        Text(String(format: "%.0f hPa", forecast.pressure))
                            .font(.headline)
                            .fontWeight(.bold)
                    }

                    VStack(spacing: 4) {
                        Text(L10n.forecastChange)
                            .font(.caption)
                            .foregroundStyle(Color.gray)
                        Text(String(format: "%+.1f", forecast.pressureChange))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(forecast.pressureChange < 0 ? Color.red : Color.green)
                    }

                    VStack(spacing: 4) {
                        Text(L10n.forecastTemperature)
                            .font(.caption)
                            .foregroundStyle(Color.gray)
                        Text(String(format: "%.0f°C", forecast.temperature))
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                .padding()
                .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 24)
    }

    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    private func formatFullDate(_ date: Date) -> String {
        Self.fullDateFormatter.string(from: date)
    }

    // MARK: - Alert Card
    private func alertCard(pressure: Double, change: Double) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: change < 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.appPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(change < 0 ? L10n.forecastPressureDropWarning : L10n.forecastPressureRising)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.appPrimary)

                Text(change < 0 ? L10n.forecastPressureDropDetail : L10n.forecastPressureStableDetail)
                    .font(.caption)
                    .foregroundStyle(Color.gray)
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? Color.surfaceDark.opacity(0.5) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }

    // MARK: - Prevention Section
    private var preventionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "cross.case.fill")
                    .foregroundStyle(Color.appPrimary)
                Text(L10n.forecastRecommendedPrevention)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 12) {
                ForEach(preventionTips) { tip in
                    PreventionTipRow(tip: tip)
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - RiskLevel Extensions (using RiskLevel from Forecast.swift)
extension RiskLevel {
    var displayText: String {
        localizedName
    }

    var displayIcon: String {
        switch self {
        case .low: return "checkmark.circle.fill"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.triangle.fill"
        case .veryHigh: return "exclamationmark.octagon.fill"
        }
    }

    var displayColor: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .veryHigh: return .red
        }
    }
}

// MARK: - Supporting Types
struct PreventionTipItem: Identifiable {
    let id: String
    let title: String
    let description: String

    init(title: String, description: String) {
        self.id = title
        self.title = title
        self.description = description
    }
}

// MARK: - Day Card
struct DayCard: View {
    @Environment(\.colorScheme) var colorScheme
    let date: String
    let dayOfWeek: String?
    let riskPercent: Int
    let weather: WeatherCondition
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    private var weatherIcon: String {
        switch weather {
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .snowy: return "cloud.snow.fill"
        case .stormy: return "cloud.bolt.rain.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let dow = dayOfWeek {
                    Text("\(date) (\(dow))")
                        .font(.caption)
                        .fontWeight(isSelected ? .bold : .medium)
                        .foregroundStyle(isSelected ? Color.appPrimary : Color.gray)
                } else {
                    Text(date)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.gray)
                }

                Image(systemName: weatherIcon)
                    .font(.title)
                    .foregroundStyle(isSelected ? Color.appPrimary : Color.gray)

                Text("\(riskPercent)%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(isSelected ? .white : Color.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected ?
                    (colorScheme == .dark ? Color(hex: "1a382b") : Color.appPrimary.opacity(0.1)) :
                    (colorScheme == .dark ? Color.surfaceDark.opacity(0.5) : Color.white)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.appPrimary : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? Color.appPrimary.opacity(0.15) : .clear, radius: 15)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            if isLocked {
                PremiumBadge(text: "Premium")
                    .padding(6)
            }
        }
        .opacity(isLocked ? 0.6 : 1)
        // Accessibility
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(dayOfWeek.map { "\(date) \($0)" } ?? date)
        .accessibilityValue(String(localized: "accessibility_day_card_risk \(riskPercent)"))
        .accessibilityHint(isSelected ? String(localized: "accessibility_currently_selected") : String(localized: "accessibility_tap_to_select"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Prevention Tip Row
struct PreventionTipRow: View {
    @Environment(\.colorScheme) var colorScheme
    let tip: PreventionTipItem
    @AppStorage private var isCompleted: Bool

    init(tip: PreventionTipItem) {
        self.tip = tip
        // Daily key: resets each day automatically
        let dateKey = Self.todayDateKey
        self._isCompleted = AppStorage(wrappedValue: false, "prevention_tip_\(dateKey)_\(tip.title)")
    }

    private static let dateKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static var todayDateKey: String {
        dateKeyFormatter.string(from: Date())
    }

    var body: some View {
        HStack(spacing: 16) {
            // Checkbox
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isCompleted.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(isCompleted ? Color.appPrimary : Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isCompleted {
                        Circle()
                            .fill(Color.appPrimary)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? Color.gray : (colorScheme == .dark ? .white : .black))

                Text(tip.description)
                    .font(.caption)
                    .foregroundStyle(Color.gray)
            }

            Spacer()
        }
        .padding(16)
        .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.1), lineWidth: 1)
        )
        // Accessibility
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(tip.title)
        .accessibilityValue(isCompleted ? String(localized: "accessibility_completed") : String(localized: "accessibility_not_completed"))
        .accessibilityHint(String(localized: "accessibility_tap_to_toggle"))
        .accessibilityAddTraits(isCompleted ? .isSelected : [])
    }
}

#Preview {
    ForecastView()
        .preferredColorScheme(.dark)
        .modelContainer(for: PainRecord.self, inMemory: true)
}
