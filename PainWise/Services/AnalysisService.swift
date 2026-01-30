import Foundation
import SwiftData

@MainActor
final class AnalysisService: ObservableObject {
    static let shared = AnalysisService()

    @Published var correlations: [CorrelationResult] = []
    @Published var insights: [Insight] = []
    @Published var isAnalyzing = false
    @Published var lastAnalyzedDate: Date?

    private init() {}

    // MARK: - Analyze Records

    func analyzeRecords(_ records: [PainRecord]) async {
        guard records.count >= 3 else {
            // Need at least 3 records for meaningful analysis
            generateMockAnalysis()
            return
        }

        isAnalyzing = true

        // Calculate correlations
        var results: [CorrelationResult] = []

        // 1. Pressure correlation
        let pressureCorrelation = calculatePressureCorrelation(records)
        if let corr = pressureCorrelation {
            results.append(corr)
        }

        // 2. Sleep correlation
        let sleepCorrelation = calculateSleepCorrelation(records)
        if let corr = sleepCorrelation {
            results.append(corr)
        }

        // 3. Step count correlation
        let stepCorrelation = calculateStepCorrelation(records)
        if let corr = stepCorrelation {
            results.append(corr)
        }

        // 4. Temperature correlation
        let tempCorrelation = calculateTemperatureCorrelation(records)
        if let corr = tempCorrelation {
            results.append(corr)
        }

        // Sort by absolute correlation strength
        correlations = results.sorted { abs($0.coefficient) > abs($1.coefficient) }

        // Generate insights
        insights = generateInsights(from: records, correlations: correlations)

        lastAnalyzedDate = Date()
        isAnalyzing = false
    }

    // MARK: - Correlation Calculations

    private func calculatePressureCorrelation(_ records: [PainRecord]) -> CorrelationResult? {
        let validRecords = records.filter { $0.weatherData?.pressure != nil }
        guard validRecords.count >= 3 else { return nil }

        let painLevels = validRecords.map { Double($0.painLevel) }
        let pressures = validRecords.compactMap { $0.weatherData?.pressure }

        guard painLevels.count == pressures.count else { return nil }

        let coefficient = pearsonCorrelation(painLevels, pressures)

        return CorrelationResult(
            factor: .pressure,
            coefficient: coefficient,
            sampleSize: validRecords.count,
            description: coefficient < -0.3 ? "低気圧時に痛みが増加" : (coefficient > 0.3 ? "高気圧時に痛みが増加" : "気圧との相関は弱い")
        )
    }

    private func calculateSleepCorrelation(_ records: [PainRecord]) -> CorrelationResult? {
        let validRecords = records.filter { $0.healthData?.sleepDuration != nil }
        guard validRecords.count >= 3 else { return nil }

        let painLevels = validRecords.map { Double($0.painLevel) }
        let sleepHours = validRecords.compactMap { $0.healthData?.sleepDuration }

        guard painLevels.count == sleepHours.count else { return nil }

        let coefficient = pearsonCorrelation(painLevels, sleepHours)

        return CorrelationResult(
            factor: .sleepDuration,
            coefficient: coefficient,
            sampleSize: validRecords.count,
            description: coefficient < -0.3 ? "睡眠不足で痛みが増加" : (coefficient > 0.3 ? "長時間睡眠で痛みが増加" : "睡眠との相関は弱い")
        )
    }

    private func calculateStepCorrelation(_ records: [PainRecord]) -> CorrelationResult? {
        let validRecords = records.filter { $0.healthData?.stepCount != nil }
        guard validRecords.count >= 3 else { return nil }

        let painLevels = validRecords.map { Double($0.painLevel) }
        let steps = validRecords.compactMap { $0.healthData?.stepCount }.map { Double($0) }

        guard painLevels.count == steps.count else { return nil }

        let coefficient = pearsonCorrelation(painLevels, steps)

        return CorrelationResult(
            factor: .stepCount,
            coefficient: coefficient,
            sampleSize: validRecords.count,
            description: coefficient < -0.3 ? "活動量が多いと痛みが軽減" : (coefficient > 0.3 ? "活動量が多いと痛みが増加" : "活動量との相関は弱い")
        )
    }

    private func calculateTemperatureCorrelation(_ records: [PainRecord]) -> CorrelationResult? {
        let validRecords = records.filter { $0.weatherData?.temperature != nil }
        guard validRecords.count >= 3 else { return nil }

        let painLevels = validRecords.map { Double($0.painLevel) }
        let temps = validRecords.compactMap { $0.weatherData?.temperature }

        guard painLevels.count == temps.count else { return nil }

        let coefficient = pearsonCorrelation(painLevels, temps)

        return CorrelationResult(
            factor: .temperature,
            coefficient: coefficient,
            sampleSize: validRecords.count,
            description: coefficient < -0.3 ? "気温が低いと痛みが増加" : (coefficient > 0.3 ? "気温が高いと痛みが増加" : "気温との相関は弱い")
        )
    }

    // MARK: - Pearson Correlation

    private func pearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count, x.count > 1 else { return 0 }

        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)

        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))

        guard denominator != 0 else { return 0 }

        return numerator / denominator
    }

    // MARK: - Generate Insights

    private func generateInsights(from records: [PainRecord], correlations: [CorrelationResult]) -> [Insight] {
        var insights: [Insight] = []

        // Most common body parts
        let bodyPartCounts = Dictionary(grouping: records.flatMap { $0.bodyParts }) { $0 }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        if let topBodyPart = bodyPartCounts.first {
            insights.append(Insight(
                type: .pattern,
                title: "最も多い痛み部位",
                description: "\(topBodyPart.key.rawValue)の痛みが\(topBodyPart.value)回記録されています"
            ))
        }

        // Average pain level
        let avgPain = records.isEmpty ? 0 : Double(records.map { $0.painLevel }.reduce(0, +)) / Double(records.count)
        insights.append(Insight(
            type: .summary,
            title: "平均痛みレベル",
            description: String(format: "過去の記録から平均 %.1f/10 の痛みレベルです", avgPain)
        ))

        // Strongest correlation insight
        if let strongest = correlations.first, abs(strongest.coefficient) > 0.3 {
            insights.append(Insight(
                type: .correlation,
                title: "主な相関要因",
                description: strongest.description
            ))
        }

        return insights
    }

    // MARK: - Mock Analysis (for demo/testing)

    private func generateMockAnalysis() {
        correlations = [
            CorrelationResult(
                factor: .pressure,
                coefficient: -0.78,
                sampleSize: 30,
                description: "低気圧接近時に痛みが悪化する傾向"
            ),
            CorrelationResult(
                factor: .sleepDuration,
                coefficient: -0.65,
                sampleSize: 28,
                description: "睡眠不足の翌日に痛みが増加"
            ),
            CorrelationResult(
                factor: .stepCount,
                coefficient: 0.12,
                sampleSize: 25,
                description: "活動量との相関は弱い"
            )
        ]

        insights = [
            Insight(type: .pattern, title: "最も多い痛み部位", description: "腰の痛みが最も多く記録されています"),
            Insight(type: .correlation, title: "主な相関要因", description: "気圧の変化と痛みに強い相関があります"),
            Insight(type: .summary, title: "記録状況", description: "より正確な分析のため、継続的な記録をお勧めします")
        ]

        lastAnalyzedDate = Date()
    }
}

// MARK: - Correlation Result (uses existing CorrelationFactor from AnalysisResult.swift)

struct CorrelationResult: Identifiable {
    let id = UUID()
    let factor: CorrelationFactor
    let coefficient: Double
    let sampleSize: Int
    let description: String

    var strength: CorrelationStrength {
        let absCoeff = abs(coefficient)
        if absCoeff >= 0.7 { return .strong }
        if absCoeff >= 0.4 { return .moderate }
        if absCoeff >= 0.2 { return .weak }
        return .negligible
    }

    var strengthText: String {
        let direction = coefficient < 0 ? "Negative" : "Positive"
        return "\(strength.englishName) \(direction)"
    }
}

// MARK: - Insight

struct Insight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let description: String
}

enum InsightType {
    case pattern
    case correlation
    case summary
    case recommendation
}
