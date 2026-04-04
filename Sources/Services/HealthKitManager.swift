import Foundation
import HealthKit
import OSLog

private let logger = Logger(subsystem: "com.theknack.lumifaste", category: "HealthKit")

/// Manages HealthKit integration for weight and step data.
/// HealthKit is OPTIONAL — the app works fine without it.
/// Weight writes are user-initiated (from WeightLogView), step reads are display-only.
@MainActor
@Observable
final class HealthKitManager {
    static let shared = HealthKitManager()

    // MARK: - State

    /// Whether HealthKit is available on this device
    let isAvailable: Bool

    /// Current authorization status for weight
    var weightAuthStatus: HKAuthorizationStatus = .notDetermined

    /// Whether we have permission to share (write) weight data
    var canWriteWeight: Bool = false

    /// Whether we have asked for permission this session
    var hasRequestedPermission: Bool = false

    /// Latest step count for today (display only)
    var todayStepCount: Int = 0

    /// Error message for UI display
    var errorMessage: String?

    /// Whether an import operation is in progress
    var isImporting: Bool = false

    // MARK: - HealthKit Store

    private let healthStore: HKHealthStore?

    private let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
    private let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

    private init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
            isAvailable = true
        } else {
            healthStore = nil
            isAvailable = false
        }
    }

    // MARK: - Authorization

    /// Request authorization to read/write weight and read steps.
    /// Shows Apple's standard HealthKit permission dialog.
    func requestAuthorization() async -> Bool {
        guard let healthStore else {
            logger.warning("HealthKit not available on this device")
            return false
        }

        let typesToShare: Set<HKSampleType> = [weightType]
        let typesToRead: Set<HKObjectType> = [weightType, stepType]

        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            hasRequestedPermission = true
            updateAuthorizationStatus()
            logger.info("HealthKit authorization completed — canWrite: \(self.canWriteWeight)")
            return true
        } catch {
            logger.error("HealthKit authorization failed: \(error.localizedDescription)")
            errorMessage = "Could not connect to Apple Health. Please try again."
            return false
        }
    }

    /// Update cached authorization status
    func updateAuthorizationStatus() {
        guard let healthStore else { return }
        weightAuthStatus = healthStore.authorizationStatus(for: weightType)
        canWriteWeight = weightAuthStatus == .sharingAuthorized
    }

    // MARK: - Write Weight

    /// Save a weight entry to HealthKit.
    /// - Parameters:
    ///   - weightKg: Weight in kilograms
    ///   - date: Date of the measurement
    /// - Returns: true if saved successfully
    func saveWeight(_ weightKg: Double, date: Date = .now) async -> Bool {
        guard let healthStore, canWriteWeight else {
            logger.info("Cannot write weight — not authorized")
            return false
        }

        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightKg)
        let sample = HKQuantitySample(
            type: weightType,
            quantity: quantity,
            start: date,
            end: date,
            metadata: [HKMetadataKeyWasUserEntered: true]
        )

        do {
            try await healthStore.save(sample)
            logger.info("Weight saved to HealthKit: \(String(format: "%.1f", weightKg)) kg")
            return true
        } catch {
            logger.error("Failed to save weight to HealthKit: \(error.localizedDescription)")
            errorMessage = "Could not save weight to Apple Health."
            return false
        }
    }

    // MARK: - Read Weight

    /// Fetch the most recent weight entries from HealthKit.
    /// - Parameter limit: Maximum number of entries to fetch
    /// - Returns: Array of (date, weightKg) tuples, newest first
    func fetchRecentWeights(limit: Int = 30) async -> [(date: Date, weightKg: Double)] {
        guard let healthStore else { return [] }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: weightType,
            predicate: nil,
            limit: limit,
            sortDescriptors: [sortDescriptor]
        ) { _, _, _ in }

        return await withCheckedContinuation { continuation in
            let sampleQuery = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    logger.error("Failed to fetch weights from HealthKit: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }

                let results = (samples as? [HKQuantitySample])?.map { sample in
                    (date: sample.endDate, weightKg: sample.quantity.doubleValue(for: .gramUnit(with: .kilo)))
                } ?? []

                continuation.resume(returning: results)
            }
            // Cancel the unused first query reference
            _ = query
            healthStore.execute(sampleQuery)
        }
    }

    // MARK: - Read Steps

    /// Fetch today's step count (display only).
    func fetchTodaySteps() async {
        guard let healthStore else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: .now,
            options: .strictStartDate
        )

        let stepsResult = await withCheckedContinuation { (continuation: CheckedContinuation<Double, Never>) in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    logger.error("Failed to fetch steps: \(error.localizedDescription)")
                    continuation.resume(returning: 0)
                    return
                }

                let sum = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: sum)
            }
            healthStore.execute(query)
        }

        todayStepCount = Int(stepsResult)
    }

    // MARK: - Import Weights from HealthKit

    /// Import weight entries from HealthKit that don't already exist in the app.
    /// Returns array of (date, weightKg) for entries that should be imported.
    func fetchWeightsForImport(existingDates: Set<Date>, limit: Int = 90) async -> [(date: Date, weightKg: Double)] {
        guard let healthStore else { return [] }

        isImporting = true
        defer { isImporting = false }

        let calendar = Calendar.current
        let ninetyDaysAgo = calendar.date(byAdding: .day, value: -limit, to: .now) ?? .now
        let predicate = HKQuery.predicateForSamples(
            withStart: ninetyDaysAgo,
            end: .now,
            options: .strictStartDate
        )
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    logger.error("Failed to fetch weights for import: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }

                let existingDays = Set(existingDates.map { calendar.startOfDay(for: $0) })

                let results = (samples as? [HKQuantitySample])?.compactMap { sample -> (date: Date, weightKg: Double)? in
                    let sampleDay = calendar.startOfDay(for: sample.endDate)
                    // Skip if we already have an entry for this day
                    guard !existingDays.contains(sampleDay) else { return nil }
                    return (date: sample.endDate, weightKg: sample.quantity.doubleValue(for: .gramUnit(with: .kilo)))
                } ?? []

                // Deduplicate: keep only one entry per day (the latest)
                var seenDays = Set<Date>()
                let deduped = results.filter { entry in
                    let day = calendar.startOfDay(for: entry.date)
                    if seenDays.contains(day) { return false }
                    seenDays.insert(day)
                    return true
                }

                continuation.resume(returning: deduped)
            }
            healthStore.execute(query)
        }
    }
}
