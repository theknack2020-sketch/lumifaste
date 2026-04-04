import Foundation
import SwiftData

// MARK: - Versioned Schema for Future Migrations

/// Schema V1 — initial release model.
/// When model changes are needed, add V2 and a migration plan.
enum LumifasteSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [FastingSessionV1.self, WeightEntryV1.self]
    }

    @Model
    final class FastingSessionV1 {
        var id: UUID
        var startDate: Date
        var endDate: Date?
        var targetEndDate: Date
        var planType: String
        var isCompleted: Bool
        var actualDuration: TimeInterval
        var stageReached: String
        var mood: String?
        var note: String?
        var waterCount: Int
        var totalPausedDuration: TimeInterval

        init(
            id: UUID = UUID(),
            startDate: Date,
            endDate: Date? = nil,
            targetEndDate: Date,
            planType: String,
            isCompleted: Bool = false,
            actualDuration: TimeInterval = 0,
            stageReached: String = FastingStage.fed.rawValue,
            mood: String? = nil,
            note: String? = nil,
            waterCount: Int = 0,
            totalPausedDuration: TimeInterval = 0
        ) {
            self.id = id
            self.startDate = startDate
            self.endDate = endDate
            self.targetEndDate = targetEndDate
            self.planType = planType
            self.isCompleted = isCompleted
            self.actualDuration = actualDuration
            self.stageReached = stageReached
            self.mood = mood
            self.note = note
            self.waterCount = waterCount
            self.totalPausedDuration = totalPausedDuration
        }
    }

    @Model
    final class WeightEntryV1 {
        var id: UUID
        var date: Date
        var weightKg: Double
        var note: String

        init(id: UUID = UUID(), date: Date = .now, weightKg: Double, note: String = "") {
            self.id = id
            self.date = date
            self.weightKg = weightKg
            self.note = note
        }
    }
}

// MARK: - Migration Plan

/// Migration plan for future schema updates.
/// When adding V2, create a MigrationStage and add it here.
enum LumifasteMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [LumifasteSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        // No migrations yet — first version.
        // When V2 is added:
        // [migrateV1toV2]
        []
    }

    // Example migration stage for reference (uncomment when V2 is needed):
    //
    // static let migrateV1toV2 = MigrationStage.lightweight(
    //     fromVersion: LumifasteSchemaV1.self,
    //     toVersion: LumifasteSchemaV2.self
    // )
    //
    // For complex migrations use:
    // static let migrateV1toV2 = MigrationStage.custom(
    //     fromVersion: LumifasteSchemaV1.self,
    //     toVersion: LumifasteSchemaV2.self,
    //     willMigrate: { context in
    //         // Pre-migration logic
    //     },
    //     didMigrate: { context in
    //         // Post-migration logic
    //         try context.save()
    //     }
    // )
}
