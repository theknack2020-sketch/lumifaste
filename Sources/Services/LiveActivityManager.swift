import ActivityKit
import Foundation
import OSLog

private let logger = Logger(subsystem: "com.theknack.lumifaste", category: "LiveActivity")

/// Manages the fasting Live Activity lifecycle — start, update, end.
/// Call from FastingManager when fasting state changes.
enum LiveActivityManager {
    /// Currently running fasting activity, if any.
    private(set) nonisolated(unsafe) static var currentActivity: Activity<FastingActivityAttributes>?

    // MARK: - Start

    /// Start a new Live Activity for an active fast.
    /// No-op if Live Activities are unavailable or one is already running.
    static func startLiveActivity(
        plan: String,
        startDate: Date,
        targetSeconds: Int,
        currentStage: String,
        stageEmoji: String
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.info("Live Activities not enabled — skipping start")
            return
        }

        // End any stale activity first
        endLiveActivity()

        let attributes = FastingActivityAttributes(
            startDate: startDate,
            fastingPlan: plan
        )

        let initialState = FastingActivityAttributes.ContentState(
            elapsedSeconds: 0,
            targetSeconds: targetSeconds,
            currentStage: currentStage,
            stageEmoji: stageEmoji,
            planName: plan
        )

        let content = ActivityContent(state: initialState, staleDate: nil)

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            currentActivity = activity
            logger.info("Live Activity started: \(activity.id)")
        } catch {
            logger.error("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    // MARK: - Update

    /// Update the running Live Activity with current fasting state.
    /// No-op if no activity is running.
    static func updateLiveActivity(
        elapsedSeconds: Int,
        targetSeconds: Int,
        stage: String,
        stageEmoji: String,
        planName: String
    ) {
        guard let activity = currentActivity else { return }

        let updatedState = FastingActivityAttributes.ContentState(
            elapsedSeconds: elapsedSeconds,
            targetSeconds: targetSeconds,
            currentStage: stage,
            stageEmoji: stageEmoji,
            planName: planName
        )

        let content = ActivityContent(state: updatedState, staleDate: nil)

        Task {
            await activity.update(content)
            logger.debug("Live Activity updated — elapsed: \(elapsedSeconds)s, stage: \(stage)")
        }
    }

    // MARK: - End

    /// End the running Live Activity.
    /// Shows a final state briefly before dismissal.
    static func endLiveActivity() {
        guard let activity = currentActivity else { return }

        let finalState = activity.content.state

        Task {
            let content = ActivityContent(state: finalState, staleDate: .now)
            await activity.end(content, dismissalPolicy: .after(.now.addingTimeInterval(60)))
            logger.info("Live Activity ended: \(activity.id)")
        }

        currentActivity = nil
    }

    /// End all fasting activities (cleanup on app launch).
    static func endAllActivities() {
        Task {
            for activity in Activity<FastingActivityAttributes>.activities {
                let content = ActivityContent(state: activity.content.state, staleDate: .now)
                await activity.end(content, dismissalPolicy: .immediate)
            }
            currentActivity = nil
            logger.info("All Live Activities ended")
        }
    }
}
