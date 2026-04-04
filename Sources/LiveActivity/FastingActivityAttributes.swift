import ActivityKit
import Foundation

/// Shared model for the fasting Live Activity.
/// Used by both the main app (to start/update/end) and the widget extension (to render).
struct FastingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var elapsedSeconds: Int
        var targetSeconds: Int
        var currentStage: String
        var stageEmoji: String
        var planName: String
    }

    var startDate: Date
    var fastingPlan: String
}
