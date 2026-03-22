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
        actualDuration = end.timeIntervalSince(startDate)
        stageReached = FastingStage.stage(for: actualDuration).rawValue
        isCompleted = true
    }
}
