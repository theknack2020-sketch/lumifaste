# HealthKit Integration Research — Fasting/Health Tracking iOS App

> **Date:** March 22, 2026  
> **Scope:** Reading weight/activity data, writing fasting data, entitlements, authorization, background delivery, privacy, App Review, SwiftUI patterns

---

## Table of Contents

1. [Reading Weight Data (bodyMass)](#1-reading-weight-data-bodymass)
2. [Reading Active Calories & Step Count](#2-reading-active-calories--step-count)
3. [Writing Fasting Data — The Fasting Problem](#3-writing-fasting-data--the-fasting-problem)
4. [Required Entitlements & Info.plist Keys](#4-required-entitlements--infoplist-keys)
5. [Authorization Flow Best Practices](#5-authorization-flow-best-practices)
6. [Background Delivery for Health Data Updates](#6-background-delivery-for-health-data-updates)
7. [Privacy Requirements — Usage Description Strings](#7-privacy-requirements--usage-description-strings)
8. [Common HealthKit Rejection Reasons & How to Avoid Them](#8-common-healthkit-rejection-reasons--how-to-avoid-them)
9. [HealthKit + SwiftUI Integration Patterns](#9-healthkit--swiftui-integration-patterns)
10. [Sources](#10-sources)

---

## 1. Reading Weight Data (bodyMass)

HealthKit stores weight as `HKQuantityTypeIdentifier.bodyMass` with unit `HKUnit.gramUnit(with: .kilo)` or `.pound()`.

### Query Most Recent Weight

```swift
import HealthKit

func fetchLatestWeight() async throws -> Double? {
    let healthStore = HKHealthStore()
    
    guard let bodyMassType = HKQuantityType.quantityType(
        forIdentifier: .bodyMass
    ) else {
        return nil
    }
    
    let sortDescriptor = NSSortDescriptor(
        key: HKSampleSortIdentifierEndDate,
        ascending: false
    )
    
    return try await withCheckedThrowingContinuation { continuation in
        let query = HKSampleQuery(
            sampleType: bodyMassType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, results, error in
            if let error {
                continuation.resume(throwing: error)
                return
            }
            
            guard let sample = results?.first as? HKQuantitySample else {
                continuation.resume(returning: nil)
                return
            }
            
            let weightInKg = sample.quantity.doubleValue(
                for: HKUnit.gramUnit(with: .kilo)
            )
            continuation.resume(returning: weightInKg)
        }
        healthStore.execute(query)
    }
}
```

### Statistics Query for Weight Over Time

```swift
func fetchWeightHistory(days: Int) async throws -> [(date: Date, kg: Double)] {
    let healthStore = HKHealthStore()
    let bodyMassType = HKQuantityType(.bodyMass)
    
    let calendar = Calendar.current
    let endDate = Date()
    let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
    
    let predicate = HKQuery.predicateForSamples(
        withStart: startDate,
        end: endDate,
        options: .strictStartDate
    )
    
    let sortDescriptor = NSSortDescriptor(
        key: HKSampleSortIdentifierStartDate,
        ascending: true
    )
    
    return try await withCheckedThrowingContinuation { continuation in
        let query = HKSampleQuery(
            sampleType: bodyMassType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, results, error in
            if let error {
                continuation.resume(throwing: error)
                return
            }
            
            let samples = (results as? [HKQuantitySample] ?? []).map { sample in
                (
                    date: sample.startDate,
                    kg: sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                )
            }
            continuation.resume(returning: samples)
        }
        healthStore.execute(query)
    }
}
```

**Key points:**
- Weight can come from Apple Watch, smart scales (Withings, etc.), or manual entry
- Always use `NSSortDescriptor` with `HKSampleSortIdentifierEndDate` descending to get the most recent
- HealthKit may contain multiple weight entries per day from different sources

---

## 2. Reading Active Calories & Step Count

### Step Count (Cumulative)

Step count is cumulative — use `HKStatisticsQuery` with `.cumulativeSum` to aggregate:

```swift
func fetchTodayStepCount() async throws -> Double {
    let healthStore = HKHealthStore()
    let stepType = HKQuantityType(.stepCount)
    
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: Date())
    let predicate = HKQuery.predicateForSamples(
        withStart: startOfDay,
        end: Date(),
        options: .strictStartDate
    )
    
    return try await withCheckedThrowingContinuation { continuation in
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, statistics, error in
            if let error {
                continuation.resume(throwing: error)
                return
            }
            
            let count = statistics?
                .sumQuantity()?
                .doubleValue(for: .count()) ?? 0
            continuation.resume(returning: count)
        }
        healthStore.execute(query)
    }
}
```

### Active Energy Burned (Cumulative)

```swift
func fetchTodayActiveCalories() async throws -> Double {
    let healthStore = HKHealthStore()
    let energyType = HKQuantityType(.activeEnergyBurned)
    
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: Date())
    let predicate = HKQuery.predicateForSamples(
        withStart: startOfDay,
        end: Date(),
        options: .strictStartDate
    )
    
    return try await withCheckedThrowingContinuation { continuation in
        let query = HKStatisticsQuery(
            quantityType: energyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, statistics, error in
            if let error {
                continuation.resume(throwing: error)
                return
            }
            
            let calories = statistics?
                .sumQuantity()?
                .doubleValue(for: .kilocalorie()) ?? 0
            continuation.resume(returning: calories)
        }
        healthStore.execute(query)
    }
}
```

### Statistics Collection Query (Weekly/Monthly Aggregation)

For charting steps or calories over time:

```swift
func fetchDailySteps(for days: Int) async throws -> [(date: Date, steps: Double)] {
    let healthStore = HKHealthStore()
    let stepType = HKQuantityType(.stepCount)
    
    let calendar = Calendar.current
    let endDate = Date()
    let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
    
    let daily = DateComponents(day: 1)
    let predicate = HKQuery.predicateForSamples(
        withStart: startDate,
        end: endDate,
        options: .strictStartDate
    )
    
    return try await withCheckedThrowingContinuation { continuation in
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: calendar.startOfDay(for: startDate),
            intervalComponents: daily
        )
        
        query.initialResultsHandler = { _, collection, error in
            if let error {
                continuation.resume(throwing: error)
                return
            }
            
            var results: [(date: Date, steps: Double)] = []
            collection?.enumerateStatistics(
                from: startDate, to: endDate
            ) { statistics, _ in
                let steps = statistics.sumQuantity()?
                    .doubleValue(for: .count()) ?? 0
                results.append((date: statistics.startDate, steps: steps))
            }
            continuation.resume(returning: results)
        }
        healthStore.execute(query)
    }
}
```

**Key identifiers for a fasting/health app:**

| Data | Identifier | Unit | Query Type |
|------|-----------|------|-----------|
| Steps | `.stepCount` | `.count()` | `cumulativeSum` |
| Active Calories | `.activeEnergyBurned` | `.kilocalorie()` | `cumulativeSum` |
| Resting Calories | `.basalEnergyBurned` | `.kilocalorie()` | `cumulativeSum` |
| Weight | `.bodyMass` | `.gramUnit(with: .kilo)` | Sample query |
| Body Fat % | `.bodyFatPercentage` | `.percent()` | Sample query |
| Heart Rate | `.heartRate` | `.count()/.minute()` | Sample query |
| Water | `.dietaryWater` | `.liter()` | `cumulativeSum` |
| Dietary Energy | `.dietaryEnergyConsumed` | `.kilocalorie()` | `cumulativeSum` |

---

## 3. Writing Fasting Data — The Fasting Problem

### ⚠️ There Is No Native Fasting Type in HealthKit

After reviewing all `HKCategoryTypeIdentifier` and `HKQuantityTypeIdentifier` values in Apple's documentation, **HealthKit does not have a dedicated fasting category or quantity type.** There is no `HKCategoryTypeIdentifier.fasting` or equivalent.

### Recommended Strategies

#### Strategy A: Store Fasting Data Locally (Recommended)

Store fasting windows in your own persistence layer (SwiftData, CoreData, or even UserDefaults for simple cases). This is what most fasting apps (Zero, Fastic, Simple) do.

```swift
import SwiftData

@Model
class FastingSession {
    var startDate: Date
    var endDate: Date?            // nil = currently fasting
    var targetDuration: TimeInterval  // e.g., 16 * 3600 for 16:8
    var fastingPlan: String       // "16:8", "18:6", "OMAD", "5:2", etc.
    var completedSuccessfully: Bool
    var notes: String?
    
    var isActive: Bool { endDate == nil }
    
    var elapsedDuration: TimeInterval {
        let end = endDate ?? Date()
        return end.timeIntervalSince(startDate)
    }
    
    var progress: Double {
        min(elapsedDuration / targetDuration, 1.0)
    }
    
    init(startDate: Date, targetDuration: TimeInterval, fastingPlan: String) {
        self.startDate = startDate
        self.targetDuration = targetDuration
        self.fastingPlan = fastingPlan
        self.completedSuccessfully = false
    }
}
```

#### Strategy B: Write Dietary Energy to HealthKit (Supplementary)

You can optionally write `dietaryEnergyConsumed` samples when the user logs meals (breaking a fast), giving the Health app nutrition data. This is a legitimate HealthKit write that adds value.

```swift
func writeMealCalories(
    calories: Double,
    date: Date
) async throws {
    let healthStore = HKHealthStore()
    let energyType = HKQuantityType(.dietaryEnergyConsumed)
    
    let quantity = HKQuantity(
        unit: .kilocalorie(),
        doubleValue: calories
    )
    
    let sample = HKQuantitySample(
        type: energyType,
        quantity: quantity,
        start: date,
        end: date,
        metadata: [
            HKMetadataKeyFoodType: "Meal after fast"
        ]
    )
    
    try await healthStore.save(sample)
}
```

#### Strategy C: Use Mindful Session as a Proxy (Not Recommended)

Some developers have considered using `HKCategoryTypeIdentifier.mindfulSession` to represent fasting, since it's a time-range-based category sample. **This is not recommended** — Apple may reject your app for writing data that doesn't match the type's intended purpose (see Section 8). Mindful sessions are specifically for meditation/breathing exercises.

#### Strategy D: Write Custom Workout (Not Recommended for Fasting)

Workouts represent physical activity. Fasting isn't exercise. Don't abuse this.

### Recommended Approach for a Fasting App

1. **Store fasting sessions locally** using SwiftData/CoreData
2. **Read** weight, steps, active calories, dietary energy from HealthKit (shows health context alongside fasting)
3. **Optionally write** dietary energy when the user logs meals
4. **Read** sleep data (`HKCategoryTypeIdentifier.sleepAnalysis`) to correlate sleep with fasting
5. **Do NOT write** fake/proxy data to HealthKit types that don't represent fasting

---

## 4. Required Entitlements & Info.plist Keys

### Xcode Capabilities

In **Signing & Capabilities**, add:

1. **HealthKit** — enables the base entitlement
2. **HealthKit > Background Delivery** (checkbox) — if you want background updates

### Entitlements File (`.entitlements`)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Required: base HealthKit entitlement -->
    <key>com.apple.developer.healthkit</key>
    <true/>
    
    <!-- Required: specify access types (empty array = general) -->
    <key>com.apple.developer.healthkit.access</key>
    <array/>
    
    <!-- Optional: enable background delivery -->
    <key>com.apple.developer.healthkit.background-delivery</key>
    <true/>
</dict>
</plist>
```

### Info.plist Keys

```xml
<!-- REQUIRED if reading health data -->
<key>NSHealthShareUsageDescription</key>
<string>YOUR_SHARE_DESCRIPTION_HERE</string>

<!-- REQUIRED if writing health data -->
<key>NSHealthUpdateUsageDescription</key>
<string>YOUR_UPDATE_DESCRIPTION_HERE</string>
```

Both keys must have non-empty, meaningful, user-facing descriptions. The app will crash at runtime if these are missing when you call `requestAuthorization`.

### If Using Background Delivery

Also add to Info.plist:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>processing</string>
</array>
```

### Summary Checklist

| Item | Key/Value | Required? |
|------|----------|----------|
| HealthKit capability | Xcode > Signing & Capabilities | **Yes** |
| Base entitlement | `com.apple.developer.healthkit` = `true` | **Yes** |
| Access types | `com.apple.developer.healthkit.access` = `[]` | **Yes** |
| Background delivery | `com.apple.developer.healthkit.background-delivery` = `true` | If using background updates |
| Health share description | `NSHealthShareUsageDescription` | If reading data |
| Health update description | `NSHealthUpdateUsageDescription` | If writing data |
| Background modes | `UIBackgroundModes` includes `processing` | If using background delivery |

---

## 5. Authorization Flow Best Practices

### Core Principles

1. **Always check availability first** — HealthKit is not available on iPad or Mac (Catalyst has limitations)
2. **Request only what you need** — each type is a separate toggle; requesting too many raises red flags
3. **Explain before prompting** — show an in-app screen explaining why before the system sheet
4. **Handle denial gracefully** — the app must work (in degraded mode) if the user denies everything
5. **Authorization is shown only once** — the system sheet won't re-appear; guide users to Settings > Health

### Full Authorization Implementation

```swift
import HealthKit

actor HealthKitAuthorizer {
    private let healthStore = HKHealthStore()
    
    // Define exactly what you need — no more
    private var readTypes: Set<HKObjectType> {
        let types: [HKObjectType?] = [
            HKQuantityType.quantityType(forIdentifier: .bodyMass),
            HKQuantityType.quantityType(forIdentifier: .stepCount),
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
            HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed),
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis),
        ]
        return Set(types.compactMap { $0 })
    }
    
    // Only request write for types you actually write
    private var writeTypes: Set<HKSampleType> {
        let types: [HKSampleType?] = [
            HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed),
        ]
        return Set(types.compactMap { $0 })
    }
    
    /// Check if HealthKit is available on this device
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    /// Request authorization — call after showing your explanation screen
    func requestAuthorization() async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }
        
        try await healthStore.requestAuthorization(
            toShare: writeTypes,
            read: readTypes
        )
    }
    
    /// Check authorization status for a specific type
    /// NOTE: For read types, HealthKit ALWAYS returns .notDetermined
    /// to protect user privacy. You cannot check if read was granted.
    func authorizationStatus(
        for type: HKObjectType
    ) -> HKAuthorizationStatus {
        healthStore.authorizationStatus(for: type)
    }
}

enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationDenied
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Health data is not available on this device."
        case .authorizationDenied:
            return "Please enable Health access in Settings."
        }
    }
}
```

### Critical Privacy Behavior

**You cannot determine if read authorization was granted or denied.** For privacy, HealthKit returns `.notDetermined` for read types regardless of the user's choice. If the user denies read access, queries simply return empty results — no error is thrown. Design your UI to handle empty data gracefully.

For **write** types, `authorizationStatus(for:)` correctly returns `.sharingAuthorized` or `.sharingDenied`.

### Pre-Authorization Explanation Screen

```swift
struct HealthAccessExplanationView: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)
            
            Text("Connect to Apple Health")
                .font(.title2.bold())
            
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "scalemass",
                    title: "Weight Tracking",
                    description: "See how fasting affects your weight over time"
                )
                FeatureRow(
                    icon: "flame",
                    title: "Calorie Insights",
                    description: "Track active calories during fasting windows"
                )
                FeatureRow(
                    icon: "figure.walk",
                    title: "Activity Correlation",
                    description: "Understand how steps relate to your fasting goals"
                )
            }
            
            Text("You can change these permissions anytime in Settings > Health.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Button("Continue") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

---

## 6. Background Delivery for Health Data Updates

Background delivery allows your app to be woken when new health data is written to the HealthKit store by other apps or devices.

### How It Works

1. You register an `HKObserverQuery` for a data type
2. You call `enableBackgroundDelivery(for:frequency:)` for that type
3. When new data is written (e.g., Apple Watch syncs steps), iOS wakes your app briefly
4. Your observer query handler fires, and you can fetch new data

### Frequency Options

| Frequency | Behavior |
|-----------|---------|
| `.immediate` | As soon as new data is available |
| `.hourly` | At most once per hour |
| `.daily` | At most once per day |

**Important:** iOS has full discretion to defer delivery based on battery, CPU usage, connectivity, and Low Power Mode. The actual delivery frequency can fluctuate, particularly for `.immediate`. Some data types are capped at `.hourly` maximum.

### Implementation

Background delivery **must** be set up in the app delegate or app initialization — not in a view:

```swift
import HealthKit

class HealthKitBackgroundManager {
    static let shared = HealthKitBackgroundManager()
    
    private let healthStore = HKHealthStore()
    private var observerQueries: [HKObserverQuery] = []
    
    /// Call this from AppDelegate.didFinishLaunchingWithOptions
    /// or from your @main App init
    func setupBackgroundDelivery() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let typesToObserve: [(HKSampleType, HKUpdateFrequency)] = [
            (HKQuantityType(.stepCount), .hourly),
            (HKQuantityType(.activeEnergyBurned), .hourly),
            (HKQuantityType(.bodyMass), .immediate),
        ]
        
        for (sampleType, frequency) in typesToObserve {
            enableBackgroundDelivery(for: sampleType, frequency: frequency)
        }
    }
    
    private func enableBackgroundDelivery(
        for sampleType: HKSampleType,
        frequency: HKUpdateFrequency
    ) {
        // 1. Create observer query
        let query = HKObserverQuery(
            sampleType: sampleType,
            predicate: nil
        ) { [weak self] query, completionHandler, error in
            if let error {
                print("Observer query error for \(sampleType): \(error)")
                completionHandler()
                return
            }
            
            // 2. Fetch the new data
            self?.handleNewData(for: sampleType) {
                // 3. MUST call completionHandler when done
                completionHandler()
            }
        }
        
        healthStore.execute(query)
        observerQueries.append(query)
        
        // 4. Enable background delivery
        healthStore.enableBackgroundDelivery(
            for: sampleType,
            frequency: frequency
        ) { success, error in
            if let error {
                print("Failed to enable background delivery: \(error)")
            }
        }
    }
    
    private func handleNewData(
        for sampleType: HKSampleType,
        completion: @escaping () -> Void
    ) {
        let query = HKSampleQuery(
            sampleType: sampleType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [
                NSSortDescriptor(
                    key: HKSampleSortIdentifierEndDate,
                    ascending: false
                )
            ]
        ) { _, results, _ in
            // Process new data (update local store, refresh UI, etc.)
            if let sample = results?.first {
                print("New \(sampleType.identifier): \(sample)")
            }
            completion()
        }
        healthStore.execute(query)
    }
}
```

### SwiftUI App Setup

```swift
@main
struct FastingApp: App {
    // Use UIApplicationDelegateAdaptor for background delivery setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        HealthKitBackgroundManager.shared.setupBackgroundDelivery()
        return true
    }
}
```

### Critical Rules

- **Always call `completionHandler()`** in the observer query — failing to do so causes iOS to stop waking your app
- Set up observer queries and `enableBackgroundDelivery` at app launch, not lazily
- Background delivery requires the `com.apple.developer.healthkit.background-delivery` entitlement
- The observer query tells you data changed, but doesn't include the new data — you must run a separate fetch query
- Only enable background delivery for types you actively use — battery impact is real

---

## 7. Privacy Requirements — Usage Description Strings

### Strings That Pass App Review

The usage descriptions must clearly explain **what** data you access and **why**. Generic strings get rejected.

#### NSHealthShareUsageDescription (Reading)

**Good examples for a fasting app:**

```
"[AppName] reads your weight, step count, and active calories from Apple Health to show how your fasting routine affects your health metrics over time."
```

```
"[AppName] accesses your health data including weight, activity, and nutrition information to provide personalized fasting insights and track your wellness progress."
```

**Bad examples (will likely trigger review questions):**

```
"This app needs access to your health data."          // Too vague
"To read health data."                                  // No explanation of why
"Required for app functionality."                       // Meaningless
"We need your health data to improve our service."     // Suspicious
```

#### NSHealthUpdateUsageDescription (Writing)

**Good example:**

```
"[AppName] saves your meal and nutrition data to Apple Health so it appears alongside your other health records and can be used by your other health apps."
```

**Bad example:**

```
"To write health data."   // Rejected — doesn't explain what or why
```

### Rules for Passing Review

1. **Be specific** about which data types you access
2. **Explain the user benefit** — what they get from sharing
3. **Match your actual usage** — don't say "steps" if you also read heart rate
4. **Don't mention HealthKit by name in the UI** — refer to it as "Apple Health" or "Health app"
5. **Keep it under ~2 sentences** — concise but complete

---

## 8. Common HealthKit Rejection Reasons & How to Avoid Them

### Rejection 1: "App uses HealthKit but does not include primary features" (Guideline 2.5.1)

**The most common HealthKit rejection.** Apple flags apps that include the HealthKit entitlement but don't visibly use health data as a core feature.

**How to avoid:**
- HealthKit data must be prominently displayed in your app's UI
- Don't include HealthKit just for unit conversions or convenience APIs
- The health integration should be central to the app, not a hidden settings toggle

### Rejection 2: "Does not clearly identify HealthKit functionality in UI" (Guideline 4.2.1)

Apple requires that health data integration is visible and understandable to users.

**How to avoid:**
- Show health data in the main app flow (dashboard, charts, insights)
- Have a clear "Health" or "Apple Health" section in settings
- Show what data is being read/written

### Rejection 3: "App description does not mention Health app integration"

Apple requires that your App Store description mentions the integration.

**How to avoid:**
- Include in your App Store description: "Integrates with the Health app to read/write [specific data types]"
- Don't use "HealthKit" — use "Health app" or "Apple Health"

### Rejection 4: Missing Privacy Policy

Apps using HealthKit **must** have a privacy policy — this is non-negotiable.

**How to avoid:**
- Provide a privacy policy URL in App Store Connect
- Make the privacy policy accessible within the app (e.g., Settings screen)
- The policy must specifically address health data collection, storage, and sharing

### Rejection 5: Requesting Unnecessary Permissions

Requesting read/write access to data types your app doesn't actually use.

**How to avoid:**
- Request only the minimum types needed
- If you only read, don't request write permission
- Each permission you request should map to a visible feature

### Rejection 6: Writing False or Incorrect Data

HealthKit rules explicitly prohibit writing false data.

**How to avoid:**
- Never write test/dummy data in production
- Validate data before writing (reasonable ranges for weight, calories, etc.)
- Don't write fasting data to unrelated HealthKit types (e.g., don't log a fast as a "mindful session")

### Rejection 7: Using Health Data for Advertising or Data Mining

HealthKit data must only be used for health/fitness/wellness purposes.

**How to avoid:**
- Never send HealthKit data to analytics/ad SDKs
- Never store HealthKit data in iCloud (Apple explicitly forbids this)
- Don't share health data with third parties without explicit consent

### Pre-Submission Checklist

- [ ] HealthKit entitlement added in Xcode capabilities
- [ ] `NSHealthShareUsageDescription` set with clear, specific text
- [ ] `NSHealthUpdateUsageDescription` set (if writing data)
- [ ] Health data is prominently shown in app UI
- [ ] App Store description mentions "Health app" integration
- [ ] Privacy policy exists, is accessible in-app, and mentions health data
- [ ] Only minimum required data types are requested
- [ ] No HealthKit data sent to analytics, ads, or iCloud
- [ ] App works in degraded mode if user denies permissions
- [ ] Demo account or review notes provided if health features need data to show

---

## 9. HealthKit + SwiftUI Integration Patterns

### Architecture: HealthKitManager + @Observable ViewModel

The recommended pattern separates HealthKit interaction (manager) from UI state (view model).

#### HealthKitManager (Data Layer)

```swift
import HealthKit
import Observation

@Observable
final class HealthKitManager {
    static let shared = HealthKitManager()
    
    let healthStore = HKHealthStore()
    
    var isAuthorized = false
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    private init() {}
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }
        
        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.bodyMass),
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.dietaryEnergyConsumed),
        ]
        
        let writeTypes: Set<HKSampleType> = [
            HKQuantityType(.dietaryEnergyConsumed),
        ]
        
        try await healthStore.requestAuthorization(
            toShare: writeTypes,
            read: readTypes
        )
        isAuthorized = true
    }
    
    // MARK: - Queries
    
    func fetchTodaySteps() async throws -> Int {
        let stepType = HKQuantityType(.stepCount)
        let predicate = todayPredicate()
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let steps = Int(
                    stats?.sumQuantity()?
                        .doubleValue(for: .count()) ?? 0
                )
                continuation.resume(returning: steps)
            }
            healthStore.execute(query)
        }
    }
    
    func fetchTodayActiveCalories() async throws -> Double {
        let energyType = HKQuantityType(.activeEnergyBurned)
        let predicate = todayPredicate()
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let cals = stats?.sumQuantity()?
                    .doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: cals)
            }
            healthStore.execute(query)
        }
    }
    
    func fetchLatestWeight() async throws -> Double? {
        let bodyMassType = HKQuantityType(.bodyMass)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [
                    NSSortDescriptor(
                        key: HKSampleSortIdentifierEndDate,
                        ascending: false
                    )
                ]
            ) { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let weight = (results?.first as? HKQuantitySample)?
                    .quantity
                    .doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: weight)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Helpers
    
    private func todayPredicate() -> NSPredicate {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictStartDate
        )
    }
}
```

#### ViewModel (Presentation Layer)

```swift
import Observation

@Observable
final class FastingDashboardViewModel {
    private let healthKit = HealthKitManager.shared
    
    var todaySteps: Int = 0
    var todayCalories: Double = 0
    var currentWeight: Double?
    var isLoading = false
    var errorMessage: String?
    
    func loadHealthData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await healthKit.requestAuthorization()
            
            // Fetch all data concurrently
            async let steps = healthKit.fetchTodaySteps()
            async let calories = healthKit.fetchTodayActiveCalories()
            async let weight = healthKit.fetchLatestWeight()
            
            todaySteps = try await steps
            todayCalories = try await calories
            currentWeight = try await weight
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
```

#### SwiftUI View

```swift
import SwiftUI

struct FastingDashboardView: View {
    @State private var viewModel = FastingDashboardViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Fasting timer (your local data)
                    FastingTimerCard()
                    
                    // Health metrics from HealthKit
                    if viewModel.isLoading {
                        ProgressView("Loading health data...")
                    } else {
                        healthMetricsSection
                    }
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .task {
                await viewModel.loadHealthData()
            }
            .refreshable {
                await viewModel.loadHealthData()
            }
        }
    }
    
    @ViewBuilder
    private var healthMetricsSection: some View {
        VStack(spacing: 12) {
            Text("Today's Health")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ],
                spacing: 12
            ) {
                MetricCard(
                    icon: "figure.walk",
                    title: "Steps",
                    value: "\(viewModel.todaySteps.formatted())",
                    color: .green
                )
                
                MetricCard(
                    icon: "flame.fill",
                    title: "Active Cal",
                    value: "\(Int(viewModel.todayCalories)) kcal",
                    color: .orange
                )
                
                if let weight = viewModel.currentWeight {
                    MetricCard(
                        icon: "scalemass",
                        title: "Weight",
                        value: String(format: "%.1f kg", weight),
                        color: .blue
                    )
                }
            }
        }
    }
}

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3.bold())
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

### Key SwiftUI Patterns

| Pattern | Usage |
|---------|-------|
| `@Observable` (iOS 17+) | Preferred for HealthKitManager and ViewModels |
| `@ObservableObject` + `@Published` | Fallback for iOS 16 support |
| `.task { }` modifier | Trigger async HealthKit queries when view appears |
| `.refreshable { }` | Pull-to-refresh for health data |
| `async let` | Concurrent fetching of multiple health metrics |
| `@UIApplicationDelegateAdaptor` | Required for background delivery setup |
| Singleton `HealthKitManager.shared` | Single `HKHealthStore` instance across app |

### Important: One HKHealthStore

Apple recommends creating a single `HKHealthStore` instance for the entire app. The singleton pattern in `HealthKitManager.shared` follows this guidance. Don't create new `HKHealthStore()` instances in views or view models.

---

## 10. Sources

1. Apple Developer Documentation — HealthKit: https://developer.apple.com/documentation/healthkit
2. Apple Developer Documentation — HKCategoryTypeIdentifier: https://developer.apple.com/documentation/healthkit/hkcategorytypeidentifier
3. Apple Developer Documentation — HKQuantityTypeIdentifier: https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier
4. Apple Developer Documentation — Background Delivery entitlement: https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.healthkit.background-delivery
5. Apple Developer Documentation — enableBackgroundDelivery: https://developer.apple.com/documentation/HealthKit/HKHealthStore/enableBackgroundDelivery(for:frequency:withCompletion:)
6. WWDC25 — Track workouts with HealthKit on iOS and iPadOS: https://developer.apple.com/videos/play/wwdc2025/322/
7. "Apple HealthKit in iOS (2026): The Complete Swift Guide" — Medium (Feb 2026): https://medium.com/@garejakirit/apple-healthkit-in-ios-2026-the-complete-swift-guide-step-by-step-0d4215b54412
8. "Reading data from HealthKit in a SwiftUI app" — Create with Swift: https://www.createwithswift.com/reading-data-from-healthkit-in-a-swiftui-app/
9. "Architecting a Modular HealthKit Manager in Swift" — Apps 2 Develop: https://medium.com/apps-2-develop/architecting-a-modular-healthkit-manager-in-swift-72bddef5573d
10. Apple Developer Forums — HealthKit rejection discussions: https://developer.apple.com/forums/thread/28627
11. Junction SDK — Apple HealthKit Background Delivery guide: https://docs.junction.com/wearables/guides/apple-healthkit
12. App Store Review Guidelines checklist (2025/2026): https://nextnative.dev/blog/app-store-review-guidelines
