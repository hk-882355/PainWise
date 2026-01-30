import Foundation
import HealthKit

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()

    @Published var isAuthorized = false
    @Published var stepCount: Int?
    @Published var sleepHours: Double?
    @Published var heartRate: Double?

    // Types to read
    private let typesToRead: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepType)
        }
        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }
        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRateType)
        }
        return types
    }()

    private init() {}

    // MARK: - Authorization

    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isHealthKitAvailable else {
            throw HealthKitError.notAvailable
        }

        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        isAuthorized = true
    }

    // MARK: - Fetch Step Count

    func fetchTodayStepCount() async throws -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.typeNotAvailable
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sum = result?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }

                let steps = Int(sum.doubleValue(for: .count()))
                continuation.resume(returning: steps)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Fetch Sleep Data

    func fetchLastNightSleep() async throws -> Double {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.typeNotAvailable
        }

        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        let startOfYesterday = Calendar.current.startOfDay(for: yesterday)

        let predicate = HKQuery.predicateForSamples(withStart: startOfYesterday, end: now, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }

                // Calculate total sleep time (asleep states only)
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]

                var totalSleepSeconds: TimeInterval = 0

                for sample in sleepSamples {
                    if asleepValues.contains(sample.value) {
                        totalSleepSeconds += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                }

                let hours = totalSleepSeconds / 3600.0
                continuation.resume(returning: hours)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Fetch Heart Rate

    func fetchLatestHeartRate() async throws -> Double {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.typeNotAvailable
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: 0)
                    return
                }

                let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: heartRate)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Fetch All Today's Data

    func fetchTodayHealthData() async -> HealthSnapshot {
        var stepCount: Int?
        var sleepHours: Double?
        var heartRate: Double?

        do {
            stepCount = try await fetchTodayStepCount()
            self.stepCount = stepCount
        } catch {
            print("Failed to fetch step count: \(error)")
        }

        do {
            sleepHours = try await fetchLastNightSleep()
            self.sleepHours = sleepHours
        } catch {
            print("Failed to fetch sleep data: \(error)")
        }

        do {
            heartRate = try await fetchLatestHeartRate()
            self.heartRate = heartRate
        } catch {
            print("Failed to fetch heart rate: \(error)")
        }

        return HealthSnapshot(
            stepCount: stepCount != nil ? Double(stepCount!) : nil,
            sleepDuration: sleepHours,
            heartRate: heartRate,
            timestamp: Date()
        )
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case typeNotAvailable
    case authorizationDenied

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKitはこのデバイスで利用できません"
        case .typeNotAvailable:
            return "指定されたヘルスデータタイプが利用できません"
        case .authorizationDenied:
            return "ヘルスケアへのアクセスが拒否されました"
        }
    }
}
