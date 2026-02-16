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
            correlations = []
            insights = []
            lastAnalyzedDate = Date()
            return
        }

        isAnalyzing = true

        // Extract Sendable data for background computation
        let recordData = records.map { AnalysisRecordData(record: $0) }

        // Offload computation to background
        let (newCorrelations, newInsights) = await Task.detached {
            Self.computeAnalysis(recordData)
        }.value

        correlations = newCorrelations
        insights = newInsights
        lastAnalyzedDate = Date()
        isAnalyzing = false
    }

    // MARK: - Background Computation (nonisolated)

    private nonisolated static func computeAnalysis(
        _ records: [AnalysisRecordData]
    ) -> ([CorrelationResult], [Insight]) {
        var results: [CorrelationResult] = []

        let correlationConfigs: [(CorrelationFactor, (AnalysisRecordData) -> Double?, String, String, String)] = [
            (.pressure, { $0.pressure }, "低気圧時に痛みが増加", "高気圧時に痛みが増加", "気圧との相関は弱い"),
            (.sleepDuration, { $0.sleepDuration }, "睡眠不足で痛みが増加", "長時間睡眠で痛みが増加", "睡眠との相関は弱い"),
            (.stepCount, { $0.stepCount.map(Double.init) }, "活動量が多いと痛みが軽減", "活動量が多いと痛みが増加", "活動量との相関は弱い"),
            (.temperature, { $0.temperature }, "気温が低いと痛みが増加", "気温が高いと痛みが増加", "気温との相関は弱い"),
            (.humidity, { $0.humidity }, "湿度が低いと痛みが増加", "湿度が高いと痛みが増加", "湿度との相関は弱い"),
            (.heartRate, { $0.heartRate }, "心拍数が低いと痛みが増加", "心拍数が高いと痛みが増加", "心拍数との相関は弱い"),
        ]

        for (factor, extractor, negDesc, posDesc, weakDesc) in correlationConfigs {
            if let result = calculateCorrelation(
                records: records,
                factor: factor,
                valueExtractor: extractor,
                negativeDescription: negDesc,
                positiveDescription: posDesc,
                weakDescription: weakDesc
            ) {
                results.append(result)
            }
        }

        let sorted = results.sorted { abs($0.coefficient) > abs($1.coefficient) }
        let insights = generateInsights(from: records, correlations: sorted)

        return (sorted, insights)
    }

    // MARK: - Generic Correlation Calculator

    private nonisolated static func calculateCorrelation(
        records: [AnalysisRecordData],
        factor: CorrelationFactor,
        valueExtractor: (AnalysisRecordData) -> Double?,
        negativeDescription: String,
        positiveDescription: String,
        weakDescription: String
    ) -> CorrelationResult? {
        let validRecords = records.filter { valueExtractor($0) != nil }
        guard validRecords.count >= 3 else { return nil }

        let painLevels = validRecords.map { Double($0.painLevel) }
        let values = validRecords.compactMap { valueExtractor($0) }

        guard painLevels.count == values.count else { return nil }

        let coefficient = pearsonCorrelation(painLevels, values)
        let description = coefficient < -0.3 ? negativeDescription : (coefficient > 0.3 ? positiveDescription : weakDescription)

        return CorrelationResult(
            factor: factor,
            coefficient: coefficient,
            sampleSize: validRecords.count,
            description: description
        )
    }

    // MARK: - Pearson Correlation

    private nonisolated static func pearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double {
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

    private nonisolated static func generateInsights(from records: [AnalysisRecordData], correlations: [CorrelationResult]) -> [Insight] {
        var insights: [Insight] = []

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

        let avgPain = records.isEmpty ? 0 : Double(records.map { $0.painLevel }.reduce(0, +)) / Double(records.count)
        insights.append(Insight(
            type: .summary,
            title: "平均痛みレベル",
            description: String(format: "過去の記録から平均 %.1f/10 の痛みレベルです", avgPain)
        ))

        if let strongest = correlations.first, abs(strongest.coefficient) > 0.3 {
            insights.append(Insight(
                type: .correlation,
                title: "主な相関要因",
                description: strongest.description
            ))
        }

        return insights
    }
}

// MARK: - Sendable data extraction for background computation

struct AnalysisRecordData: Sendable {
    let painLevel: Int
    let bodyParts: [BodyPart]
    let pressure: Double?
    let temperature: Double?
    let humidity: Double?
    let sleepDuration: Double?
    let stepCount: Int?
    let heartRate: Double?

    init(record: PainRecord) {
        self.painLevel = record.painLevel
        self.bodyParts = record.bodyParts
        self.pressure = record.weatherData?.pressure
        self.temperature = record.weatherData?.temperature
        self.humidity = record.weatherData?.humidity
        self.sleepDuration = record.healthData?.sleepDuration
        self.stepCount = record.healthData?.stepCount.map(Int.init)
        self.heartRate = record.healthData?.heartRate
    }
}

// MARK: - Correlation Result

struct CorrelationResult: Identifiable, Sendable {
    let id: String
    let factor: CorrelationFactor
    let coefficient: Double
    let sampleSize: Int
    let description: String

    init(factor: CorrelationFactor, coefficient: Double, sampleSize: Int, description: String) {
        self.id = factor.rawValue
        self.factor = factor
        self.coefficient = coefficient
        self.sampleSize = sampleSize
        self.description = description
    }

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

struct Insight: Identifiable, Sendable {
    let id: String
    let type: InsightType
    let title: String
    let description: String

    init(type: InsightType, title: String, description: String) {
        self.id = "\(type)-\(title)"
        self.type = type
        self.title = title
        self.description = description
    }
}

enum InsightType: Sendable {
    case pattern
    case correlation
    case summary
    case recommendation
}
