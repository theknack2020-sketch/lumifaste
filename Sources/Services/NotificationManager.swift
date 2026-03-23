import Foundation
import UserNotifications
import UIKit
import OSLog

private let logger = Logger(subsystem: "com.theknack.lumifaste", category: "Notifications")

// MARK: - Notification Preferences (persisted in UserDefaults)

/// Per-type toggle + quiet hours — stored as UserDefaults booleans.
@Observable
final class NotificationSettings {
    
    // MARK: - Toggle keys
    
    var dailyReminderEnabled: Bool {
        didSet { UserDefaults.standard.set(dailyReminderEnabled, forKey: Key.dailyReminder) }
    }
    
    var milestoneEnabled: Bool {
        didSet { UserDefaults.standard.set(milestoneEnabled, forKey: Key.milestone) }
    }
    
    var stageTransitionEnabled: Bool {
        didSet { UserDefaults.standard.set(stageTransitionEnabled, forKey: Key.stageTransition) }
    }
    
    var fastCompleteEnabled: Bool {
        didSet { UserDefaults.standard.set(fastCompleteEnabled, forKey: Key.fastComplete) }
    }
    
    var motivationalQuotesEnabled: Bool {
        didSet { UserDefaults.standard.set(motivationalQuotesEnabled, forKey: Key.motivationalQuotes) }
    }
    
    var streakReminderEnabled: Bool {
        didSet { UserDefaults.standard.set(streakReminderEnabled, forKey: Key.streakReminder) }
    }
    
    // MARK: - Daily Reminder Time
    
    /// Hour component (0-23) for the daily reminder
    var dailyReminderHour: Int {
        didSet { UserDefaults.standard.set(dailyReminderHour, forKey: Key.dailyReminderHour) }
    }
    
    /// Minute component (0-59) for the daily reminder
    var dailyReminderMinute: Int {
        didSet { UserDefaults.standard.set(dailyReminderMinute, forKey: Key.dailyReminderMinute) }
    }
    
    // MARK: - Quiet Hours
    
    var quietHoursEnabled: Bool {
        didSet { UserDefaults.standard.set(quietHoursEnabled, forKey: Key.quietHoursEnabled) }
    }
    
    /// Quiet hours start (hour, 0-23). Default 22 (10 PM)
    var quietHoursStart: Int {
        didSet { UserDefaults.standard.set(quietHoursStart, forKey: Key.quietHoursStart) }
    }
    
    /// Quiet hours end (hour, 0-23). Default 7 (7 AM)
    var quietHoursEnd: Int {
        didSet { UserDefaults.standard.set(quietHoursEnd, forKey: Key.quietHoursEnd) }
    }
    
    init() {
        let ud = UserDefaults.standard
        
        // Default all toggles to true on first launch
        if !ud.bool(forKey: Key.initialized) {
            ud.set(true, forKey: Key.initialized)
            ud.set(true, forKey: Key.dailyReminder)
            ud.set(true, forKey: Key.milestone)
            ud.set(true, forKey: Key.stageTransition)
            ud.set(true, forKey: Key.fastComplete)
            ud.set(true, forKey: Key.motivationalQuotes)
            ud.set(true, forKey: Key.streakReminder)
            ud.set(20, forKey: Key.dailyReminderHour)
            ud.set(0, forKey: Key.dailyReminderMinute)
            ud.set(false, forKey: Key.quietHoursEnabled)
            ud.set(22, forKey: Key.quietHoursStart)
            ud.set(7, forKey: Key.quietHoursEnd)
        }
        
        self.dailyReminderEnabled = ud.bool(forKey: Key.dailyReminder)
        self.milestoneEnabled = ud.bool(forKey: Key.milestone)
        self.stageTransitionEnabled = ud.bool(forKey: Key.stageTransition)
        self.fastCompleteEnabled = ud.bool(forKey: Key.fastComplete)
        self.motivationalQuotesEnabled = ud.bool(forKey: Key.motivationalQuotes)
        self.streakReminderEnabled = ud.bool(forKey: Key.streakReminder)
        self.dailyReminderHour = ud.integer(forKey: Key.dailyReminderHour)
        self.dailyReminderMinute = ud.integer(forKey: Key.dailyReminderMinute)
        self.quietHoursEnabled = ud.bool(forKey: Key.quietHoursEnabled)
        self.quietHoursStart = ud.integer(forKey: Key.quietHoursStart)
        self.quietHoursEnd = ud.integer(forKey: Key.quietHoursEnd)
    }
    
    private enum Key {
        static let initialized = "lf_notif_settings_init"
        static let dailyReminder = "lf_notif_daily_reminder"
        static let milestone = "lf_notif_milestone"
        static let stageTransition = "lf_notif_stage_transition"
        static let fastComplete = "lf_notif_fast_complete"
        static let motivationalQuotes = "lf_notif_motivational"
        static let streakReminder = "lf_notif_streak"
        static let dailyReminderHour = "lf_notif_daily_hour"
        static let dailyReminderMinute = "lf_notif_daily_minute"
        static let quietHoursEnabled = "lf_notif_quiet_enabled"
        static let quietHoursStart = "lf_notif_quiet_start"
        static let quietHoursEnd = "lf_notif_quiet_end"
    }
}

// MARK: - Notification Categories & Actions

enum NotificationCategory: String {
    case fastingMilestone = "FASTING_MILESTONE"
    case fastingStage = "FASTING_STAGE"
    case fastComplete = "FAST_COMPLETE"
    case dailyReminder = "DAILY_REMINDER"
    case streakReminder = "STREAK_REMINDER"
    case motivationalQuote = "MOTIVATIONAL_QUOTE"
}

enum NotificationActionID: String {
    case extendFast = "EXTEND_FAST"
    case endFast = "END_FAST"
    case startFast = "START_FAST"
    case dismiss = "DISMISS"
}

// MARK: - Notification Manager

/// Local notification manager — scheduling, categories, smart timing, quiet hours.
@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationManager()
    
    let settings = NotificationSettings()
    
    /// Tracks whether the app is currently in the foreground
    var isAppInForeground = true
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Category Registration
    
    /// Register notification categories with actions. Call once at app launch.
    func registerCategories() {
        let extendAction = UNNotificationAction(
            identifier: NotificationActionID.extendFast.rawValue,
            title: "Extend Fast",
            options: .foreground
        )
        let endAction = UNNotificationAction(
            identifier: NotificationActionID.endFast.rawValue,
            title: "End Fast",
            options: [.foreground, .destructive]
        )
        let startAction = UNNotificationAction(
            identifier: NotificationActionID.startFast.rawValue,
            title: "Start Fast",
            options: .foreground
        )
        let dismissAction = UNNotificationAction(
            identifier: NotificationActionID.dismiss.rawValue,
            title: "Dismiss",
            options: []
        )
        
        let milestoneCategory = UNNotificationCategory(
            identifier: NotificationCategory.fastingMilestone.rawValue,
            actions: [extendAction, dismissAction],
            intentIdentifiers: []
        )
        
        let stageCategory = UNNotificationCategory(
            identifier: NotificationCategory.fastingStage.rawValue,
            actions: [dismissAction],
            intentIdentifiers: []
        )
        
        let completeCategory = UNNotificationCategory(
            identifier: NotificationCategory.fastComplete.rawValue,
            actions: [extendAction, endAction],
            intentIdentifiers: []
        )
        
        let dailyCategory = UNNotificationCategory(
            identifier: NotificationCategory.dailyReminder.rawValue,
            actions: [startAction, dismissAction],
            intentIdentifiers: []
        )
        
        let streakCategory = UNNotificationCategory(
            identifier: NotificationCategory.streakReminder.rawValue,
            actions: [startAction, dismissAction],
            intentIdentifiers: []
        )
        
        let quoteCategory = UNNotificationCategory(
            identifier: NotificationCategory.motivationalQuote.rawValue,
            actions: [dismissAction],
            intentIdentifiers: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            milestoneCategory, stageCategory, completeCategory,
            dailyCategory, streakCategory, quoteCategory
        ])
        
        logger.info("Registered notification categories")
    }
    
    // MARK: - Permission
    
    /// Current authorization status
    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }
    
    /// Cached permission status for synchronous UI checks
    private(set) var currentPermissionStatus: UNAuthorizationStatus = .notDetermined
    
    /// Refresh the cached permission status. Call on app foreground
    /// to detect if user changed notification settings externally.
    func refreshPermissionStatus() async {
        let status = await authorizationStatus()
        let previousStatus = currentPermissionStatus
        currentPermissionStatus = status
        
        if previousStatus != status {
            logger.info("Notification permission changed: \(String(describing: previousStatus)) → \(String(describing: status))")
            
            // If permission was granted and we have an active fast, reschedule notifications
            if status == .authorized {
                // Re-schedule daily reminder if enabled
                if settings.dailyReminderEnabled {
                    scheduleDailyReminder()
                }
            }
        }
    }
    
    /// Request notification permission. Returns true if granted.
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            logger.info("Notification permission: \(granted ? "granted" : "denied")")
            return granted
        } catch {
            logger.error("Notification permission error: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Foreground Notification Handling
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping @Sendable (UNNotificationPresentationOptions) -> Void
    ) {
        let category = notification.request.content.categoryIdentifier
        let identifier = notification.request.identifier
        
        // Call completionHandler synchronously to avoid sending across isolation
        completionHandler([.banner, .sound])
        
        // Fire haptics on main actor
        Task { @MainActor in
            if category == NotificationCategory.fastComplete.rawValue {
                HapticManager.shared.fastCompleted()
            } else if category == NotificationCategory.fastingMilestone.rawValue || identifier.hasPrefix("fast_milestone_") {
                HapticManager.shared.milestoneReached()
            } else if category == NotificationCategory.fastingStage.rawValue || identifier.hasPrefix("fast_stage_") {
                HapticManager.shared.stageTransition()
            }
        }
    }
    
    /// Handle notification actions (extend/end/start fast)
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping @Sendable () -> Void
    ) {
        let actionID = response.actionIdentifier
        
        Task { @MainActor in
            NotificationCenter.default.post(
                name: .notificationActionReceived,
                object: nil,
                userInfo: ["actionID": actionID]
            )
        }
        
        completionHandler()
    }
    
    // MARK: - Schedule Fasting Notifications
    
    /// Schedule all fasting-related notifications when a fast starts.
    func scheduleFastingNotifications(startDate: Date, plan: FastingPlan) {
        cancelAllFastingNotifications()
        
        let targetDuration = plan.fastingDuration
        let targetDate = startDate.addingTimeInterval(targetDuration)
        
        // 1. Milestone notifications (25%, 50%, 75%)
        if settings.milestoneEnabled {
            scheduleMilestoneNotifications(startDate: startDate, targetDuration: targetDuration)
        }
        
        // 2. Stage transition notifications
        if settings.stageTransitionEnabled {
            scheduleStageNotifications(startDate: startDate, targetDuration: targetDuration)
        }
        
        // 3. Fast complete notification
        if settings.fastCompleteEnabled {
            scheduleFastCompleteNotification(targetDate: targetDate, plan: plan)
        }
        
        // 4. Motivational quote midway through
        if settings.motivationalQuotesEnabled {
            let midpoint = startDate.addingTimeInterval(targetDuration * 0.6)
            if midpoint > Date.now {
                scheduleMotivationalQuote(at: midpoint)
            }
        }
        
        logger.info("Scheduled fasting notifications for \(plan.rawValue) plan")
    }
    
    // MARK: - Milestone Notifications (25%, 50%, 75%)
    
    private func scheduleMilestoneNotifications(startDate: Date, targetDuration: TimeInterval) {
        let milestones: [(pct: Double, title: String, body: String)] = [
            (0.25, "25% Complete 💪", "Quarter of the way there. You're doing great — stay strong!"),
            (0.50, "Halfway There! 🔥", "50% done! Your body is working hard. Keep going!"),
            (0.75, "75% Complete ⚡", "The home stretch! Only 25% left — you've got this!")
        ]
        
        for milestone in milestones {
            let triggerDate = startDate.addingTimeInterval(targetDuration * milestone.pct)
            guard triggerDate > Date.now else { continue }
            guard !isDuringQuietHours(triggerDate) else { continue }
            
            let content = makeContent(
                title: milestone.title,
                body: milestone.body,
                category: .fastingMilestone,
                interruptionLevel: .timeSensitive
            )
            
            scheduleNotification(
                id: "fast_milestone_\(Int(milestone.pct * 100))pct",
                content: content,
                date: triggerDate
            )
        }
    }
    
    // MARK: - Stage Transition Notifications
    
    private func scheduleStageNotifications(startDate: Date, targetDuration: TimeInterval) {
        let stages: [(hours: Double, stage: FastingStage, body: String)] = [
            (4, .earlyFasting, "Blood sugar is dropping and your body is switching fuel sources."),
            (12, .fatBurning, "Your body is now burning stored fat for energy! 🔥"),
            (18, .ketosis, "Ketone production is ramping up — deep metabolic benefits unlocked! ⚡"),
            (24, .autophagy, "Cellular cleanup mode activated — your cells are renewing! ✨")
        ]
        
        for stageInfo in stages {
            let triggerDate = startDate.addingTimeInterval(stageInfo.hours * 3600)
            // Only schedule if within plan duration (+2h buffer for overtime)
            guard stageInfo.hours <= (targetDuration / 3600) + 2 else { continue }
            guard triggerDate > Date.now else { continue }
            guard !isDuringQuietHours(triggerDate) else { continue }
            
            let content = makeContent(
                title: "\(stageInfo.stage.rawValue) Stage Reached \(stageInfo.stage.icon.isEmpty ? "" : "")",
                body: stageInfo.body,
                category: .fastingStage
            )
            // Use a thread identifier to group stage notifications
            content.threadIdentifier = "fasting_stages"
            
            scheduleNotification(
                id: "fast_stage_\(Int(stageInfo.hours))h",
                content: content,
                date: triggerDate
            )
        }
    }
    
    // MARK: - Fast Complete Notification
    
    private func scheduleFastCompleteNotification(targetDate: Date, plan: FastingPlan) {
        guard targetDate > Date.now else { return }
        // Fast complete is important enough to ignore quiet hours
        
        let content = makeContent(
            title: "🎉 Goal Reached!",
            body: "You've completed your \(plan.rawValue) fast! Amazing discipline. Open the app to see your results.",
            category: .fastComplete,
            interruptionLevel: .timeSensitive
        )
        
        scheduleNotification(id: "fast_complete", content: content, date: targetDate)
    }
    
    // MARK: - Motivational Quote
    
    private func scheduleMotivationalQuote(at date: Date) {
        guard !isDuringQuietHours(date) else { return }
        
        let quote = MotivationalQuotes.random()
        let content = makeContent(
            title: "💭 Stay Motivated",
            body: quote,
            category: .motivationalQuote
        )
        content.threadIdentifier = "motivational"
        
        scheduleNotification(id: "fast_motivational", content: content, date: date)
    }
    
    // MARK: - Daily Fasting Reminder
    
    /// Schedule a repeating daily reminder at the user's chosen time.
    func scheduleDailyReminder() {
        cancelDailyReminder()
        guard settings.dailyReminderEnabled else { return }
        
        var dateComponents = DateComponents()
        dateComponents.hour = settings.dailyReminderHour
        dateComponents.minute = settings.dailyReminderMinute
        
        let content = makeContent(
            title: "Time to Fast? 🍃",
            body: "Ready for your next fasting session? Tap to start.",
            category: .dailyReminder
        )
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)
        
        let hour = settings.dailyReminderHour
        let minute = settings.dailyReminderMinute
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("Failed to schedule daily reminder: \(error.localizedDescription)")
            } else {
                logger.info("Scheduled daily reminder at \(hour):\(minute)")
            }
        }
    }
    
    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
    }
    
    // MARK: - Streak Reminder
    
    /// Schedule a streak reminder for tomorrow evening if user has an active streak.
    func scheduleStreakReminder(currentStreak: Int) {
        cancelStreakReminder()
        guard settings.streakReminderEnabled, currentStreak >= 2 else { return }
        
        // Remind at 7 PM tomorrow
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date.now)
        if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date.now) {
            components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        }
        components.hour = 19
        components.minute = 0
        
        let content = makeContent(
            title: "🔥 Don't Break Your \(currentStreak)-Day Streak!",
            body: "You've been consistent for \(currentStreak) days. Start a fast today to keep it going!",
            category: .streakReminder
        )
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "streak_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("Failed to schedule streak reminder: \(error.localizedDescription)")
            } else {
                logger.info("Scheduled streak reminder for \(currentStreak)-day streak")
            }
        }
    }
    
    func cancelStreakReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["streak_reminder"])
    }
    
    // MARK: - Cancel
    
    func cancelAllFastingNotifications() {
        let ids = [
            "fast_milestone_25pct", "fast_milestone_50pct", "fast_milestone_75pct",
            "fast_stage_4h", "fast_stage_12h", "fast_stage_18h", "fast_stage_24h",
            "fast_complete", "fast_motivational"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        logger.info("Cancelled all fasting notifications")
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        logger.info("Cancelled all pending notifications")
    }
    
    // MARK: - Quiet Hours
    
    /// Check if a given date falls within the user's quiet hours.
    func isDuringQuietHours(_ date: Date) -> Bool {
        guard settings.quietHoursEnabled else { return false }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let start = settings.quietHoursStart
        let end = settings.quietHoursEnd
        
        if start < end {
            // e.g. 22:00 - 07:00 doesn't wrap — this means start > end wraps
            // Actually if start=8, end=20, quiet is 8-20
            return hour >= start && hour < end
        } else if start > end {
            // Wraps midnight: e.g. 22:00 - 07:00
            return hour >= start || hour < end
        }
        // start == end means no quiet hours
        return false
    }
    
    // MARK: - Private Helpers
    
    private func makeContent(
        title: String,
        body: String,
        category: NotificationCategory,
        interruptionLevel: UNNotificationInterruptionLevel = .active
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category.rawValue
        content.interruptionLevel = interruptionLevel
        return content
    }
    
    private func scheduleNotification(id: String, content: UNMutableNotificationContent, date: Date) {
        let interval = date.timeIntervalSince(Date.now)
        guard interval > 0 else { return }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("Failed to schedule '\(id)': \(error.localizedDescription)")
            } else {
                logger.info("Scheduled '\(id)' for \(date.formatted())")
            }
        }
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let notificationActionReceived = Notification.Name("LumifasteNotificationActionReceived")
    static let deepLinkReceived = Notification.Name("LumifasteDeepLinkReceived")
}

// MARK: - Motivational Quotes

enum MotivationalQuotes {
    
    static let quotes: [String] = [
        "Your body is getting stronger with every hour of fasting.",
        "Hunger is temporary. The benefits of fasting last a lifetime.",
        "You're not starving — you're healing.",
        "Every hour fasted is an investment in your health.",
        "Discipline is choosing between what you want now and what you want most.",
        "Your cells are thanking you right now.",
        "The only bad fast is the one you didn't start.",
        "Fasting is the greatest remedy — the physician within.",
        "You are stronger than your cravings.",
        "Right now, your body is burning fat for fuel. Keep going!",
        "Small daily improvements lead to stunning results.",
        "The discomfort you feel is your body adapting and growing stronger.",
        "Every minute of fasting counts. You're making progress.",
        "Your future self will thank you for staying strong today.",
        "Fasting isn't about deprivation — it's about liberation.",
        "The hunger wave always passes. Ride it out.",
        "You've already done the hardest part: starting.",
        "Consistency beats perfection. Show up and fast.",
        "Your metabolism is resetting. Trust the process.",
        "Think of fasting as pressing the reset button on your body.",
        "What feels hard today becomes your strength tomorrow.",
        "You're not just fasting — you're building willpower.",
        "Every completed fast is a victory over impulse.",
        "Your body has incredible healing abilities. Let it work."
    ]
    
    static func random() -> String {
        quotes.randomElement() ?? quotes[0]
    }
    
    /// Get a deterministic quote for a given day (rotates through all quotes)
    static func quoteForDate(_ date: Date = .now) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return quotes[day % quotes.count]
    }
}
