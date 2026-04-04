import Foundation
import SwiftData

/// A completed or in-progress fasting session.
/// Timestamp-based: startDate/endDate persist edilir, elapsed time Date.now'dan hesaplanır.
@Model
final class FastingSession {
    var id: UUID = UUID()
    var startDate: Date = Date()
    var endDate: Date?
    var targetEndDate: Date = Date()
    var planType: String = ""
    var isCompleted: Bool = false
    var actualDuration: TimeInterval = 0
    var stageReached: String = ""

    // MARK: - New fields

    /// User's mood/energy at fast end (emoji string: 😴😐😊🔥)
    var mood: String?

    /// User note attached to the completed fast
    var note: String?

    /// Water intake count during fast (simple counter)
    var waterCount: Int = 0

    /// Total paused duration (seconds) — subtracted from elapsed for accurate tracking
    var totalPausedDuration: TimeInterval = 0

    init(
        startDate: Date,
        targetEndDate: Date,
        planType: FastingPlan
    ) {
        id = UUID()
        self.startDate = startDate
        endDate = nil
        self.targetEndDate = targetEndDate
        self.planType = planType.rawValue
        isCompleted = false
        actualDuration = 0
        stageReached = FastingStage.fed.rawValue
        mood = nil
        note = nil
        waterCount = 0
        totalPausedDuration = 0
    }

    var plan: FastingPlan {
        FastingPlan(rawValue: planType) ?? .sixteenEight
    }

    var stage: FastingStage {
        FastingStage(rawValue: stageReached) ?? .fed
    }

    /// Orucu tamamla — gerçek süreyi kaydet
    func complete() {
        let end = Date.now
        endDate = end
        actualDuration = end.timeIntervalSince(startDate) - totalPausedDuration
        stageReached = FastingStage.stage(for: actualDuration).rawValue
        isCompleted = true
    }
}
