# SwiftData + CloudKit Sync Research (2025–2026)

> **Last updated:** March 2026  
> **iOS targets:** iOS 17+ (SwiftData minimum), iOS 18+ recommended for stability  
> **Key WWDC sessions:** WWDC23 "Meet SwiftData", WWDC23 "Model your schema with SwiftData", WWDC23 "Sync to iCloud with CKSyncEngine", WWDC25 "SwiftData: Dive into inheritance and schema migration"

---

## Table of Contents

1. [SwiftData Basics](#1-swiftdata-basics)
2. [CloudKit Sync with SwiftData](#2-cloudkit-sync-with-swiftdata)
3. [Offline-First Architecture](#3-offline-first-architecture)
4. [Conflict Resolution Strategies](#4-conflict-resolution-strategies)
5. [Migration Strategies](#5-migration-strategies)
6. [Performance with Large Datasets](#6-performance-with-large-datasets)
7. [CloudKit Container Setup & Entitlements](#7-cloudkit-container-setup--entitlements)
8. [Testing CloudKit Sync Locally](#8-testing-cloudkit-sync-locally)
9. [Known Limitations & Gotchas (2025)](#9-known-limitations--gotchas-2025)
10. [SwiftData vs Core Data + CloudKit](#10-swiftdata-vs-core-data--cloudkit)

---

## 1. SwiftData Basics

SwiftData was introduced at WWDC 2023 (iOS 17) as Apple's modern, declarative persistence framework built on top of Core Data. It replaces `.xcdatamodeld` files with pure Swift code using macros.

### Core Concepts

#### @Model Macro

The `@Model` macro transforms a Swift class into a persistable entity. It generates the backing store, change tracking, and observation conformance.

```swift
import SwiftData

@Model
class FastingRecord {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    var targetHours: Double
    var notes: String
    var mood: Int  // 1-5 scale
    
    // Computed (not persisted)
    @Transient
    var isActive: Bool {
        endDate == nil
    }
    
    init(
        id: UUID = UUID(),
        startDate: Date = .now,
        endDate: Date? = nil,
        targetHours: Double = 16.0,
        notes: String = "",
        mood: Int = 3
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.targetHours = targetHours
        self.notes = notes
        self.mood = mood
    }
}
```

Key macros:
- **`@Attribute(.unique)`** — enforces uniqueness (NOT compatible with CloudKit sync)
- **`@Attribute(.externalStorage)`** — stores large data (images, blobs) externally for lazy loading
- **`@Attribute(.spotlight)`** — indexes for Spotlight search
- **`@Relationship`** — defines relationships with delete rules and inverse specification
- **`@Transient`** — excludes property from persistence (must have default value)

#### ModelContainer

The `ModelContainer` manages the database schema and backing store. Created once, typically at app launch.

```swift
@main
struct FastingApp: App {
    let container: ModelContainer
    
    init() {
        let schema = Schema([FastingRecord.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic  // Enable CloudKit sync
        )
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
```

`ModelConfiguration` options for CloudKit:
- `.automatic` — inspects entitlements, uses first CloudKit container found
- `.private("iCloud.com.yourapp.identifier")` — specifies exact container
- `.none` — disables CloudKit sync entirely

#### ModelContext

The `ModelContext` is the workspace for creating, reading, updating, and deleting model objects. It tracks changes and commits them to the store.

```swift
struct FastingListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FastingRecord.startDate, order: .reverse)
    private var records: [FastingRecord]
    
    func startNewFast() {
        let record = FastingRecord(targetHours: 16.0)
        context.insert(record)
        // Autosave handles persistence, or call:
        // try? context.save()
    }
    
    func deleteRecord(_ record: FastingRecord) {
        context.delete(record)
    }
}
```

Key `ModelContext` operations:
- `insert(_:)` — adds a new object
- `delete(_:)` — marks for deletion
- `save()` — persists pending changes (autosave is on by default)
- `fetch(_:)` — executes a `FetchDescriptor`
- `enumerate(_:)` — memory-efficient iteration over large result sets

#### @Query Macro

The `@Query` macro in SwiftUI views provides live, auto-updating results:

```swift
// Simple query with sort
@Query(sort: \FastingRecord.startDate, order: .reverse)
private var allRecords: [FastingRecord]

// Filtered query with predicate
@Query(filter: #Predicate<FastingRecord> { $0.endDate != nil },
       sort: \FastingRecord.startDate)
private var completedFasts: [FastingRecord]

// With fetch limit for performance
@Query(sort: \FastingRecord.startDate, order: .reverse)
private var recentRecords: [FastingRecord]
// Use FetchDescriptor for limits in non-view code
```

---

## 2. CloudKit Sync with SwiftData

### Two Approaches

There are two fundamentally different ways to sync SwiftData with CloudKit:

#### Approach A: Automatic Sync via ModelContainer (Recommended for most apps)

SwiftData's built-in CloudKit integration uses `NSPersistentCloudKitContainer` under the hood. Zero sync code required — just configure the container and entitlements.

```swift
let config = ModelConfiguration(
    schema: schema,
    cloudKitDatabase: .automatic
)
let container = try ModelContainer(for: schema, configurations: [config])
```

**Pros:** Zero sync code, handles push notifications, change tokens, and merging automatically.  
**Cons:** No control over sync timing, only supports private database, no shared/public database access, silent failures.

#### Approach B: SwiftData + CKSyncEngine (For fine-grained control)

`CKSyncEngine` (introduced iOS 17) gives you control over when and how data syncs while handling the difficult parts (scheduling, batching, retry). You use SwiftData for local persistence and CKSyncEngine as a separate sync layer.

```swift
// SyncManager coordinates SwiftData and CKSyncEngine
@MainActor
final class SyncManager: ObservableObject {
    private let ckContainer: CKContainer
    private var syncEngine: CKSyncEngine?
    private let modelContainer: ModelContainer
    
    @Published private(set) var syncStatus: SyncStatus = .idle
    
    enum SyncStatus { case idle, syncing, error }
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.ckContainer = CKContainer(identifier: "iCloud.com.yourapp")
    }
    
    func setupSyncEngine() {
        let config = CKSyncEngine.Configuration(
            database: ckContainer.privateCloudDatabase,
            stateSerialization: loadSyncState(),
            delegate: self
        )
        syncEngine = CKSyncEngine(config)
    }
}

extension SyncManager: CKSyncEngineDelegate {
    func handleEvent(_ event: CKSyncEngine.Event, 
                     syncEngine: CKSyncEngine) async {
        switch event {
        case .stateUpdate(let update):
            saveSyncEngineState(update.stateSerialization)
        case .fetchedRecordZoneChanges(let changes):
            await handleFetchedChanges(changes)
        case .sentRecordZoneChanges(let results):
            await handleSentChanges(results)
        case .accountChange(let event):
            handleAccountChange(event)
        default:
            break
        }
    }
    
    func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        let pending = syncEngine.state.pendingRecordZoneChanges
            .filter { context.options.scope.contains($0) }
        guard !pending.isEmpty else { return nil }
        return await CKSyncEngine.RecordZoneChangeBatch(
            pendingChanges: pending
        ) { recordID in
            return await self.buildCKRecord(for: recordID)
        }
    }
}
```

**Note:** Apple confirmed that CKSyncEngine can be used with SwiftData for local storage, but as of 2025 there is no official sample project combining the two. Apple's sample uses a JSON file for local storage.

> **Recommendation for a fasting app:** Start with Approach A (automatic sync). It's sufficient for private user data with thousands of records. Only move to CKSyncEngine if you need shared databases, sync progress UI, or manual sync triggers.

---

## 3. Offline-First Architecture

SwiftData is inherently offline-first. All data is persisted locally in SQLite, and CloudKit sync is layered on top. The app works fully without network.

### Architecture Pattern

```
┌─────────────────────────────────┐
│          SwiftUI Views          │
│    (@Query, @Environment)       │
├─────────────────────────────────┤
│        ModelContext              │
│    (insert, delete, save)       │
├─────────────────────────────────┤
│        ModelContainer           │
│    (local SQLite store)         │
├─────────────────────────────────┤
│   NSPersistentCloudKitContainer │
│   (automatic background sync)  │
├─────────────────────────────────┤
│        CloudKit (iCloud)        │
│    (when network available)     │
└─────────────────────────────────┘
```

### Key Behaviors

1. **Writes are always local first.** `context.insert()` and `context.save()` write to SQLite immediately. No network required.
2. **Sync happens in the background.** The system pushes local changes when connectivity is available, and pulls remote changes via push notifications.
3. **No explicit online/offline modes needed.** The framework handles this transparently.

### Handling Network State (Optional UI Feedback)

If you want to show sync status in the UI:

```swift
import Network

@Observable
class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    var isConnected: Bool = true
    var connectionType: NWInterface.InterfaceType? = nil
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces
                    .first?.type
            }
        }
        monitor.start(queue: queue)
    }
}
```

### Detecting CloudKit Sync Events

To know when remote data has arrived (e.g., to refresh UI):

```swift
// Listen for CloudKit import events
.onReceive(
    NotificationCenter.default.publisher(
        for: NSPersistentCloudKitContainer.eventChangedNotification
    )
) { notification in
    guard let event = notification.userInfo?[
        NSPersistentCloudKitContainer.eventNotificationUserInfoKey
    ] as? NSPersistentCloudKitContainer.Event else { return }
    
    if event.endDate != nil && event.type == .import {
        // Remote data has been imported — UI will auto-update
        // via @Query, but you can trigger additional logic here
    }
}
```

---

## 4. Conflict Resolution Strategies

### Automatic Sync (ModelContainer + CloudKit)

When using SwiftData's built-in CloudKit sync, conflict resolution is handled automatically with a **last-writer-wins** strategy at the record level. This is the same behavior as `NSPersistentCloudKitContainer` in Core Data.

- If Device A and Device B both edit the same record offline, whichever change reaches the server last "wins"
- This is per-record, not per-field — the entire record is replaced
- There is no built-in merge or user-facing conflict resolution UI

### CKSyncEngine (Manual Conflict Handling)

With CKSyncEngine, you get explicit conflict callbacks when `serverRecordChanged` errors occur:

```swift
private func handleSentChanges(
    _ results: CKSyncEngine.Event.SentRecordZoneChanges
) {
    for failedSave in results.failedRecordSaves {
        switch failedSave.error.code {
        case .serverRecordChanged:
            // Conflict! Server has a newer version
            if let serverRecord = failedSave.error.serverRecord {
                resolveConflict(
                    client: failedSave.record,
                    server: serverRecord
                )
            }
        case .zoneNotFound:
            // Zone was deleted, recreate it
            break
        case .networkFailure, .networkUnavailable:
            // Auto-retry handled by CKSyncEngine
            break
        default:
            break
        }
    }
}

private func resolveConflict(
    client: CKRecord,
    server: CKRecord
) {
    // Strategy 1: Last-writer-wins (simplest)
    // Just re-save the client record with the server's change tag
    
    // Strategy 2: Field-level merge (more sophisticated)
    let merged = server  // Start with server version
    
    // Compare modification dates per field and keep the newer one
    if let clientDate = client["modifiedAt"] as? Date,
       let serverDate = server["modifiedAt"] as? Date,
       clientDate > serverDate {
        // Client is newer, apply client fields
        merged["notes"] = client["notes"]
        merged["mood"] = client["mood"]
    }
    
    // Strategy 3: Additive merge (for append-only data)
    // Combine both versions (e.g., merge arrays, sum counters)
    
    // Re-queue the merged record for upload
    syncEngine?.state.add(pendingRecordZoneChanges: [
        .saveRecord(merged.recordID)
    ])
}
```

### Practical Strategies for a Fasting App

For fasting records, conflicts are rare (records are typically created and completed on one device). Recommended approach:

1. **Use UUID-based IDs** — avoids insert conflicts
2. **Include a `lastModifiedAt` timestamp** — enables field-level merge if needed
3. **Treat completed fasts as immutable** — once `endDate` is set, don't allow edits (eliminates most conflict scenarios)
4. **For active fasts, last-writer-wins is acceptable** — there's only one active fast at a time

---

## 5. Migration Strategies

SwiftData uses `VersionedSchema` and `SchemaMigrationPlan` for schema evolution.

### Lightweight Migration

Simple changes that SwiftData handles automatically:
- Adding a new property **with a default value**
- Removing a property
- Renaming a property (with `@Attribute(originalName:)`)

```swift
// V1 → V2: Rename a property
@Model class FastingRecord {
    // Was: var fastDuration: Double
    @Attribute(originalName: "fastDuration")
    var targetHours: Double = 16.0
}
```

### Versioned Schema Setup

```swift
enum FastingSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [FastingRecord.self]
    }
    
    @Model
    class FastingRecord {
        var id: UUID = UUID()
        var startDate: Date = Date.now
        var endDate: Date?
        var targetHours: Double = 16.0
        var notes: String = ""
        
        init(startDate: Date = .now, targetHours: Double = 16.0) {
            self.id = UUID()
            self.startDate = startDate
            self.targetHours = targetHours
            self.notes = ""
        }
    }
}

enum FastingSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [FastingRecord.self]
    }
    
    @Model
    class FastingRecord {
        var id: UUID = UUID()
        var startDate: Date = Date.now
        var endDate: Date?
        var targetHours: Double = 16.0
        var notes: String = ""
        var mood: Int = 3        // NEW in V2
        var fastType: String = "intermittent"  // NEW in V2
        
        init(startDate: Date = .now, targetHours: Double = 16.0) {
            self.id = UUID()
            self.startDate = startDate
            self.targetHours = targetHours
            self.notes = ""
            self.mood = 3
            self.fastType = "intermittent"
        }
    }
}
```

### Migration Plan

```swift
enum FastingMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [FastingSchemaV1.self, FastingSchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    // Lightweight: just adding properties with defaults
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: FastingSchemaV1.self,
        toVersion: FastingSchemaV2.self
    )
}

// Use in ModelContainer
let container = try ModelContainer(
    for: FastingSchemaV2.FastingRecord.self,
    migrationPlan: FastingMigrationPlan.self
)
```

### Custom (Heavyweight) Migration

For complex changes (splitting properties, transforming data):

```swift
static let migrateV2toV3 = MigrationStage.custom(
    fromVersion: FastingSchemaV2.self,
    toVersion: FastingSchemaV3.self,
    willMigrate: { context in
        // Access OLD model here
        // Good for: reading data you need before schema changes
    },
    didMigrate: { context in
        // Access NEW model here
        // Good for: populating new fields from old data
        let records = try context.fetch(
            FetchDescriptor<FastingSchemaV3.FastingRecord>()
        )
        for record in records {
            // e.g., populate a new computed field
            if let end = record.endDate {
                record.actualHours = end.timeIntervalSince(
                    record.startDate
                ) / 3600.0
            }
        }
        try context.save()
    }
)
```

### Migration Gotcha with CloudKit

**Critical:** When using CloudKit sync, schema changes must be **additive only** in the CloudKit schema. You can:
- Add new record types
- Add new fields to existing record types

You **cannot**:
- Remove fields from CloudKit (they'll just be nil)
- Rename fields in CloudKit (treated as new field + removed field)

Your local SwiftData migration handles the local store, but the CloudKit schema has different constraints. Always test migrations with CloudKit enabled.

### Best Practice: Start with VersionedSchema from Day 1

Multiple developers have reported painful experiences trying to add `VersionedSchema` to an existing unversioned SwiftData project. Start versioned from the first release.

---

## 6. Performance with Large Datasets

### Known Performance Characteristics

SwiftData is built on Core Data's SQLite engine, but the `@Model` macro adds overhead:

- **Object creation is slower than Core Data.** Developers have reported 30x slowdowns creating 30K `@Model` instances vs. plain Swift classes (90s vs. 3s). This is due to the runtime observation and tracking infrastructure the macro generates.
- **`@Query` loads all matching objects.** There's no built-in pagination in `@Query`. For views, all matched objects are loaded into memory.
- **Relationships are lazily loaded.** SwiftData loads relationship data only when accessed, which is good for memory but can cause N+1 fetch patterns.
- **Main thread by default.** `@Query` and `ModelContext` from the environment run on the main thread.

### Optimization Strategies for Thousands of Records

For a fasting app with thousands of records (realistic: ~1000–5000 over years of daily use):

#### 1. Use Predicates to Limit Data

```swift
// Don't load all records — filter at the database level
let oneMonthAgo = Calendar.current.date(
    byAdding: .month, value: -1, to: .now
)!

@Query(
    filter: #Predicate<FastingRecord> { $0.startDate > oneMonthAgo },
    sort: \FastingRecord.startDate,
    order: .reverse
)
private var recentRecords: [FastingRecord]
```

#### 2. Use FetchDescriptor with Limits

```swift
func fetchRecentRecords(limit: Int = 50) throws -> [FastingRecord] {
    var descriptor = FetchDescriptor<FastingRecord>(
        sortBy: [SortDescriptor(\.startDate, order: .reverse)]
    )
    descriptor.fetchLimit = limit
    return try context.fetch(descriptor)
}
```

#### 3. Use @ModelActor for Background Work

```swift
@ModelActor
actor FastingDataService {
    // Runs on a background thread automatically
    
    func computeStatistics() -> FastingStats {
        let descriptor = FetchDescriptor<FastingRecord>(
            predicate: #Predicate { $0.endDate != nil }
        )
        let records = try! modelContext.fetch(descriptor)
        
        // Heavy computation off main thread
        let totalFasts = records.count
        let avgDuration = records.compactMap { record -> Double? in
            guard let end = record.endDate else { return nil }
            return end.timeIntervalSince(record.startDate) / 3600
        }.reduce(0, +) / Double(max(totalFasts, 1))
        
        return FastingStats(
            totalFasts: totalFasts,
            averageHours: avgDuration
        )
    }
}

// Usage
let service = FastingDataService(modelContainer: container)
let stats = await service.computeStatistics()
```

#### 4. External Storage for Large Data

```swift
@Model
class FastingRecord {
    // ... other properties
    
    @Attribute(.externalStorage)
    var photo: Data?  // Stored externally, loaded on demand
}
```

#### 5. Use enumerate() for Memory-Efficient Iteration

```swift
// For batch processing without loading everything into memory
let descriptor = FetchDescriptor<FastingRecord>()
try context.enumerate(descriptor, batchSize: 100) { record in
    // Process one at a time, memory is reclaimed per batch
}
```

#### 6. Prefetch Relationships

```swift
var descriptor = FetchDescriptor<FastingRecord>()
descriptor.relationshipKeyPathsForPrefetching = [\.tags]
let records = try context.fetch(descriptor)
// Tags are loaded in one pass instead of N+1 queries
```

### Realistic Assessment for Fasting App

With ~1000–5000 fasting records (simple flat records, no images, no deep relationships), SwiftData performance should be **perfectly adequate**. The performance issues reported in forums involve either:
- Massive bulk inserts (30K+ records)
- Storing large binary data inline (not using external storage)
- Loading everything into memory without predicates

A fasting app won't hit these patterns.

---

## 7. CloudKit Container Setup & Entitlements

### Step-by-Step Setup

#### Prerequisites
- Active Apple Developer Program membership ($99/year)
- A real device for testing (simulators don't support push notifications for sync)

#### 1. Add iCloud Capability

In Xcode → Target → Signing & Capabilities → + Capability → iCloud:

- Check **CloudKit**
- Press **+** to add a container: `iCloud.com.yourcompany.yourapp`

> **Warning:** Once you create a CloudKit container, it cannot be deleted. Choose the identifier carefully.

#### 2. Add Background Modes

In Xcode → Target → Signing & Capabilities → + Capability → Background Modes:

- Check **Remote Notifications**

This allows the app to be notified when data changes on other devices.

#### 3. Entitlements File

Xcode auto-generates `YourApp.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>development</string>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.yourcompany.yourapp</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
</dict>
</plist>
```

#### 4. Configure ModelContainer

```swift
let schema = Schema([FastingRecord.self])
let config = ModelConfiguration(
    schema: schema,
    cloudKitDatabase: .automatic
    // or: .private("iCloud.com.yourcompany.yourapp")
)
let container = try ModelContainer(
    for: schema,
    configurations: [config]
)
```

#### 5. CloudKit Console

Access at [https://icloud.developer.apple.com](https://icloud.developer.apple.com):
- View your container's record types and records
- Query the private database per-user (use sandbox iCloud accounts)
- Monitor Telemetry, Alerts, and Logs (added in 2024)
- Inspect the `com.apple.coredata.cloudkit.zone` zone for your synced records

### Container Architecture

```
CKContainer ("iCloud.com.yourcompany.yourapp")
└── CKDatabase (private — per user)
    └── CKRecordZone ("com.apple.coredata.cloudkit.zone")
        └── CKRecords (one per @Model instance)
```

SwiftData + CloudKit only supports the **private database**. For shared or public data, you must use Core Data + `NSPersistentCloudKitContainer` or raw CKSyncEngine.

---

## 8. Testing CloudKit Sync Locally

### Challenges

CloudKit sync testing is notoriously difficult:
- Simulators don't receive push notifications (sync is push-driven)
- Sync timing is non-deterministic
- You need two devices signed into the same iCloud account
- CloudKit has throttle limits that can affect testing

### Strategies

#### 1. Test on Real Devices (Primary Method)

Use two physical devices signed into the same Apple ID:
1. Install the app on both devices
2. Create data on Device A
3. Wait 5–30 seconds for sync
4. Verify data appears on Device B

For development, use a **sandbox iCloud account** (create in App Store Connect → Users → Sandbox Testers).

#### 2. Use CloudKit Console for Verification

After creating data on a device:
1. Open CloudKit Console
2. Select your container → Private Database
3. Select the `com.apple.coredata.cloudkit.zone`
4. Query records to verify they were uploaded

#### 3. Monitor Xcode Console Logs

CloudKit sync produces verbose logging. Filter Xcode console for:
- `CoreData+CloudKit` — sync activity
- `CKError` — sync failures
- `NSPersistentCloudKitContainer` — event notifications

```swift
// Enable verbose CloudKit logging (add to scheme environment variables)
// com.apple.CoreData.CloudKitDebug = 1
```

#### 4. Unit Test with In-Memory Stores

For testing your data layer (not sync itself):

```swift
func makeTestContainer() throws -> ModelContainer {
    let config = ModelConfiguration(
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none  // Disable CloudKit for unit tests
    )
    return try ModelContainer(
        for: FastingRecord.self,
        configurations: [config]
    )
}

@Test
func testCreateFastingRecord() throws {
    let container = try makeTestContainer()
    let context = ModelContext(container)
    
    let record = FastingRecord(targetHours: 18.0)
    context.insert(record)
    try context.save()
    
    let fetched = try context.fetch(FetchDescriptor<FastingRecord>())
    #expect(fetched.count == 1)
    #expect(fetched.first?.targetHours == 18.0)
}
```

#### 5. Test CKSyncEngine with Simulated Environments

Apple's [sample-cloudkit-sync-engine](https://github.com/apple/sample-cloudkit-sync-engine) project includes `SyncTests.swift` demonstrating how to simulate multi-device sync:

```swift
// From Apple's sample — simulates two devices syncing
func testTwoDevicesSync() async throws {
    let deviceA = try SyncedDatabase(...)
    let deviceB = try SyncedDatabase(...)
    
    // Device A adds a contact
    await deviceA.addContact(name: "Alice")
    
    // Simulate sync: A sends → server → B fetches
    try await deviceA.syncEngine.sendChanges()
    try await deviceB.syncEngine.fetchChanges()
    
    // Verify B received it
    let contacts = await deviceB.allContacts()
    XCTAssertEqual(contacts.count, 1)
}
```

#### 6. Integration Test Checklist

- [ ] Create record on Device A → appears on Device B
- [ ] Edit record on Device A → updates on Device B
- [ ] Delete record on Device A → removed from Device B
- [ ] Create record offline → syncs when back online
- [ ] App reinstall → data recovers from iCloud
- [ ] Sign out of iCloud → app still works (local data intact)
- [ ] Sign into different iCloud account → sees that account's data

---

## 9. Known Limitations & Gotchas (2025)

### CloudKit Model Requirements (Silent Failures!)

These requirements are **enforced silently** — your app will work locally but sync will fail with no user-facing error:

1. **All properties must have default values or be optional.** Non-optional properties without defaults will prevent sync.
2. **All relationships must be optional.** Required relationships break sync.
3. **`@Attribute(.unique)` is NOT supported with CloudKit.** Unique constraints prevent sync entirely.
4. **All relationships must have an inverse.** One-way relationships cause sync errors.

```swift
// ❌ WRONG — will break CloudKit sync silently
@Model class FastingRecord {
    var startDate: Date           // No default!
    @Attribute(.unique) var id: UUID  // Unique not supported!
    var tags: [Tag]               // Non-optional relationship!
}

// ✅ CORRECT — CloudKit compatible
@Model class FastingRecord {
    var startDate: Date = Date.now
    var id: UUID = UUID()         // Default value, no .unique
    @Relationship(inverse: \Tag.record)
    var tags: [Tag]? = []         // Optional with inverse
}
```

### Stability Issues

- **iOS 17 → iOS 18 regression:** SwiftData underwent a major internal refactoring in iOS 18 (shifting from tight Core Data coupling to supporting custom stores). Code that worked on iOS 17 broke on iOS 18 for many developers.
- **Random crashes with deleted objects:** Accessing properties on a deleted SwiftData model object crashes at runtime, and Swift doesn't provide safe workarounds once data is in a bad state.
- **`ModelContainer` creation can crash:** Some developers report `fatalError`-level crashes during container creation even when using `try`/`catch`, particularly related to CloudKit schema validation.

### Sync-Specific Gotchas

- **Private database only.** SwiftData + CloudKit does not support shared or public CloudKit databases. For multi-user collaboration, you must use Core Data or CKSyncEngine directly.
- **No sync progress API.** There's no way to show sync progress or know when sync is complete with automatic sync.
- **First sync can be slow.** When a user installs on a new device, the initial sync of all historical data can take minutes.
- **Simulator testing is unreliable.** Push notifications don't work in the simulator, so sync testing requires real devices.
- **CloudKit containers can't be deleted.** Once created, a container identifier is permanent. Use a sensible naming convention.

### SwiftData-Specific Gotchas

- **No custom indexing.** SwiftData doesn't expose the ability to create database indexes on specific columns. (iOS 26 may add `@Attribute(.index)`)
- **@Query is main-thread only.** Heavy queries on `@Query` will block the UI.
- **Autosave can silently fail.** The automatic saving mechanism occasionally fails without throwing errors.
- **`cloudKitDatabase: .none` had bugs.** Setting the database to `.none` was supposed to disable sync, but in some iOS versions it still attempted to sync (crashing on non-CloudKit-compatible models). This was mostly fixed by iOS 17.2.
- **Bulk inserts are slow.** Creating thousands of `@Model` objects has significant per-object overhead compared to Core Data.
- **No `NSFetchedResultsController` equivalent.** The `@Query` macro is the only built-in way to observe changes; there's no sectioned results controller.

### iOS 26 (WWDC 2025) Additions

- **Class inheritance support.** `@Model` classes can now use class inheritance (subclasses). This is the only major new feature added in iOS 26.
- **No new sync features.** Shared and public database support was not added. Dynamic predicate adjustment was not added.

---

## 10. SwiftData vs Core Data + CloudKit

### Current State (2025–2026)

| Feature | SwiftData + CloudKit | Core Data + CloudKit |
|---|---|---|
| Setup effort | Minimal (add capabilities, done) | Moderate (NSPersistentCloudKitContainer) |
| Code required | Near-zero for basic sync | More boilerplate, but well-documented |
| Private database | ✅ | ✅ |
| Shared database | ❌ | ✅ |
| Public database | ❌ | ✅ (with raw CloudKit) |
| Sync progress | ❌ No API | ✅ Via event notifications |
| Conflict resolution | Last-writer-wins (automatic) | Last-writer-wins (automatic) + custom |
| Schema migration | VersionedSchema (newer, less proven) | NSMappingModel (mature, well-tested) |
| Performance (large data) | Slower for bulk operations | Faster, more optimized |
| Stability (2025) | Improved but still has edge cases | Battle-tested, very stable |
| SwiftUI integration | Excellent (@Query, @Model) | Good (via @FetchRequest) |
| Minimum iOS | iOS 17 | iOS 13+ |
| Future investment | Apple's primary focus | Maintenance mode (no new features) |

### Honest Assessment

**SwiftData reliability** has improved significantly from iOS 17 → iOS 18 → iOS 18.x, but developers in the community still report edge-case crashes and sync issues that don't exist with Core Data. As one widely-cited developer noted, many "serious" use cases end with developers returning to Core Data + CloudKit after consulting with Apple DTS.

**Core Data + CloudKit** is more reliable today, has been battle-tested for years, supports shared databases, and has more robust migration tooling. But it requires significantly more boilerplate and doesn't integrate as cleanly with SwiftUI.

### Recommendation for a Fasting App

**Use SwiftData + CloudKit automatic sync.** Here's why:

1. **Simple data model.** A fasting record is a flat model with no complex relationships. This is SwiftData's sweet spot.
2. **Private data only.** Users sync their own fasting data across their own devices. No sharing needed.
3. **Moderate data volume.** Thousands of records is well within SwiftData's comfortable range.
4. **New project.** No legacy Core Data code to maintain.
5. **SwiftUI-first.** `@Query` and `@Model` integrate beautifully with SwiftUI views.

**Mitigations:**
- Start with `VersionedSchema` from day 1
- Make all properties CloudKit-compatible from the start (defaults, optional relationships)
- Target iOS 18+ minimum to avoid iOS 17 bugs
- Test on real devices early and often
- Keep a fallback plan: if SwiftData sync proves unreliable, you can disable CloudKit sync (`cloudKitDatabase: .none`) and add CKSyncEngine as a separate layer without rewriting your models

---

## Sources

1. [Hacking with Swift — Syncing SwiftData with CloudKit](https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit)
2. [Hacking with Swift — How to sync SwiftData with iCloud](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-sync-swiftdata-with-icloud)
3. [Hacking with Swift — Optimize SwiftData performance](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-optimize-the-performance-of-your-swiftdata-apps)
4. [Hacking with Swift — Complex migration with VersionedSchema](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-create-a-complex-migration-using-versionedschema)
5. [Apple Developer — Syncing model data across devices](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices)
6. [Apple Developer — SchemaMigrationPlan](https://developer.apple.com/documentation/swiftdata/schemamigrationplan)
7. [Apple Developer Forums — SwiftData + CKSyncEngine](https://developer.apple.com/forums/thread/770450)
8. [Apple Developer Forums — Disable automatic iCloud sync](https://developer.apple.com/forums/thread/731375)
9. [Apple Developer Forums — Schema migration gotchas](https://developer.apple.com/forums/thread/738812)
10. [Apple WWDC25 — SwiftData: Dive into inheritance and schema migration](https://developer.apple.com/videos/play/wwdc2025/291/)
11. [Apple WWDC23 — Model your schema with SwiftData](https://developer.apple.com/videos/play/wwdc2023/10195/)
12. [Superwall — CKSyncEngine tutorial](https://superwall.com/blog/syncing-data-with-cloudkit-in-your-ios-app-using-cksyncengine-and-swift-and-swiftui/)
13. [Apple sample-cloudkit-sync-engine (GitHub)](https://github.com/apple/sample-cloudkit-sync-engine)
14. [Yingjie's Blog — SwiftData with CKSyncEngine](https://yingjiezhao.com/en/articles/Implementing-iCloud-Sync-by-Combining-SwiftData-with-CKSyncEngine/)
15. [Jacob Bartlett — High Performance SwiftData](https://blog.jacobstechtavern.com/p/high-performance-swiftdata)
16. [Michael Tsai — Returning to Core Data (community sentiment)](https://mjtsai.com/blog/2024/10/16/returning-to-core-data/)
17. [Michael Tsai — SwiftData and Core Data at WWDC25](https://mjtsai.com/blog/2025/06/19/swiftdata-and-core-data-at-wwdc25/)
18. [DistantJob — Core Data vs SwiftData 2025](https://distantjob.com/blog/core-data-vs-swiftdata/)
19. [Tanaschita — Migration with SwiftData](https://tanaschita.com/20231120-migration-with-swiftdata/)
20. [Atomic Robot — Unauthorized Guide to SwiftData Migrations](https://atomicrobot.com/blog/an-unauthorized-guide-to-swiftdata-migrations/)
21. [SwiftDataSync (third-party alternative)](https://github.com/FiveSheepCo/SwiftDataSync)
22. [Kodeco — CloudKit Support & Extending SwiftData Apps (March 2025)](https://www.kodeco.com/ios/paths/continuing-swiftui/45123174-data-persistence-with-swiftdata/04-extending-swiftdata-apps-cloudkit-support/02)
23. [Alex Logan — SwiftData, meet iCloud](https://alexanderlogan.co.uk/blog/wwdc23/08-cloudkit-swift-data)
24. [DEV Community — WWDC 2025 SwiftData iOS 26 Inheritance & Migration](https://dev.to/arshtechpro/wwdc-2025-swiftdata-ios-26-class-inheritance-migration-issues-30bh)
