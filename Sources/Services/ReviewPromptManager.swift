import Foundation
import Observation
import OSLog
import StoreKit
import UIKit

/// Asks for an App Store review only after a genuinely *positive* moment — a
/// completed fast — and only once the person has clearly invested in Lumifaste.
/// The ask is never a standalone interruption: a caller invokes
/// ``trackPositiveAction()`` right after a success, and this manager decides
/// quietly whether the timing is right to surface the honest in-app pre-prompt.
///
/// Timing contract (all must hold):
///  - at least `minPositiveActions` completed fasts have accumulated,
///  - at least `minSessions` app sessions have started,
///  - at least `cooldownDays` have passed since the last request.
///
/// Apple independently caps the system prompt at three per 365 days, so the
/// cooldown is a courtesy floor rather than the only guard. Because the prompt
/// is fired from a real success, we never ask after a negative experience — the
/// single most important App Store review rule (canonical: Sillora
/// `ReviewPromptManager`).
///
/// This is the honest "flavor a" pattern: a genuine two-option pre-prompt. It is
/// never a fake star UI that secretly routes low taps to feedback and high taps
/// to the App Store — Apple's HIG discourages that review-gating and it clashes
/// with the TheKnack honest-brand rule.
@Observable @MainActor
final class ReviewPromptManager {
    private let defaults: UserDefaults
    private let logger = Logger(subsystem: "com.theknack.lumifaste", category: "review")

    private enum Key {
        static let positiveActionCount = "lf_review_positive_count"
        static let sessionCount = "lf_review_session_count"
        static let lastRequestAt = "lf_review_last_request_at"
    }

    /// Private feedback channel for the "could be better" path — an unhappy tap
    /// vents to us in Mail instead of a public one-star. Honest routing: we never
    /// fake-collect a star rating and secretly filter.
    private static let feedbackMailto =
        "mailto:theknack2020@gmail.com?subject=Lumifaste%20Feedback"

    /// Drives the honest, in-app pre-prompt ("Enjoying Lumifaste?"). Set at a peak
    /// moment; a happy tap opens Apple's native prompt, an unhappy tap opens
    /// private feedback.
    var pendingPrePrompt = false

    /// Completed fasts required before the first ask (real investment first).
    private nonisolated static let minPositiveActions = 3
    /// App sessions required before the first ask (never on the first run).
    private nonisolated static let minSessions = 3
    /// Courtesy floor between asks; Apple's own 3/year cap sits above this.
    private nonisolated static let cooldownDays = 120

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Counters (UserDefaults-backed)

    private(set) var positiveActionCount: Int {
        get { defaults.integer(forKey: Key.positiveActionCount) }
        set { defaults.set(newValue, forKey: Key.positiveActionCount) }
    }

    private(set) var sessionCount: Int {
        get { defaults.integer(forKey: Key.sessionCount) }
        set { defaults.set(newValue, forKey: Key.sessionCount) }
    }

    private var lastRequestDate: Date? {
        let raw = defaults.double(forKey: Key.lastRequestAt)
        return raw > 0 ? Date(timeIntervalSince1970: raw) : nil
    }

    // MARK: - Tracking

    /// Call once per app foreground/session start. Advances the session counter
    /// used by the timing gate.
    func trackSessionStart() {
        sessionCount += 1
    }

    /// Record a positive moment (a completed fast) and, if the timing is right,
    /// surface the honest review pre-prompt. Safe to call from many surfaces —
    /// the internal gate ensures at most one ask per cooldown window.
    ///
    /// ⛔ Only ever call this after something the person will feel good about.
    /// Never after an error, a cancel, or any friction.
    func trackPositiveAction() {
        positiveActionCount += 1
        requestReviewIfAppropriate()
    }

    // MARK: - Request

    private func requestReviewIfAppropriate() {
        guard Self.shouldRequestReview(
            positiveActionCount: positiveActionCount,
            sessionCount: sessionCount,
            lastRequest: lastRequestDate
        ) else { return }

        // Record the ask now so the cooldown applies to the pre-prompt itself,
        // then surface the honest in-app card. The native App Store prompt only
        // fires if they tap "I love it" (``lovedIt()``).
        defaults.set(Date.now.timeIntervalSince1970, forKey: Key.lastRequestAt)
        pendingPrePrompt = true
        logger.debug("Surfacing review pre-prompt.")
    }

    /// "I love it" — open Apple's native rating prompt (itself capped at 3/365 by
    /// iOS). Dismisses the pre-prompt.
    func lovedIt() {
        pendingPrePrompt = false
        guard let scene = activeWindowScene else {
            logger.debug("Review request skipped: no active window scene.")
            return
        }
        AppStore.requestReview(in: scene)
        logger.debug("Requested App Store review.")
    }

    /// "Could be better" — route to private feedback (Mail) so the gripe reaches
    /// us, not a public one-star. Dismisses the pre-prompt.
    func notForMe() {
        pendingPrePrompt = false
        if let url = URL(string: Self.feedbackMailto) {
            UIApplication.shared.open(url)
        }
        logger.debug("Routed review pre-prompt to feedback.")
    }

    /// Explicit "Rate Lumifaste" from Settings — the person deliberately asked to
    /// rate, so open the native prompt directly, no gating. Bypasses the cadence
    /// gate but still respects iOS's own 3/365 cap.
    func requestReviewDirectly() {
        guard let scene = activeWindowScene else { return }
        AppStore.requestReview(in: scene)
        logger.debug("Requested App Store review directly (Settings).")
    }

    /// The pure timing gate — the ethics heart of the review ask. Extracted as a
    /// static, side-effect-free function so the cadence contract — invest first,
    /// never on the first runs, courtesy cooldown — is pinned in tests
    /// independently of `AppStore.requestReview` and UIKit window scenes. All
    /// three conditions must hold for an ask to be appropriate.
    nonisolated static func shouldRequestReview(
        positiveActionCount: Int,
        sessionCount: Int,
        lastRequest: Date?,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        guard positiveActionCount >= minPositiveActions,
              sessionCount >= minSessions
        else { return false }

        guard let last = lastRequest else { return true }
        let elapsedDays = calendar.dateComponents([.day], from: last, to: now).day ?? 0
        return elapsedDays >= cooldownDays
    }

    private var activeWindowScene: UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes
        return scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
            ?? scenes.first { $0 is UIWindowScene } as? UIWindowScene
    }

    #if DEBUG
        /// Clears all review cadence state (development / UI-test resets only).
        func resetForTesting() {
            defaults.removeObject(forKey: Key.positiveActionCount)
            defaults.removeObject(forKey: Key.sessionCount)
            defaults.removeObject(forKey: Key.lastRequestAt)
        }
    #endif
}
