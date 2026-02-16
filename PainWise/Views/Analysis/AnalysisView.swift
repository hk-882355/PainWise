import SwiftUI
import SwiftData

struct AnalysisView: View {
    @Environment(\.colorScheme) var colorScheme
    @Query(sort: \PainRecord.timestamp, order: .reverse) private var records: [PainRecord]

    @ObservedObject private var analysisService = AnalysisService.shared
    @ObservedObject private var storeKit = StoreKitManager.shared
    @State private var showPremium = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerSection

                    // Correlation Cards Carousel
                    if storeKit.isPremium {
                        if !analysisService.correlations.isEmpty {
                            correlationCarousel
                        }

                        // Summary
                        summarySection

                        // Recommendations
                        recommendationsSection
                    } else {
                        premiumLockedSection
                    }
                }
                .padding(.bottom, 100)
            }
            .background(colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(L10n.analysisTitle)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { storeKit.isPremium ? refreshAnalysis() : (showPremium = true) }) {
                        Image(systemName: storeKit.isPremium ? (analysisService.isAnalyzing ? "arrow.clockwise" : "arrow.triangle.2.circlepath") : "lock.fill")
                    }
                    .disabled(storeKit.isPremium ? analysisService.isAnalyzing : false)
                }
            }
            .task {
                guard storeKit.isPremium else { return }
                await analysisService.analyzeRecords(records)
            }
            .onChange(of: records.count) { _, _ in
                guard storeKit.isPremium else { return }
                Task {
                    await analysisService.analyzeRecords(records)
                }
            }
        }
        .sheet(isPresented: $showPremium) {
            PremiumView()
        }
    }

    private func refreshAnalysis() {
        Task {
            await analysisService.analyzeRecords(records)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L10n.analysisLast30Days)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gray)
                    .tracking(1)

                Spacer()

                if let lastDate = analysisService.lastAnalyzedDate {
                    Text(lastDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.appPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.appPrimary.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            Text(L10n.analysisFactors)
                .font(.title)
                .fontWeight(.bold)

            Text(L10n.analysisCorrelationsDetected)
                .font(.subheadline)
                .foregroundStyle(Color.gray)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    // MARK: - Correlation Carousel
    private var correlationCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(analysisService.correlations) { correlation in
                    CorrelationCardView(correlation: correlation)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Summary
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.appPrimary)
                Text(L10n.analysisAiSummary)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            VStack(alignment: .leading, spacing: 16) {
                // Insights
                ForEach(analysisService.insights) { insight in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(insight.title.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.appPrimary)
                            .tracking(1)

                        Text(insight.description)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }

                    if insight.id != analysisService.insights.last?.id {
                        Divider()
                    }
                }

                // No data state
                if analysisService.insights.isEmpty {
                    Text(L10n.analysisInsufficientData)
                        .font(.subheadline)
                        .foregroundStyle(Color.gray)
                }

                // Feedback
                FeedbackSection()
            }
            .padding(24)
            .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appPrimary.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
    }

    private var premiumLockedSection: some View {
        VStack(spacing: 16) {
            PremiumGateCard(
                title: "分析レポートはプレミアム",
                message: "相関サマリー・おすすめアクションが利用できます。",
                buttonTitle: "プレミアムを見る",
                onUpgrade: { showPremium = true }
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("使える場所")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gray)
                    .textCase(.uppercase)
                    .tracking(1)

                Text("・分析タブ：相関サマリー\\n・履歴タブ：PDFエクスポート")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Recommendations
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.analysisRecommendedActions)
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                // Dynamic recommendations based on correlations
                if let pressureCorr = analysisService.correlations.first(where: { $0.factor == .pressure }),
                   abs(pressureCorr.coefficient) > 0.3 {
                    RecommendationRow(
                        icon: "exclamationmark.triangle.fill",
                        iconColor: .orange,
                        title: L10n.analysisCheckPressure,
                        subtitle: L10n.analysisPressureCorrelation
                    )
                }

                if let sleepCorr = analysisService.correlations.first(where: { $0.factor == .sleepDuration }),
                   sleepCorr.coefficient < -0.3 {
                    RecommendationRow(
                        icon: "alarm.fill",
                        iconColor: .blue,
                        title: L10n.analysisSleepReminder,
                        subtitle: L10n.analysisSleepCorrelation
                    )
                }

                // Default recommendation
                RecommendationRow(
                    icon: "pencil.circle.fill",
                    iconColor: .green,
                    title: L10n.analysisContinueRecording,
                    subtitle: L10n.analysisForAccurate
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - CorrelationFactor Color Extension
extension CorrelationFactor {
    var displayColor: Color {
        switch self {
        case .pressure: return .green
        case .temperature: return .red
        case .humidity: return .blue
        case .sleepDuration: return .indigo
        case .stepCount: return .orange
        case .heartRate: return .pink
        }
    }
}

// MARK: - Correlation Card View
struct CorrelationCardView: View {
    @Environment(\.colorScheme) var colorScheme
    let correlation: CorrelationResult

    private var cardColor: Color {
        correlation.factor.displayColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(cardColor.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: correlation.factor.icon)
                        .font(.title2)
                        .foregroundStyle(cardColor)
                }

                Spacer()

                // Coefficient
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%+.2f", correlation.coefficient))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(cardColor)

                    Text(correlation.strengthText.uppercased())
                        .font(.system(size: 8))
                        .fontWeight(.bold)
                        .foregroundStyle(cardColor.opacity(0.8))
                        .tracking(0.5)
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(cardColor)
                        .frame(width: abs(correlation.coefficient) * geometry.size.width, height: 6)
                }
            }
            .frame(height: 6)

            // Title & Description
            VStack(alignment: .leading, spacing: 4) {
                Text(correlation.factor.localizedName)
                    .font(.headline)
                    .fontWeight(.bold)

                Text(correlation.description)
                    .font(.caption)
                    .foregroundStyle(Color.gray)
            }
        }
        .padding(20)
        .frame(width: 256, height: 192)
        .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.1), lineWidth: 1)
        )
        // Accessibility
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(correlation.factor.localizedName)
        .accessibilityValue(String(localized: "accessibility_correlation_value \(correlation.strengthText) \(String(format: "%+.2f", correlation.coefficient))"))
        .accessibilityHint(correlation.description)
    }
}

// MARK: - Recommendation Row
struct RecommendationRow: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.gray)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.gray)
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

// MARK: - Feedback Section
struct FeedbackSection: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("analysisFeedback") private var feedback: String = ""  // "up", "down", or ""

    var body: some View {
        HStack {
            Text(L10n.analysisHelpfulQuestion)
                .font(.caption)
                .foregroundStyle(Color.gray)

            Spacer()

            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        feedback = feedback == "up" ? "" : "up"
                    }
                } label: {
                    Image(systemName: feedback == "up" ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .foregroundStyle(feedback == "up" ? Color.appPrimary : Color.gray)
                        .padding(8)
                        .background(feedback == "up" ? Color.appPrimary.opacity(0.1) : Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        feedback = feedback == "down" ? "" : "down"
                    }
                } label: {
                    Image(systemName: feedback == "down" ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .foregroundStyle(feedback == "down" ? Color.red : Color.gray)
                        .padding(8)
                        .background(feedback == "down" ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
    }
}

#Preview {
    AnalysisView()
        .preferredColorScheme(.dark)
        .modelContainer(for: PainRecord.self, inMemory: true)
}
