import Foundation
import Testing
@testable import Lumifaste

/// Pins the review-prompt cadence contract — the ethics heart of the ask:
/// invest first (enough completed fasts + sessions), never on the first runs, and
/// respect a courtesy cooldown between asks. A regression here would either spam
/// users (bad reviews) or never ask (no ratings flywheel), so this suite makes the
/// gate loud. Mirrors the pure-function pattern from Sillora/WrenchLog.
@Suite("ReviewPromptManager timing gate")
struct ReviewPromptManagerTests {
    // MARK: - Happy path

    @Test("Asks once thresholds are met and no prior request")
    func asksWhenInvestedAndNeverAsked() {
        #expect(ReviewPromptManager.shouldRequestReview(
            positiveActionCount: 3,
            sessionCount: 3,
            lastRequest: nil
        ))
    }

    @Test("Asks again after the cooldown has fully elapsed")
    func asksAfterCooldown() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let longAgo = now.addingTimeInterval(-121 * 86400) // 121 days > 120-day floor
        #expect(ReviewPromptManager.shouldRequestReview(
            positiveActionCount: 5,
            sessionCount: 8,
            lastRequest: longAgo,
            now: now
        ))
    }

    // MARK: - Edge cases (the guards that protect the user)

    @Test("Never asks before enough positive actions accumulate")
    func blockedByPositiveActions() {
        #expect(!ReviewPromptManager.shouldRequestReview(
            positiveActionCount: 2, // below minPositiveActions (3)
            sessionCount: 10,
            lastRequest: nil
        ))
    }

    @Test("Never asks before enough sessions have started")
    func blockedBySessions() {
        #expect(!ReviewPromptManager.shouldRequestReview(
            positiveActionCount: 10,
            sessionCount: 2, // below minSessions (3)
            lastRequest: nil
        ))
    }

    @Test("Never asks twice inside the cooldown window")
    func blockedByCooldown() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let recent = now.addingTimeInterval(-10 * 86400) // 10 days < 120-day floor
        #expect(!ReviewPromptManager.shouldRequestReview(
            positiveActionCount: 9,
            sessionCount: 9,
            lastRequest: recent,
            now: now
        ))
    }
}
