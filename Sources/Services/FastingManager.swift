import Foundation
import OSLog
import SwiftData
import SwiftUI

private let logger = Logger(subsystem: "com.theknack.lumifaste", category: "FastingManager")

/// Fasting manager — timer state, persistence, stage tracking.
/// Timestamp-based: never uses tick counters, calculates from Date.now.
/// All active fast state is persisted to UserDefaults — survives app kill & restart (#12).
/// Clock manipulation protection via ClockGuard.
@Observable
final class FastingManager {
    // MARK: - Persisted State (UserDefaults — survives kill)

    private(set) var isActive: Bool {
        didSet { UserDefaults.standard.set(isActive, forKey: "lf_fasting_active") }
    }

    private(set) var startDate: Date? {
        didSet { UserDefaults.standard.set(startDate, forKey: "lf_fasting_start") }
    }

    private(set) var targetEndDate: Date? {
        didSet { UserDefaults.standard.set(targetEndDate, forKey: "lf_fasting_end") }
    }

    private(set) var currentPlan: FastingPlan {
        didSet { UserDefaults.standard.set(currentPlan.rawValue, forKey: "lf_fasting_plan") }
    }

    // MARK: - Pause State (persisted)

    /// Whether the fast is currently paused
    private(set) var isPaused: Bool {
        didSet { UserDefaults.standard.set(isPaused, forKey: "lf_fasting_paused") }
    }

    /// When the current pause started (nil if not paused)
    private(set) var pauseStartDate: Date? {
        didSet { UserDefaults.standard.set(pauseStartDate, forKey: "lf_fasting_pause_start") }
    }

    /// Accumulated paused duration from previous pauses (seconds)
    private(set) var totalPausedDuration: TimeInterval {
        didSet { UserDefaults.standard.set(totalPausedDuration, forKey: "lf_fasting_paused_total") }
    }

    // MARK: - Water Counter (persisted)

    /// Number of water intakes logged during current fast
    var waterCount: Int {
        didSet { UserDefaults.standard.set(waterCount, forKey: "lf_fasting_water") }
    }

    // MARK: - Computed (always from Date.now)

    /// Current paused duration for the active pause (0 if not paused)
    private var currentPauseDuration: TimeInterval {
        guard isPaused, let pauseStart = pauseStartDate else { return 0 }
        return max(0, Date.now.timeIntervalSince(pauseStart))
    }

    /// Total time spent paused (past + current)
    var effectivePausedDuration: TimeInterval {
        totalPausedDuration + currentPauseDuration
    }

    /// Geçen süre (saniye) — minus paused time, with clock manipulation protection
    var elapsedTime: TimeInterval {
        guard let start = startDate, isActive else { return 0 }
        return ClockGuard.safeElapsedTime(since: start, pausedDuration: effectivePausedDuration)
    }

    /// Whether a clock anomaly was detected during this session
    private(set) var clockAnomalyDetected: Bool = false

    /// Kalan süre (saniye) — elapsed'dan türetilir, senkronizasyon garantili
    var remainingTime: TimeInterval {
        guard let start = startDate, let end = targetEndDate, isActive else { return 0 }
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return max(0, total - elapsedTime)
    }

    /// 0.0 - 1.0 arası ilerleme
    var progress: Double {
        guard let start = startDate, let end = targetEndDate, isActive else { return 0 }
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(1.0, elapsedTime / total)
    }

    /// Şu anki fasting stage
    var currentStage: FastingStage {
        FastingStage.stage(for: elapsedTime)
    }

    /// Target'ı aştık mı (bonus time)
    var isOvertime: Bool {
        guard isActive else { return false }
        return remainingTime <= 0
    }

    // MARK: - Init (restore from persistence)

    init() {
        isActive = UserDefaults.standard.bool(forKey: "lf_fasting_active")
        startDate = UserDefaults.standard.object(forKey: "lf_fasting_start") as? Date
        targetEndDate = UserDefaults.standard.object(forKey: "lf_fasting_end") as? Date
        let planRaw = UserDefaults.standard.string(forKey: "lf_fasting_plan") ?? FastingPlan.sixteenEight.rawValue
        currentPlan = FastingPlan(rawValue: planRaw) ?? .sixteenEight
        isPaused = UserDefaults.standard.bool(forKey: "lf_fasting_paused")
        pauseStartDate = UserDefaults.standard.object(forKey: "lf_fasting_pause_start") as? Date
        totalPausedDuration = UserDefaults.standard.double(forKey: "lf_fasting_paused_total")
        waterCount = UserDefaults.standard.integer(forKey: "lf_fasting_water")
    }

    // MARK: - Actions

    /// Start a new fast
    func startFast(plan: FastingPlan) {
        let now = Date.now
        startDate = now
        targetEndDate = now.addingTimeInterval(plan.fastingDuration)
        currentPlan = plan
        isActive = true
        isPaused = false
        pauseStartDate = nil
        totalPausedDuration = 0
        waterCount = 0

        // Start Live Activity
        let stage = FastingStage.stage(for: 0)
        LiveActivityManager.startLiveActivity(
            plan: plan.rawValue,
            startDate: now,
            targetSeconds: Int(plan.fastingDuration),
            currentStage: stage.rawValue,
            stageEmoji: stage.emoji
        )

        // Schedule all notifications
        Task { @MainActor in
            let granted = await NotificationManager.shared.requestPermission()
            if granted {
                NotificationManager.shared.scheduleFastingNotifications(startDate: now, plan: plan)
            }
        }
    }

    /// Orucu bitir ve SwiftData'ya kaydet. Returns the session on success.
    @MainActor
    @discardableResult
    func endFast(context: ModelContext) -> FastingSession? {
        guard isActive, let start = startDate, let target = targetEndDate else { return nil }

        // If paused, finalize the pause duration first
        if isPaused, let pauseStart = pauseStartDate {
            totalPausedDuration += Date.now.timeIntervalSince(pauseStart)
            isPaused = false
            pauseStartDate = nil
        }

        let session = FastingSession(
            startDate: start,
            targetEndDate: target,
            planType: currentPlan
        )
        session.waterCount = waterCount
        session.totalPausedDuration = totalPausedDuration
        session.complete()
        context.insert(session)

        // Save with error handling
        do {
            try context.save()
        } catch {
            logger.error("Failed to save completed fast session: \(error.localizedDescription)")
        }

        // Cancel pending fasting notifications
        Task { @MainActor in
            NotificationManager.shared.cancelAllFastingNotifications()
        }

        // Record completion for paywall trigger and review request tracking
        FastingManager.recordFastCompletion()

        // State temizle
        clearState()

        return session
    }

    /// Orucu iptal et (kaydetmeden)
    func cancelFast() {
        LiveActivityManager.endLiveActivity()
        clearState()

        Task { @MainActor in
            NotificationManager.shared.cancelAllFastingNotifications()
        }
    }

    /// Change plan (when no active fast)
    func setPlan(_ plan: FastingPlan) {
        guard !isActive else { return }
        currentPlan = plan
    }

    // MARK: - Edit Start Time (#1: "I forgot to start")

    /// Adjust the start time retroactively. Recalculates targetEndDate accordingly.
    /// The new start must be in the past and no more than 24h ago.
    func adjustStartTime(to newStart: Date) {
        guard isActive, newStart < Date.now else { return }
        let maxPast = Date.now.addingTimeInterval(-24 * 3600)
        let clamped = max(newStart, maxPast)

        let plan = currentPlan
        startDate = clamped
        targetEndDate = clamped.addingTimeInterval(plan.fastingDuration)

        // Reschedule notifications
        Task { @MainActor in
            NotificationManager.shared.scheduleFastingNotifications(startDate: clamped, plan: plan)
        }
    }

    // MARK: - Extend Fast (#3)

    /// Extend the target end by a given number of hours (1–24).
    func extendFast(byHours hours: Double) {
        guard isActive, let end = targetEndDate else { return }
        let clamped = min(max(hours, 0.5), 24)
        targetEndDate = end.addingTimeInterval(clamped * 3600)
    }

    // MARK: - Pause / Resume (#11)

    func pauseFast() {
        guard isActive, !isPaused else { return }
        isPaused = true
        pauseStartDate = Date.now

        Task { @MainActor in
            NotificationManager.shared.cancelAllFastingNotifications()
        }
    }

    func resumeFast() {
        guard isActive, isPaused, let pauseStart = pauseStartDate else { return }
        let pausedSeconds = Date.now.timeIntervalSince(pauseStart)
        totalPausedDuration += pausedSeconds
        isPaused = false
        pauseStartDate = nil

        // Reschedule notifications from now based on remaining effective time
        if let start = startDate {
            let plan = currentPlan
            Task { @MainActor in
                NotificationManager.shared.scheduleFastingNotifications(startDate: start, plan: plan)
            }
        }
    }

    // MARK: - Water Intake (#5)

    func logWater() {
        guard isActive else { return }
        waterCount += 1
    }

    // MARK: - Private

    private func clearState() {
        isActive = false
        startDate = nil
        targetEndDate = nil
        isPaused = false
        pauseStartDate = nil
        totalPausedDuration = 0
        waterCount = 0
        clockAnomalyDetected = false
    }

    // MARK: - Clock Integrity

    /// Check clock integrity and handle anomalies.
    /// Call on app foreground and periodically during active fast.
    func checkClockIntegrity() {
        guard isActive else { return }

        let result = ClockGuard.checkClockIntegrity()
        switch result {
        case let .movedForward(seconds) where seconds > 3600:
            // Clock moved forward by more than 1 hour — suspicious
            clockAnomalyDetected = true
            logger.warning("Clock moved forward \(seconds)s during active fast — flagging anomaly")
        case let .movedBackward(seconds) where seconds > 300:
            // Clock moved backward by more than 5 minutes — suspicious
            clockAnomalyDetected = true
            logger.warning("Clock moved backward \(seconds)s during active fast — flagging anomaly")
        default:
            break
        }

        // Also check timezone changes
        if let oldTZ = ClockGuard.checkTimezoneChange() {
            logger.info("Timezone changed from \(oldTZ) during active fast — Date handles this correctly")
            // Swift's Date is timezone-agnostic (absolute time), so no correction needed.
            // But we log it for diagnostics.
        }
    }

    // MARK: - Nudge Check (#13): returns true if user hasn't fasted in 3+ days

    static func shouldShowNudge(sessions: [FastingSession]) -> Bool {
        let completed = sessions.filter(\.isCompleted)
        guard let lastFast = completed.max(by: { $0.startDate < $1.startDate }) else {
            // No fasts at all — nudge if onboarding was more than 3 days ago
            return true
        }
        let daysSinceLast = Date.now.timeIntervalSince(lastFast.startDate) / 86400
        return daysSinceLast >= 3
    }

    // MARK: - Soft Paywall Trigger (#14)

    /// Key for total completed fasts counter (persisted across sessions)
    private static let totalCompletedFastsKey = "lf_total_completed_fasts"

    /// Key for whether soft paywall has been triggered at least once
    private static let softPaywallTriggeredKey = "lf_soft_paywall_triggered"

    /// Number of completed fasts needed to trigger soft paywall
    static let softPaywallThreshold = 3

    /// Total number of completed fasts (persisted, monotonically increasing)
    static var totalCompletedFasts: Int {
        UserDefaults.standard.integer(forKey: totalCompletedFastsKey)
    }

    /// Record a completed fast — updates counter and checks paywall eligibility.
    /// Called from endFast. Returns true if this completion should trigger a soft paywall.
    @discardableResult
    static func recordFastCompletion() -> Bool {
        let newCount = totalCompletedFasts + 1
        UserDefaults.standard.set(newCount, forKey: totalCompletedFastsKey)
        logger.info("Total completed fasts: \(newCount)")

        // Trigger soft paywall at threshold and at multiples of 10 after
        if newCount == softPaywallThreshold || (newCount > softPaywallThreshold && newCount % 10 == 0) {
            if !UserDefaults.standard.bool(forKey: softPaywallTriggeredKey) || newCount % 10 == 0 {
                logger.info("Soft paywall trigger eligible at \(newCount) fasts")
                return true
            }
        }
        return false
    }

    /// Mark that soft paywall was shown (prevents re-showing until next trigger point)
    static func markSoftPaywallShown() {
        UserDefaults.standard.set(true, forKey: softPaywallTriggeredKey)
        logger.info("Soft paywall marked as shown")
    }

    /// Whether conditions are met to show soft paywall (non-premium, threshold reached, not yet shown this cycle)
    static func shouldShowSoftPaywall(isPremium: Bool) -> Bool {
        guard !isPremium else { return false }
        let count = totalCompletedFasts
        guard count >= softPaywallThreshold else { return false }
        // Show at threshold, or at every 10 fasts after
        if count == softPaywallThreshold {
            return !UserDefaults.standard.bool(forKey: softPaywallTriggeredKey)
        }
        return count % 10 == 0
    }

    /// Reset soft paywall trigger state (for testing or after subscription change)
    static func resetSoftPaywallState() {
        UserDefaults.standard.removeObject(forKey: softPaywallTriggeredKey)
        logger.info("Soft paywall state reset")
    }

    // MARK: - Retention Helpers (#14-18)

    /// Weekly stats: number of completed fasts and total fasting hours this calendar week.
    struct WeeklyStats {
        let fastCount: Int
        let totalHours: Double
        let streakActive: Bool
    }

    /// Compute average start time (hour component) from completed sessions.
    /// Returns nil if no completed sessions exist.
    static func averageStartTime(sessions: [FastingSession]) -> DateComponents? {
        let completed = sessions.filter(\.isCompleted)
        guard !completed.isEmpty else { return nil }

        let calendar = Calendar.current
        var totalMinutesSinceMidnight: Double = 0

        for session in completed {
            let comps = calendar.dateComponents([.hour, .minute], from: session.startDate)
            totalMinutesSinceMidnight += Double(comps.hour ?? 0) * 60 + Double(comps.minute ?? 0)
        }

        let avgMinutes = Int(totalMinutesSinceMidnight / Double(completed.count))
        var result = DateComponents()
        result.hour = avgMinutes / 60
        result.minute = avgMinutes % 60
        return result
    }

    /// Format average start time as a readable string like "8:30 PM".
    static func formattedAverageStartTime(sessions: [FastingSession]) -> String? {
        guard let comps = averageStartTime(sessions: sessions) else { return nil }
        var dateComps = DateComponents()
        dateComps.hour = comps.hour
        dateComps.minute = comps.minute
        guard let date = Calendar.current.date(from: dateComps) else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    /// Number of days since the last completed fast. Returns nil if no fasts exist.
    static func daysSinceLastFast(sessions: [FastingSession]) -> Int? {
        let completed = sessions.filter(\.isCompleted)
        guard let lastFast = completed.max(by: { $0.startDate < $1.startDate }) else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: lastFast.startDate), to: calendar.startOfDay(for: .now)).day
    }

    /// Compute stats for the current calendar week (Mon–Sun).
    static func weeklyStats(sessions: [FastingSession], currentStreak: Int) -> WeeklyStats {
        let calendar = Calendar.current
        let now = Date.now

        // Find start of this week (Monday)
        let weekday = calendar.component(.weekday, from: now)
        let daysFromMonday = (weekday + 5) % 7 // Mon=0, Tue=1, ..., Sun=6
        guard let weekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: calendar.startOfDay(for: now)) else {
            return WeeklyStats(fastCount: 0, totalHours: 0, streakActive: currentStreak > 0)
        }

        let thisWeek = sessions.filter { $0.isCompleted && $0.startDate >= weekStart }
        let totalHours = thisWeek.reduce(0.0) { $0 + $1.actualDuration } / 3600
        let rounded = (totalHours * 10).rounded(.down) / 10 // 1 decimal

        return WeeklyStats(
            fastCount: thisWeek.count,
            totalHours: rounded,
            streakActive: currentStreak > 0
        )
    }

    // MARK: - Streak Freeze (Pro Feature)

    private static let streakFreezeCountKey = "lf_streak_freeze_count"
    private static let lastFreezeDateKey = "lf_streak_freeze_last_date"
    private static let lastFreezeRefillKey = "lf_streak_freeze_last_refill"

    /// Number of streak freezes currently available.
    static var streakFreezeCount: Int {
        get { UserDefaults.standard.integer(forKey: streakFreezeCountKey) }
        set { UserDefaults.standard.set(max(0, newValue), forKey: streakFreezeCountKey) }
    }

    /// Date when a streak freeze was last used.
    static var lastFreezeDate: Date? {
        get { UserDefaults.standard.object(forKey: lastFreezeDateKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastFreezeDateKey) }
    }

    /// Use a streak freeze if available. Max 1 per 7 days.
    /// Returns true if freeze was successfully used.
    static func useStreakFreeze() -> Bool {
        guard streakFreezeCount > 0 else { return false }

        // Check if one was used within the last 7 days
        if let lastUsed = lastFreezeDate {
            let daysSince = Calendar.current.dateComponents([.day], from: lastUsed, to: Date.now).day ?? 0
            if daysSince < 7 {
                logger.info("Streak freeze denied — last used \(daysSince) days ago (min 7)")
                return false
            }
        }

        streakFreezeCount -= 1
        lastFreezeDate = Date.now
        logger.info("Streak freeze used. Remaining: \(streakFreezeCount)")
        return true
    }

    /// Add 1 streak freeze (e.g. weekly auto-refill for Pro users).
    static func addStreakFreeze() {
        streakFreezeCount += 1
        logger.info("Streak freeze added. Total: \(streakFreezeCount)")
    }

    /// Auto-refill 1 streak freeze on Mondays for Pro users.
    /// Call on app foreground. Idempotent per week.
    static func refillStreakFreezeIfNeeded(isPremium: Bool) {
        guard isPremium else { return }

        let calendar = Calendar.current
        let now = Date.now
        let weekday = calendar.component(.weekday, from: now)

        // Only on Monday (weekday == 2 in Gregorian)
        guard weekday == 2 else { return }

        let todayStart = calendar.startOfDay(for: now)
        let lastRefill = UserDefaults.standard.object(forKey: lastFreezeRefillKey) as? Date

        // Already refilled today
        if let last = lastRefill, calendar.isDate(last, inSameDayAs: todayStart) {
            return
        }

        addStreakFreeze()
        UserDefaults.standard.set(todayStart, forKey: lastFreezeRefillKey)
        logger.info("Weekly streak freeze refill applied (Monday)")
    }
}
