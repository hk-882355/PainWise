import Foundation
import SwiftData

@Model
final class PainRecord {
    var id: UUID
    var timestamp: Date
    var painLevel: Int // 0-10
    var bodyParts: [BodyPart]
    var painTypes: [PainType]
    var note: String
    var weatherData: WeatherSnapshot?
    var healthData: HealthSnapshot?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        painLevel: Int,
        bodyParts: [BodyPart] = [],
        painTypes: [PainType] = [],
        note: String = "",
        weatherData: WeatherSnapshot? = nil,
        healthData: HealthSnapshot? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.painLevel = painLevel
        self.bodyParts = bodyParts
        self.painTypes = painTypes
        self.note = note
        self.weatherData = weatherData
        self.healthData = healthData
    }

    var painSeverity: PainSeverity {
        switch painLevel {
        case 0...2: return .mild
        case 3...5: return .moderate
        case 6...8: return .severe
        default: return .extreme
        }
    }
}

enum BodyPart: String, Codable, CaseIterable {
    case head = "頭"
    case neck = "首"
    case leftShoulder = "左肩"
    case rightShoulder = "右肩"
    case upperBack = "背中（上部）"
    case lowerBack = "腰"
    case chest = "胸"
    case abdomen = "腹部"
    case leftArm = "左腕"
    case rightArm = "右腕"
    case leftHand = "左手"
    case rightHand = "右手"
    case leftHip = "左股関節"
    case rightHip = "右股関節"
    case leftKnee = "左膝"
    case rightKnee = "右膝"
    case leftLeg = "左脚"
    case rightLeg = "右脚"
    case leftFoot = "左足"
    case rightFoot = "右足"

    var englishName: String {
        switch self {
        case .head: return "Head"
        case .neck: return "Neck"
        case .leftShoulder: return "Left Shoulder"
        case .rightShoulder: return "Right Shoulder"
        case .upperBack: return "Upper Back"
        case .lowerBack: return "Lower Back"
        case .chest: return "Chest"
        case .abdomen: return "Abdomen"
        case .leftArm: return "Left Arm"
        case .rightArm: return "Right Arm"
        case .leftHand: return "Left Hand"
        case .rightHand: return "Right Hand"
        case .leftHip: return "Left Hip"
        case .rightHip: return "Right Hip"
        case .leftKnee: return "Left Knee"
        case .rightKnee: return "Right Knee"
        case .leftLeg: return "Left Leg"
        case .rightLeg: return "Right Leg"
        case .leftFoot: return "Left Foot"
        case .rightFoot: return "Right Foot"
        }
    }
}

enum PainType: String, Codable, CaseIterable {
    case throbbing = "ズキズキ"
    case tingling = "ピリピリ"
    case dull = "鈍痛"
    case sharp = "鋭い"
    case burning = "焼けるような"
    case aching = "うずく"
    case stiff = "こわばり"

    var englishName: String {
        switch self {
        case .throbbing: return "Throbbing"
        case .tingling: return "Tingling"
        case .dull: return "Dull"
        case .sharp: return "Sharp"
        case .burning: return "Burning"
        case .aching: return "Aching"
        case .stiff: return "Stiff"
        }
    }

    var localizedName: String {
        switch self {
        case .throbbing: return String(localized: "pain_type_throbbing")
        case .tingling: return String(localized: "pain_type_tingling")
        case .dull: return String(localized: "pain_type_dull")
        case .sharp: return String(localized: "pain_type_sharp")
        case .burning: return String(localized: "pain_type_burning")
        case .aching: return String(localized: "pain_type_aching")
        case .stiff: return String(localized: "pain_type_stiff")
        }
    }
}

enum PainSeverity: String {
    case mild = "軽い"
    case moderate = "中度"
    case severe = "強い"
    case extreme = "激痛"

    var color: String {
        switch self {
        case .mild: return "primary"
        case .moderate: return "yellow"
        case .severe: return "orange"
        case .extreme: return "red"
        }
    }
}

struct WeatherSnapshot: Codable {
    var pressure: Double // hPa
    var temperature: Double // Celsius
    var humidity: Double // %
    var weatherCondition: String
    var timestamp: Date
}

struct HealthSnapshot: Codable {
    var stepCount: Double?
    var sleepDuration: Double?
    var heartRate: Double?
    var timestamp: Date

    // Backwards compatibility
    enum CodingKeys: String, CodingKey {
        case stepCount
        case sleepDuration = "sleepHours"
        case heartRate
        case timestamp
    }
}
