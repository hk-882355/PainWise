import Foundation
import SwiftData

@Model
final class PainForecast {
    var id: UUID
    var createdAt: Date
    var targetDate: Date
    var riskPercentage: Int // 0-100
    var riskLevel: RiskLevel
    var weatherForecast: WeatherForecast?
    var preventionTips: [PreventionTip]
    var confidence: Int // AI confidence 0-100

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        targetDate: Date,
        riskPercentage: Int,
        riskLevel: RiskLevel,
        weatherForecast: WeatherForecast? = nil,
        preventionTips: [PreventionTip] = [],
        confidence: Int = 0
    ) {
        self.id = id
        self.createdAt = createdAt
        self.targetDate = targetDate
        self.riskPercentage = riskPercentage
        self.riskLevel = riskLevel
        self.weatherForecast = weatherForecast
        self.preventionTips = preventionTips
        self.confidence = confidence
    }
}

enum RiskLevel: String, Codable {
    case low = "低"
    case medium = "中"
    case high = "高"
    case veryHigh = "非常に高い"

    var englishName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .veryHigh: return "Very High"
        }
    }

    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .veryHigh: return "red"
        }
    }

    var icon: String {
        switch self {
        case .low: return "checkmark.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.triangle.fill"
        case .veryHigh: return "exclamationmark.octagon.fill"
        }
    }
}

struct WeatherForecast: Codable {
    var date: Date
    var pressure: Double
    var pressureChange: Double // Change from previous day
    var temperature: Double
    var humidity: Double
    var condition: WeatherCondition
    var precipitationProbability: Int
}

enum WeatherCondition: String, Codable {
    case sunny = "晴れ"
    case cloudy = "曇り"
    case rainy = "雨"
    case snowy = "雪"
    case stormy = "嵐"
    case partlyCloudy = "曇り時々晴れ"

    var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .snowy: return "cloud.snow.fill"
        case .stormy: return "cloud.bolt.rain.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        }
    }
}

struct PreventionTip: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var isCompleted: Bool = false
}
