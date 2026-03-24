import Foundation
import SwiftData
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.theknack.lumifaste", category: "FastingManager")

/// Oruç yöneticisi — timer state, persistence, stage tracking.
/// Timestamp-based: asla tick counter kullanmaz, Date.now'dan hesaplar.
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
    
    /// Kalan süre (saniye) — target'a göre, adjusted for pauses
    var remainingTime: TimeInterval {
        guard let end = targetEndDate, isActive else { return 0 }
        let adjusted = end.addingTimeInterval(effectivePausedDuration)
        return max(0, adjusted.timeIntervalSince(Date.now))
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
        self.isActive = UserDefaults.standard.bool(forKey: "lf_fasting_active")
        self.startDate = UserDefaults.standard.object(forKey: "lf_fasting_start") as? Date
        self.targetEndDate = UserDefaults.standard.object(forKey: "lf_fasting_end") as? Date
        let planRaw = UserDefaults.standard.string(forKey: "lf_fasting_plan") ?? FastingPlan.sixteenEight.rawValue
        self.currentPlan = FastingPlan(rawValue: planRaw) ?? .sixteenEight
        self.isPaused = UserDefaults.standard.bool(forKey: "lf_fasting_paused")
        self.pauseStartDate = UserDefaults.standard.object(forKey: "lf_fasting_pause_start") as? Date
        self.totalPausedDuration = UserDefaults.standard.double(forKey: "lf_fasting_paused_total")
        self.waterCount = UserDefaults.standard.integer(forKey: "lf_fasting_water")
    }
    
    // MARK: - Actions
    
    /// Yeni oruç başlat
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
        clearState()
        
        Task { @MainActor in
            NotificationManager.shared.cancelAllFastingNotifications()
        }
    }
    
    /// Plan değiştir (aktif oruç yokken)
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
            let plan = self.currentPlan
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
        case .movedForward(let seconds) where seconds > 3600:
            // Clock moved forward by more than 1 hour — suspicious
            clockAnomalyDetected = true
            logger.warning("Clock moved forward \(seconds)s during active fast — flagging anomaly")
        case .movedBackward(let seconds) where seconds > 300:
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
}
