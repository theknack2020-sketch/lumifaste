import Foundation
import OSLog
import UserNotifications

private let logger = Logger(subsystem: "com.theknack.lumifaste", category: "OnboardingJourney")

/// First 3-day progressive feature discovery manager.
/// Tracks install date and shows contextual banners on TimerView:
///   Day 1: "Your first fast matters most!"
///   Day 2: "Tap the stage card to learn what's happening"
///   Day 3: "Check your badges in Settings!"
///   After day 3: banners stop.
///
/// All state persisted in UserDefaults — survives app kill & restart.
@Observable
final class OnboardingJourneyManager {
    // MARK: - Keys

    private enum Key {
        static let installDate = "lf_install_date"
        static let dismissedDay = "lf_journey_dismissed_day"
    }

    // MARK: - Banner Model

    struct Banner: Equatable {
        let title: String
        let message: String
        let icon: String
        let day: Int
    }

    // MARK: - State

    /// The day number since install (1-indexed). Day 1 = install day.
    var currentDay: Int {
        guard let installDate else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: installDate), to: calendar.startOfDay(for: .now)).day ?? 0
        return days + 1 // 1-indexed
    }

    /// Whether the journey is still active (within first 3 days).
    var isJourneyActive: Bool {
        currentDay >= 1 && currentDay <= 3
    }

    private var installDate: Date? {
        UserDefaults.standard.object(forKey: Key.installDate) as? Date
    }

    /// The day number that was last dismissed by the user.
    private var dismissedDay: Int {
        UserDefaults.standard.integer(forKey: Key.dismissedDay)
    }

    // MARK: - Init

    init() {
        ensureInstallDateSet()
    }

    // MARK: - Public API

    /// Returns the banner for today, or nil if:
    /// - Journey is over (day > 3)
    /// - Today's banner was already dismissed
    /// - Install date not set
    func currentDayBanner() -> Banner? {
        guard isJourneyActive else { return nil }
        let day = currentDay
        guard day != dismissedDay else { return nil }

        switch day {
        case 1:
            return Banner(
                title: "Welcome to Lumifaste! 🌱",
                message: "Your first fast matters most. Start with 12:12 — it's the easiest way to begin.",
                icon: "leaf.fill",
                day: 1
            )
        case 2:
            return Banner(
                title: "Did You Know? 🔍",
                message: "Tap the stage card to learn what your body is doing right now during your fast.",
                icon: "hand.tap.fill",
                day: 2
            )
        case 3:
            return Banner(
                title: "Check Your Achievements! 🏅",
                message: "You've earned your first badges! Check them in Settings → Achievements.",
                icon: "trophy.fill",
                day: 3
            )
        default:
            return nil
        }
    }

    /// Dismiss today's banner. Won't show again until the next day.
    func dismissBanner() {
        let day = currentDay
        UserDefaults.standard.set(day, forKey: Key.dismissedDay)
        logger.info("Dismissed journey banner for day \(day)")
    }

    // MARK: - Push Notifications (Day 1-3)

    /// Schedule push notifications for the journey days.
    /// Called once at install — schedules Day 1, 2, 3 notifications at 10 AM.
    /// Idempotent: checks if already scheduled.
    func scheduleJourneyPushNotifications() {
        let scheduledKey = "lf_journey_push_scheduled"
        guard !UserDefaults.standard.bool(forKey: scheduledKey) else { return }
        guard let installDate else { return }

        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current

        let messages: [(day: Int, title: String, body: String)] = [
            (1, "Your Fasting Journey Begins! 🌱", "Your first fast matters most. Open Lumifaste and start with an easy 12:12 plan."),
            (2, "Day 2 — Discover Fasting Stages 🔍", "Did you know your body enters different metabolic stages? Open Lumifaste to explore."),
            (3, "Day 3 — Check Your Achievements! 🏅", "You may have earned your first badges. Open Lumifaste to see your progress!"),
        ]

        for msg in messages {
            guard let targetDate = calendar.date(byAdding: .day, value: msg.day - 1, to: calendar.startOfDay(for: installDate)) else { continue }
            var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
            components.hour = 10
            components.minute = 0

            // Don't schedule if the date already passed
            guard let fireDate = calendar.date(from: components), fireDate > Date.now else { continue }

            let content = UNMutableNotificationContent()
            content.title = msg.title
            content.body = msg.body
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "lf_journey_day\(msg.day)", content: content, trigger: trigger)

            center.add(request) { error in
                if let error {
                    logger.error("Failed to schedule journey push day \(msg.day): \(error.localizedDescription)")
                } else {
                    logger.info("Scheduled journey push for day \(msg.day)")
                }
            }
        }

        UserDefaults.standard.set(true, forKey: scheduledKey)
        logger.info("Journey push notifications scheduled")
    }

    // MARK: - Private

    /// Sets the install date on first launch. Idempotent.
    private func ensureInstallDateSet() {
        guard UserDefaults.standard.object(forKey: Key.installDate) == nil else { return }
        let now = Date.now
        UserDefaults.standard.set(now, forKey: Key.installDate)
        logger.info("Install date set: \(now.formatted())")
    }
}
