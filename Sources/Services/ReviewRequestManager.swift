import StoreKit
import Foundation
import OSLog

private let logger = Logger(subsystem: "com.theknack.lumifaste", category: "ReviewRequest")

/// Manages "Rate this App" prompts — triggers after a threshold of completed fasts.
/// Uses SKStoreReviewController which Apple rate-limits automatically.
enum ReviewRequestManager {
    
    private static let completedFastsKey = "lf_completed_fasts_count"
    private static let hasRequestedReviewKey = "lf_has_requested_review"
    private static let lastReviewRequestDateKey = "lf_last_review_request_date"
    
    /// Threshold: request review after this many completed fasts
    static let threshold = 5
    
    /// Call after each fast completion. Increments counter and requests review if threshold met.
    @MainActor
    static func recordCompletedFast() {
        let count = UserDefaults.standard.integer(forKey: completedFastsKey) + 1
        UserDefaults.standard.set(count, forKey: completedFastsKey)
        
        logger.info("Completed fasts count: \(count)")
        
        // Request review at exactly the threshold, or every 20 fasts after
        if count == threshold || (count > threshold && count % 20 == 0) {
            requestReviewIfAppropriate()
        }
    }
    
    /// Request review via SKStoreReviewController — Apple rate-limits to ~3/year.
    @MainActor
    static func requestReviewIfAppropriate() {
        // Don't request more than once per 60 days
        if let lastDate = UserDefaults.standard.object(forKey: lastReviewRequestDateKey) as? Date {
            let daysSinceLastRequest = Date.now.timeIntervalSince(lastDate) / 86400
            guard daysSinceLastRequest >= 60 else {
                logger.info("Skipping review request — last request was \(Int(daysSinceLastRequest)) days ago")
                return
            }
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            logger.warning("No active window scene for review request")
            return
        }
        
        SKStoreReviewController.requestReview(in: windowScene)
        UserDefaults.standard.set(Date.now, forKey: lastReviewRequestDateKey)
        UserDefaults.standard.set(true, forKey: hasRequestedReviewKey)
        logger.info("Requested app review")
    }
}
