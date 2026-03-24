import Foundation
import OSLog

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
        guard let installDate = installDate else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: installDate), to: calendar.startOfDay(for: .now)).day ?? 0
        return days + 1  // 1-indexed
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
    
    // MARK: - Private
    
    /// Sets the install date on first launch. Idempotent.
    private func ensureInstallDateSet() {
        guard UserDefaults.standard.object(forKey: Key.installDate) == nil else { return }
        let now = Date.now
        UserDefaults.standard.set(now, forKey: Key.installDate)
        logger.info("Install date set: \(now.formatted())")
    }
}
