import Foundation
import UserNotifications
import OSLog

private let logger = Logger(subsystem: "com.theknack.lumifaste", category: "Notifications")

/// Local notification yöneticisi — oruç milestone'ları ve hatırlatıcılar.
@MainActor
final class NotificationManager {
    
    static let shared = NotificationManager()
    
    private init() {}
    
    // MARK: - Permission
    
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
    
    // MARK: - Schedule Fasting Notifications
    
    /// Oruç başladığında milestone notification'ları planla
    func scheduleFastingNotifications(startDate: Date, plan: FastingPlan) {
        // Önce eski notification'ları temizle
        cancelAllFastingNotifications()
        
        let milestones: [(hours: Double, title: String, body: String)] = [
            (4, "Early Fasting 🕐", "4 hours in — blood sugar is dropping. You're doing great!"),
            (12, "Fat Burning 🔥", "12 hours! Your body is now burning stored fat."),
            (16, "Sweet Sixteen! 💪", "16 hours fasted. If you're doing 16:8, you've hit your goal!"),
            (18, "Ketosis Zone ⚡", "18 hours — ketone production is ramping up."),
            (24, "Autophagy Mode ✨", "24 hours! Cellular cleanup is in full effect."),
        ]
        
        // Target completion notification
        let targetHours = plan.fastingHours
        
        for milestone in milestones {
            // Sadece plan süresine kadar olan milestone'ları planla
            guard milestone.hours <= targetHours + 2 else { continue }
            // Skip if milestone coincides with target completion (avoid double notification)
            guard abs(milestone.hours - targetHours) > 0.5 else { continue }
            
            let triggerDate = startDate.addingTimeInterval(milestone.hours * 3600)
            guard triggerDate > Date.now else { continue }
            
            scheduleNotification(
                id: "fast_milestone_\(Int(milestone.hours))h",
                title: milestone.title,
                body: milestone.body,
                date: triggerDate
            )
        }
        
        // Target completion notification
        let targetDate = startDate.addingTimeInterval(plan.fastingDuration)
        if targetDate > Date.now {
            scheduleNotification(
                id: "fast_complete",
                title: "🎉 Goal Reached!",
                body: "You've completed your \(plan.rawValue) fast! Great discipline.",
                date: targetDate
            )
        }
        
        logger.info("Scheduled fasting notifications for \(plan.rawValue) plan")
    }
    
    /// Tüm oruç notification'larını iptal et
    func cancelAllFastingNotifications() {
        let ids = [
            "fast_milestone_4h", "fast_milestone_12h", "fast_milestone_16h",
            "fast_milestone_18h", "fast_milestone_24h", "fast_complete"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        logger.info("Cancelled all fasting notifications")
    }
    
    // MARK: - Private
    
    private func scheduleNotification(id: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
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
