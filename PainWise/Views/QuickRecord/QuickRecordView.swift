import SwiftUI
import SwiftData
import FirebaseCrashlytics

struct QuickRecordView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedBodyParts: Set<BodyPart> = []
    @State private var painLevel: Double = 5
    @State private var selectedPainTypes: Set<PainType> = []
    @State private var showFront: Bool = true
    @State private var note: String = ""
    @State private var isSaving = false
    @State private var isLoadingContext = false
    @State private var showSaveError = false
    @State private var weatherSnapshot: WeatherSnapshot?
    @State private var healthSnapshot: HealthSnapshot?
    @AppStorage("sleepDataEnabled") private var sleepDataEnabled = true
    @AppStorage("stepCountEnabled") private var stepCountEnabled = true
    @AppStorage("heartRateEnabled") private var heartRateEnabled = false
    @AppStorage("locationEnabled") private var locationEnabled = true

    private let weatherService = WeatherService.shared
    private let healthKitService = HealthKitService.shared
    @ObservedObject private var storeKit = StoreKitManager.shared

    private var painSeverityText: String {
        PainSeverity.fromLevel(Int(painLevel)).localizedName
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerView

                    // Body View Toggle
                    bodyViewToggle
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                    // Instruction
                    VStack(spacing: 4) {
                        Text(L10n.quickRecordSelectParts)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 16)

                    // Body Map
                    BodyMapView(
                        showFront: $showFront,
                        selectedParts: $selectedBodyParts
                    )
                    .frame(height: 320)

                    // Pain Slider Section
                    painSliderSection
                }
                .padding(.bottom, 100)
            }

            // Save Button
            saveButton
        }
        .task {
            await fetchContextData()
        }
        .alert(String(localized: "quick_record_save_error_title"), isPresented: $showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(String(localized: "quick_record_save_error_message"))
        }
    }

    // MARK: - Fetch Context Data
    private func fetchContextData() async {
        isLoadingContext = true
        defer { isLoadingContext = false }

        // Fetch weather and health data concurrently
        async let weatherTask: Void = fetchWeatherData()
        async let healthTask: Void = fetchHealthData()
        _ = await (weatherTask, healthTask)
    }

    private func fetchWeatherData() async {
        guard locationEnabled else { return }
        await weatherService.fetchCurrentWeather()
        weatherSnapshot = weatherService.currentWeather
    }

    private func fetchHealthData() async {
        let healthEnabled = sleepDataEnabled || stepCountEnabled || heartRateEnabled
        guard storeKit.isPremium, healthEnabled, healthKitService.isHealthKitAvailable else { return }
        do {
            if !healthKitService.isAuthorized {
                try await healthKitService.requestAuthorization()
            }
            healthSnapshot = await healthKitService.fetchTodayHealthData()
        } catch {
            #if DEBUG
            print("HealthKit authorization failed: \(error)")
            #endif
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .frame(width: 48, height: 48)
            }

            Spacer()

            Text(L10n.quickRecordTitle)
                .font(.headline)
                .fontWeight(.bold)

            Spacer()

            Color.clear
                .frame(width: 48, height: 48)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Body View Toggle
    private var bodyViewToggle: some View {
        HStack(spacing: 0) {
            toggleButton(title: String(localized: "body_view_front"), isSelected: showFront) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showFront = true
                }
            }

            toggleButton(title: String(localized: "body_view_back"), isSelected: !showFront) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showFront = false
                }
            }
        }
        .padding(6)
        .background(colorScheme == .dark ? Color(hex: "1f3a2e") : Color.gray.opacity(0.2))
        .clipShape(Capsule())
    }

    private func toggleButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(isSelected ? (colorScheme == .dark ? .white : Color.appPrimary) : Color.gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? (colorScheme == .dark ? Color(hex: "2f5e48") : Color.white) : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pain Slider Section
    private var painSliderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Pain Level Display
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.quickRecordPainLevel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.textSecondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(painLevel))")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(Color.appPrimary)

                        Text("/ 10")
                            .font(.subheadline)
                            .foregroundStyle(Color.gray)
                    }
                }

                Spacer()

                Text(painSeverityText)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.appPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.appPrimary.opacity(0.1))
                    .clipShape(Capsule())
            }

            // Slider
            PainSlider(value: $painLevel)

            // Pain Type Chips
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "quick_record_pain_type"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.textSecondary)

                // FlowLayout for better visibility (2-row display)
                FlowLayout(spacing: 8) {
                    ForEach(PainType.allCases, id: \.self) { painType in
                        painTypeChip(painType)
                    }
                }
            }

            // Note Input Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(String(localized: "quick_record_note"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.textSecondary)

                    Spacer()

                    Text("\(note.count)/200")
                        .font(.caption)
                        .foregroundStyle(note.count > 180 ? Color.orange : Color.gray)
                }

                TextEditor(text: $note)
                    .frame(minHeight: 80, maxHeight: 120)
                    .padding(12)
                    .background(colorScheme == .dark ? Color(hex: "1f3a2e") : Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        Group {
                            if note.isEmpty {
                                Text(String(localized: "quick_record_note_placeholder"))
                                    .foregroundStyle(Color.gray)
                                    .padding(.leading, 16)
                                    .padding(.top, 20)
                            }
                        },
                        alignment: .topLeading
                    )
                    .onChange(of: note) { _, newValue in
                        if newValue.count > 200 {
                            note = String(newValue.prefix(200))
                        }
                    }
            }
        }
        .padding(24)
        .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: -4)
    }

    private func painTypeChip(_ painType: PainType) -> some View {
        let isSelected = selectedPainTypes.contains(painType)

        return Button {
            if isSelected {
                selectedPainTypes.remove(painType)
            } else {
                selectedPainTypes.insert(painType)
            }
        } label: {
            Text("\(painType.rawValue) (\(painType.englishName))")
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .medium)
                .foregroundStyle(isSelected ? Color.backgroundDark : (colorScheme == .dark ? .white : Color.gray))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isSelected ? Color.appPrimary : (colorScheme == .dark ? Color(hex: "2f5e48") : Color.gray.opacity(0.1)))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Validation
    private var canSave: Bool {
        !selectedBodyParts.isEmpty && !isLoadingContext
    }

    private var validationMessage: String? {
        if selectedBodyParts.isEmpty {
            return String(localized: "quick_record_validation_select_body_part")
        }
        return nil
    }

    // MARK: - Save Button
    private var saveButton: some View {
        VStack(spacing: 8) {
            Spacer()

            // Validation Message
            if let message = validationMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.caption)
                    Text(message)
                        .font(.caption)
                }
                .foregroundStyle(Color.orange)
                .padding(.horizontal, 16)
            }

            Button(action: saveRecord) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                    Text(L10n.quickRecordSave)
                        .fontWeight(.bold)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canSave)
            .opacity(canSave ? 1.0 : 0.5)
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
            .background(
                LinearGradient(
                    colors: [
                        (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight).opacity(0),
                        (colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    // MARK: - Save Action
    private func saveRecord() {
        guard !isSaving else { return }
        isSaving = true

        let record = PainRecord(
            painLevel: Int(painLevel),
            bodyParts: Array(selectedBodyParts),
            painTypes: Array(selectedPainTypes),
            note: note,
            weatherData: weatherSnapshot,
            healthData: healthSnapshot
        )

        modelContext.insert(record)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            #if DEBUG
            print("Failed to save record: \(error)")
            #endif
            Crashlytics.crashlytics().record(error: error)
            isSaving = false
            showSaveError = true
        }
    }
}

#Preview {
    QuickRecordView()
        .preferredColorScheme(.dark)
        .modelContainer(for: PainRecord.self, inMemory: true)
}
