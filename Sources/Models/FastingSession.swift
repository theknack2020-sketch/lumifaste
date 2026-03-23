import Foundation
import SwiftData

/// Tamamlanmış veya devam eden bir oruç oturumu.
/// Timestamp-based: startDate/endDate persist edilir, elapsed time Date.now'dan hesaplanır.
@Model
final class FastingSession {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    var targetEndDate: Date
    var planType: String
    var isCompleted: Bool
    var actualDuration: TimeInterval
    var stageReached: String
    
    // MARK: - New fields
    
    /// User's mood/energy at fast end (emoji string: 😴😐😊🔥)
    var mood: String?
    
    /// User note attached to the completed fast
    var note: String?
    
    /// Water intake count during fast (simple counter)
    var waterCount: Int
    
    /// Total paused duration (seconds) — subtracted from elapsed for accurate tracking
    var totalPausedDuration: TimeInterval
    
    init(
        startDate: Date,
        targetEndDate: Date,
        planType: FastingPlan
    ) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = nil
        self.targetEndDate = targetEndDate
        self.planType = planType.rawValue
        self.isCompleted = false
        self.actualDuration = 0
        self.stageReached = FastingStage.fed.rawValue
        self.mood = nil
        self.note = nil
        self.waterCount = 0
        self.totalPausedDuration = 0
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
