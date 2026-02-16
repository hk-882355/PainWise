import XCTest
import SwiftUI
@testable import PainWise

final class PainWiseTests: XCTestCase {

    // MARK: - PainRecord Tests

    func testPainLevelClampingAboveMax() {
        let record = PainRecord(painLevel: 15)
        XCTAssertEqual(record.painLevel, 10, "painLevel above 10 should be clamped to 10")
    }

    func testPainLevelClampingBelowMin() {
        let record = PainRecord(painLevel: -3)
        XCTAssertEqual(record.painLevel, 0, "painLevel below 0 should be clamped to 0")
    }

    func testPainLevelNormalRange() {
        for level in 0...10 {
            let record = PainRecord(painLevel: level)
            XCTAssertEqual(record.painLevel, level, "painLevel \(level) should not be modified")
        }
    }

    func testPainSeverityMild() {
        for level in 0...2 {
            let record = PainRecord(painLevel: level)
            XCTAssertEqual(record.painSeverity, .mild)
        }
    }

    func testPainSeverityModerate() {
        for level in 3...5 {
            let record = PainRecord(painLevel: level)
            XCTAssertEqual(record.painSeverity, .moderate)
        }
    }

    func testPainSeveritySevere() {
        for level in 6...8 {
            let record = PainRecord(painLevel: level)
            XCTAssertEqual(record.painSeverity, .severe)
        }
    }

    func testPainSeverityExtreme() {
        for level in 9...10 {
            let record = PainRecord(painLevel: level)
            XCTAssertEqual(record.painSeverity, .extreme)
        }
    }

    func testPainSeverityColor() {
        XCTAssertEqual(PainSeverity.mild.color, Color.green)
        XCTAssertEqual(PainSeverity.moderate.color, Color.yellow)
        XCTAssertEqual(PainSeverity.severe.color, Color.orange)
        XCTAssertEqual(PainSeverity.extreme.color, Color.red)
    }

    func testPainRecordDefaultValues() {
        let record = PainRecord(painLevel: 5)
        XCTAssertTrue(record.bodyParts.isEmpty)
        XCTAssertTrue(record.painTypes.isEmpty)
        XCTAssertTrue(record.note.isEmpty)
        XCTAssertNil(record.weatherData)
        XCTAssertNil(record.healthData)
    }

    func testPainRecordWithAllFields() {
        let weather = WeatherSnapshot(
            pressure: 1013.0,
            temperature: 20.0,
            humidity: 60.0,
            weatherCondition: "Clear",
            timestamp: Date()
        )
        let health = HealthSnapshot(
            stepCount: 5000,
            sleepDuration: 7.5,
            heartRate: 72,
            timestamp: Date()
        )
        let record = PainRecord(
            painLevel: 7,
            bodyParts: [.head, .neck],
            painTypes: [.throbbing, .dull],
            note: "テスト",
            weatherData: weather,
            healthData: health
        )

        XCTAssertEqual(record.painLevel, 7)
        XCTAssertEqual(record.bodyParts.count, 2)
        XCTAssertEqual(record.painTypes.count, 2)
        XCTAssertEqual(record.note, "テスト")
        XCTAssertNotNil(record.weatherData)
        XCTAssertNotNil(record.healthData)
    }

    // MARK: - BodyPart Tests

    func testBodyPartCaseCount() {
        XCTAssertEqual(BodyPart.allCases.count, 20)
    }

    func testBodyPartEnglishNames() {
        XCTAssertEqual(BodyPart.head.englishName, "Head")
        XCTAssertEqual(BodyPart.lowerBack.englishName, "Lower Back")
        XCTAssertEqual(BodyPart.leftKnee.englishName, "Left Knee")
    }

    func testBodyPartRawValuesAreStable() {
        // Raw values are used for persistence - must not change
        XCTAssertEqual(BodyPart.head.rawValue, "頭")
        XCTAssertEqual(BodyPart.neck.rawValue, "首")
        XCTAssertEqual(BodyPart.lowerBack.rawValue, "腰")
    }

    func testBodyPartCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let parts: [BodyPart] = [.head, .neck, .leftShoulder]
        let data = try encoder.encode(parts)
        let decoded = try decoder.decode([BodyPart].self, from: data)

        XCTAssertEqual(parts, decoded)
    }

    // MARK: - PainType Tests

    func testPainTypeCaseCount() {
        XCTAssertEqual(PainType.allCases.count, 7)
    }

    func testPainTypeCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let types: [PainType] = [.throbbing, .dull, .sharp]
        let data = try encoder.encode(types)
        let decoded = try decoder.decode([PainType].self, from: data)

        XCTAssertEqual(types, decoded)
    }

    // MARK: - WeatherSnapshot Tests

    func testWeatherSnapshotCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let snapshot = WeatherSnapshot(
            pressure: 1013.25,
            temperature: 22.5,
            humidity: 65.0,
            weatherCondition: "Rain",
            timestamp: Date(timeIntervalSince1970: 1000000)
        )

        let data = try encoder.encode(snapshot)
        let decoded = try decoder.decode(WeatherSnapshot.self, from: data)

        XCTAssertEqual(decoded.pressure, 1013.25)
        XCTAssertEqual(decoded.temperature, 22.5)
        XCTAssertEqual(decoded.humidity, 65.0)
        XCTAssertEqual(decoded.weatherCondition, "Rain")
    }

    // MARK: - HealthSnapshot Tests

    func testHealthSnapshotCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let snapshot = HealthSnapshot(
            stepCount: 8000,
            sleepDuration: 7.0,
            heartRate: 68,
            timestamp: Date(timeIntervalSince1970: 1000000)
        )

        let data = try encoder.encode(snapshot)
        let decoded = try decoder.decode(HealthSnapshot.self, from: data)

        XCTAssertEqual(decoded.stepCount, 8000)
        XCTAssertEqual(decoded.sleepDuration, 7.0)
        XCTAssertEqual(decoded.heartRate, 68)
    }

    func testHealthSnapshotCodingKeyCompat() throws {
        // sleepDuration is encoded as "sleepHours" for backwards compatibility
        let json = """
        {"stepCount": 5000, "sleepHours": 6.5, "heartRate": 70, "timestamp": 1000000}
        """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(HealthSnapshot.self, from: data)

        XCTAssertEqual(decoded.sleepDuration, 6.5)
        XCTAssertEqual(decoded.stepCount, 5000)
    }

    func testHealthSnapshotOptionalFields() throws {
        let json = """
        {"timestamp": 1000000}
        """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(HealthSnapshot.self, from: data)

        XCTAssertNil(decoded.stepCount)
        XCTAssertNil(decoded.sleepDuration)
        XCTAssertNil(decoded.heartRate)
    }

    // MARK: - WeatherCondition Tests

    func testWeatherConditionIcon() {
        XCTAssertEqual(WeatherCondition.sunny.icon, "sun.max.fill")
        XCTAssertEqual(WeatherCondition.rainy.icon, "cloud.rain.fill")
        XCTAssertEqual(WeatherCondition.snowy.icon, "cloud.snow.fill")
        XCTAssertEqual(WeatherCondition.stormy.icon, "cloud.bolt.rain.fill")
        XCTAssertEqual(WeatherCondition.cloudy.icon, "cloud.fill")
        XCTAssertEqual(WeatherCondition.partlyCloudy.icon, "cloud.sun.fill")
    }

    // MARK: - AlertLevel Tests

    func testAlertLevelColors() {
        XCTAssertEqual(AlertLevel.low.color, Color.green)
        XCTAssertEqual(AlertLevel.medium.color, Color.yellow)
        XCTAssertEqual(AlertLevel.high.color, Color.red)
    }

    // MARK: - RiskLevel Tests

    func testRiskLevelDisplayColor() {
        XCTAssertEqual(RiskLevel.low.displayColor, Color.green)
        XCTAssertEqual(RiskLevel.medium.displayColor, Color.yellow)
        XCTAssertEqual(RiskLevel.high.displayColor, Color.orange)
        XCTAssertEqual(RiskLevel.veryHigh.displayColor, Color.red)
    }

    func testRiskLevelDisplayIcon() {
        XCTAssertFalse(RiskLevel.low.displayIcon.isEmpty)
        XCTAssertFalse(RiskLevel.high.displayIcon.isEmpty)
    }

    // MARK: - PeriodFilter Tests

    func testPeriodFilterDaysBack() {
        XCTAssertEqual(HistoryView.PeriodFilter.thisWeek.daysBack, 7)
        XCTAssertEqual(HistoryView.PeriodFilter.thisMonth.daysBack, 30)
        XCTAssertEqual(HistoryView.PeriodFilter.threeMonths.daysBack, 90)
        XCTAssertNil(HistoryView.PeriodFilter.all.daysBack)
    }

    func testPeriodFilterAllCases() {
        XCTAssertEqual(HistoryView.PeriodFilter.allCases.count, 4)
    }

    func testPeriodFilterDisplayNameNotEmpty() {
        for filter in HistoryView.PeriodFilter.allCases {
            XCTAssertFalse(filter.displayName.isEmpty, "\(filter) displayName should not be empty")
        }
    }

    // MARK: - IntensityFilter Tests

    func testIntensityFilterAllCases() {
        XCTAssertEqual(HistoryView.IntensityFilter.allCases.count, 4)
    }

    func testIntensityFilterDisplayNameNotEmpty() {
        for filter in HistoryView.IntensityFilter.allCases {
            XCTAssertFalse(filter.displayName.isEmpty, "\(filter) displayName should not be empty")
        }
    }

    // MARK: - FlowLayout Tests

    func testFlowLayoutDefaultSpacing() {
        let layout = FlowLayout()
        XCTAssertEqual(layout.spacing, 8)
    }

    func testFlowLayoutCustomSpacing() {
        let layout = FlowLayout(spacing: 16)
        XCTAssertEqual(layout.spacing, 16)
    }
}
