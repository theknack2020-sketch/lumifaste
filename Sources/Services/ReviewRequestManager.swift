import Foundation
import OSLog
import StoreKit

private let logger = Logger(subsystem: "com.theknack.lumifaste", category: "ReviewRequest")

/// Manages "Rate this App" prompts — triggers after a threshold of completed fasts.
/// Uses SKStoreReviewController which Apple rate-limits automatically (~3/year).
///
/// Strategy:
/// - First prompt at 5 completed fasts (user has seen value)
/// - Subsequent prompts every 20 fasts (not annoying, but consistent)
/// - Minimum 60 days between prompts (even if fast count threshold is met)
/// - Apple's own rate limiting applies on top of ours
enum ReviewRequestManager {
    private static let completedFastsKey = "lf_completed_fasts_count"
    private static let hasRequestedReviewKey = "lf_has_requested_review"
    private static let lastReviewRequestDateKey = "lf_last_review_request_date"

    /// Threshold: request review after this many completed fasts
    static let threshold = 5

    /// Minimum days between review requests (our own throttle on top of Apple's)
    static let minimumDaysBetweenRequests = 60

    /// Repeat interval: request again every N fasts after threshold
    static let repeatInterval = 20

    /// Current completed fasts count (for diagnostics/debugging)
    static var completedFastsCount: Int {
        UserDefaults.standard.integer(forKey: completedFastsKey)
    }

    /// Whether we've ever requested a review
    static var hasRequestedReview: Bool {
        UserDefaults.standard.bool(forKey: hasRequestedReviewKey)
    }

    /// Call after each fast completion. Increments counter and requests review if threshold met.
    @MainActor
    static func recordCompletedFast() {
        let count = UserDefaults.standard.integer(forKey: completedFastsKey) + 1
        UserDefaults.standard.set(count, forKey: completedFastsKey)

        logger.info("Completed fasts count: \(count)")

        // Request review at exactly the threshold, or every `repeatInterval` fasts after
        if count == threshold || (count > threshold && count % repeatInterval == 0) {
            requestReviewIfAppropriate()
        }
    }

    /// Request review via SKStoreReviewController — Apple rate-limits to ~3/year.
    @MainActor
    static func requestReviewIfAppropriate() {
        // Don't request more than once per `minimumDaysBetweenRequests` days
        if let lastDate = UserDefaults.standard.object(forKey: lastReviewRequestDateKey) as? Date {
            let daysSinceLastRequest = Date.now.timeIntervalSince(lastDate) / 86400
            guard daysSinceLastRequest >= Double(minimumDaysBetweenRequests) else {
                logger.info("Skipping review request — last request was \(Int(daysSinceLastRequest)) days ago (min: \(minimumDaysBetweenRequests))")
                return
            }
        }

        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else {
            logger.warning("No active window scene for review request")
            return
        }

        SKStoreReviewController.requestReview(in: windowScene)
        UserDefaults.standard.set(Date.now, forKey: lastReviewRequestDateKey)
        UserDefaults.standard.set(true, forKey: hasRequestedReviewKey)
        logger.info("Requested app review (fasts: \(completedFastsCount))")
    }

    /// Reset all review request state — for testing or account reset
    static func reset() {
        UserDefaults.standard.removeObject(forKey: completedFastsKey)
        UserDefaults.standard.removeObject(forKey: hasRequestedReviewKey)
        UserDefaults.standard.removeObject(forKey: lastReviewRequestDateKey)
        logger.info("Review request state reset")
    }
}
