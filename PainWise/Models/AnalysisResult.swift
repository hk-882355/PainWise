import Foundation
import SwiftData

@Model
final class AnalysisResult {
    var id: UUID
    var createdAt: Date
    var periodStart: Date
    var periodEnd: Date
    var correlations: [Correlation]
    var aiSummary: String
    var recommendations: [Recommendation]

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        periodStart: Date,
        periodEnd: Date,
        correlations: [Correlation] = [],
        aiSummary: String = "",
        recommendations: [Recommendation] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.correlations = correlations
        self.aiSummary = aiSummary
        self.recommendations = recommendations
    }
}

struct Correlation: Codable, Identifiable {
    var id: UUID = UUID()
    var factor: CorrelationFactor
    var coefficient: Double // -1.0 to 1.0
    var pValue: Double
    var description: String

    var strength: CorrelationStrength {
        let absCoeff = abs(coefficient)
        switch absCoeff {
        case 0.7...: return .strong
        case 0.4..<0.7: return .moderate
        case 0.2..<0.4: return .weak
        default: return .negligible
        }
    }

    var isSignificant: Bool {
        pValue < 0.05
    }
}

enum CorrelationFactor: String, Codable {
    case pressure = "気圧"
    case temperature = "気温"
    case humidity = "湿度"
    case sleepDuration = "睡眠時間"
    case stepCount = "歩数"
    case heartRate = "心拍数"

    var englishName: String {
        switch self {
        case .pressure: return "Atmospheric Pressure"
        case .temperature: return "Temperature"
        case .humidity: return "Humidity"
        case .sleepDuration: return "Sleep Duration"
        case .stepCount: return "Step Count"
        case .heartRate: return "Heart Rate"
        }
    }

    var icon: String {
        switch self {
        case .pressure: return "cloud.rain"
        case .temperature: return "thermometer"
        case .humidity: return "humidity"
        case .sleepDuration: return "bed.double"
        case .stepCount: return "figure.walk"
        case .heartRate: return "heart.fill"
        }
    }
}

enum CorrelationStrength: String {
    case strong = "強い"
    case moderate = "中程度"
    case weak = "弱い"
    case negligible = "ほぼなし"

    var englishName: String {
        switch self {
        case .strong: return "Strong"
        case .moderate: return "Moderate"
        case .weak: return "Weak"
        case .negligible: return "Negligible"
        }
    }
}

struct Recommendation: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var icon: String
    var priority: RecommendationPriority
    var isCompleted: Bool = false
}

enum RecommendationPriority: String, Codable {
    case high = "高"
    case medium = "中"
    case low = "低"
}
