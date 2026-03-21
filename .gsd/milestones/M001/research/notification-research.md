# Fasting App Notification Strategy — Research Document

## Summary

Local notifications are the backbone of fasting app engagement — they remind users when fasts start/end, celebrate milestones, and keep streaks alive. The key tension is between driving engagement and annoying users into disabling notifications entirely. This document covers the full notification stack for a SwiftUI fasting app: scheduling, permission strategy, copy, timing, actions, rich media, grouping, badge counts, and lessons from top fasting apps.

---

## Table of Contents

1. [Local Notification Scheduling](#1-local-notification-scheduling)
2. [UNUserNotificationCenter Best Practices in SwiftUI](#2-unusernotificationcenter-best-practices-in-swiftui)
3. [Notification Copy That Drives Engagement](#3-notification-copy-that-drives-engagement)
4. [Optimal Timing and Frequency](#4-optimal-timing-and-frequency)
5. [Notification Categories and Actions](#5-notification-categories-and-actions)
6. [Provisional vs Full Permission](#6-provisional-vs-full-permission)
7. [Rich Notifications](#7-rich-notifications)
8. [Notification Grouping and Summary](#8-notification-grouping-and-summary)
9. [How Top Fasting Apps Handle Notifications](#9-how-top-fasting-apps-handle-notifications)
10. [Badge Count Strategy](#10-badge-count-strategy)

---

## 1. Local Notification Scheduling

### Trigger Types for Fasting

iOS provides three trigger types. A fasting app uses all three:

| Trigger | Use Case | Example |
|---|---|---|
| `UNTimeIntervalNotificationTrigger` | Relative to fast start | "1 hour left!" after N seconds |
| `UNCalendarNotificationTrigger` | Daily reminders | "Time to start your 16:8 fast" at 8pm |
| `UNLocationNotificationTrigger` | Geofenced (rare) | Not typical for fasting |

### Core Scheduling Pattern

```swift
import UserNotifications

final class FastingNotificationScheduler {
    
    static let shared = FastingNotificationScheduler()
    private let center = UNUserNotificationCenter.current()
    
    // MARK: - Schedule Fast End Notification
    
    /// Schedules a notification for when the fasting window ends.
    /// Called when the user starts a fast.
    func scheduleFastEndNotification(
        fastEndDate: Date,
        fastingHours: Int
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Fast Complete! 🎉"
        content.body = "You crushed your \(fastingHours)-hour fast. Time to eat!"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.fastEnd
        content.userInfo = [
            "type": "fast_end",
            "fastingHours": fastingHours
        ]
        content.threadIdentifier = "fasting-timer"
        
        let timeInterval = fastEndDate.timeIntervalSinceNow
        guard timeInterval > 0 else { return }
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "fast-end-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error {
                print("Failed to schedule fast end notification: \(error)")
            }
        }
    }
    
    // MARK: - Schedule Milestone Notifications During Fast
    
    /// Schedules progress check-ins at key fasting milestones.
    /// E.g., at 12h (autophagy begins), 16h (fat burning peak), etc.
    func scheduleMilestoneNotifications(
        fastStartDate: Date,
        fastDurationHours: Int
    ) {
        // Milestones as (hours, title, body)
        let milestones: [(hours: Int, title: String, body: String)] = [
            (12, "12 Hours In 🔥", "Your body is switching to fat-burning mode."),
            (16, "16 Hours — Deep Ketosis", "Growth hormone is rising. Stay strong!"),
            (18, "18 Hours — Autophagy Active 🧬", "Cellular cleanup is underway."),
            (24, "24 Hours — One Full Day! 💪", "You've fasted a full day. Incredible.")
        ]
        
        for milestone in milestones where milestone.hours < fastDurationHours {
            let fireDate = fastStartDate.addingTimeInterval(
                TimeInterval(milestone.hours * 3600)
            )
            guard fireDate > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = milestone.title
            content.body = milestone.body
            content.sound = .default
            content.categoryIdentifier = NotificationCategory.milestone
            content.threadIdentifier = "fasting-timer"
            content.userInfo = [
                "type": "milestone",
                "hours": milestone.hours
            ]
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: fireDate.timeIntervalSinceNow,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "milestone-\(milestone.hours)h",
                content: content,
                trigger: trigger
            )
            
            center.add(request)
        }
    }
    
    // MARK: - Schedule Daily Fasting Reminder
    
    /// Recurring reminder to start fasting at a user-chosen time.
    func scheduleDailyFastingReminder(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Fast ⏰"
        content.body = "Ready to start your fasting window?"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.fastReminder
        content.threadIdentifier = "fasting-reminders"
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "daily-fast-reminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    // MARK: - Cancel All Fasting Notifications
    
    /// Call when user manually ends a fast early.
    func cancelAllFastingNotifications() {
        center.removePendingNotificationRequests(
            withIdentifiers: ["fast-end-notification"]
        )
        // Remove milestone notifications
        let milestoneIDs = [12, 16, 18, 24].map { "milestone-\($0)h" }
        center.removePendingNotificationRequests(withIdentifiers: milestoneIDs)
    }
    
    /// Remove all pending and delivered notifications.
    func removeAll() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
}
```

### Key Constraints

- **64 notification limit**: iOS allows a maximum of 64 locally scheduled notifications per app. The system keeps the 64 soonest-firing ones. For a fasting app this is generous, but be mindful if scheduling recurring daily + milestone + motivational notifications.
- **Repeating interval minimum**: `UNTimeIntervalNotificationTrigger` with `repeats: true` requires a minimum interval of 60 seconds.
- **Calendar triggers**: Use `UNCalendarNotificationTrigger` for daily/weekly recurring reminders. Only specify the date components you need (hour + minute for daily).
- **Cancellation on fast-end**: When a user ends a fast early, immediately cancel all pending milestone and fast-end notifications. Use stable identifiers (not random UUIDs) for notifications you need to cancel individually.

---

## 2. UNUserNotificationCenter Best Practices in SwiftUI

### Architecture: AppDelegate + NotificationManager

SwiftUI doesn't have a native notification delegate mechanism. The standard pattern uses `@UIApplicationDelegateAdaptor` to bridge into UIKit's `AppDelegate`:

```swift
// App.swift
import SwiftUI

@main
struct FastingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// AppDelegate.swift
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set delegate BEFORE app finishes launching — critical
        UNUserNotificationCenter.current().delegate = self
        
        // Register notification categories early
        NotificationCategoryManager.shared.registerCategories()
        
        return true
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    /// Called when notification arrives while app is in foreground.
    /// Without this, foreground notifications are silently suppressed.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show banner + sound even when app is open
        // For a fasting app, the user may have the app open
        // when their fast ends — they should still see it
        return [.banner, .sound, .list]
    }
    
    /// Called when user taps a notification or an action button.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself
            handleNotificationTap(userInfo: userInfo)
            
        case UNNotificationDismissActionIdentifier:
            // User swiped to dismiss
            break
            
        case NotificationAction.snooze:
            handleSnooze(userInfo: userInfo)
            
        case NotificationAction.endFast:
            handleEndFast(userInfo: userInfo)
            
        case NotificationAction.extendFast:
            handleExtendFast(userInfo: userInfo)
            
        default:
            break
        }
    }
    
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }
        // Deep link to the appropriate screen
        NotificationCenter.default.post(
            name: .didTapNotification,
            object: nil,
            userInfo: ["type": type]
        )
    }
    
    private func handleSnooze(userInfo: [AnyHashable: Any]) {
        // Reschedule the reminder for 30 minutes later
        let content = UNMutableNotificationContent()
        content.title = "Reminder: Start Your Fast"
        content.body = "Snoozed reminder — ready now?"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.fastReminder
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 30 * 60, // 30 minutes
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "snoozed-reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func handleEndFast(userInfo: [AnyHashable: Any]) {
        // Post to the app's state management to end the current fast
        NotificationCenter.default.post(
            name: .didEndFastFromNotification,
            object: nil
        )
    }
    
    private func handleExtendFast(userInfo: [AnyHashable: Any]) {
        // Extend by 2 hours, reschedule end notification
        NotificationCenter.default.post(
            name: .didExtendFastFromNotification,
            object: nil,
            userInfo: ["extensionHours": 2]
        )
    }
}

extension Notification.Name {
    static let didTapNotification = Notification.Name("didTapNotification")
    static let didEndFastFromNotification = Notification.Name("didEndFastFromNotification")
    static let didExtendFastFromNotification = Notification.Name("didExtendFastFromNotification")
}
```

### NotificationManager as ObservableObject

```swift
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    private let center = UNUserNotificationCenter.current()
    
    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }
    
    func requestAuthorization() async throws -> Bool {
        let granted = try await center.requestAuthorization(
            options: [.alert, .badge, .sound]
        )
        await refreshAuthorizationStatus()
        return granted
    }
    
    func requestProvisionalAuthorization() async throws -> Bool {
        let granted = try await center.requestAuthorization(
            options: [.alert, .badge, .sound, .provisional]
        )
        await refreshAuthorizationStatus()
        return granted
    }
    
    func loadPendingNotifications() async {
        pendingNotifications = await center.pendingNotificationRequests()
    }
}
```

### Critical Rules

1. **Set the delegate before `application(_:didFinishLaunchingWithOptions:)` returns.** If a notification arrives before the delegate is set, the response is lost.
2. **Always implement `willPresent`** to show notifications while the app is in the foreground. Without it, foreground notifications are silently dropped.
3. **Use async/await versions** of the APIs (available since iOS 15+). The completion-handler versions work but are harder to compose.
4. **Check authorization status before scheduling** — don't schedule notifications if the user has denied permission. Check both `.authorized` and `.provisional`.

---

## 3. Notification Copy That Drives Engagement

### Principles for Health App Notifications

Based on analysis of successful health and fasting apps:

1. **Be a coach, not an alarm** — Motivate, don't nag
2. **Use progress language** — "You're X hours in" not "You should be fasting"
3. **Celebrate milestones** — Positive reinforcement at key moments
4. **Be scientifically grounded** — Brief health facts build trust
5. **Keep it short** — iOS truncates at ~110 characters for body text
6. **Use emoji sparingly** — One emoji per notification, in the title

### Notification Copy Library

#### Fast Start Reminders
| Title | Body |
|---|---|
| Time to Fast ⏰ | Your fasting window starts now. Tap to begin your timer. |
| Evening Reminder | Close the kitchen and start your overnight fast. You've got this. |
| Fast Starting Soon | Your {duration}h fast begins in 30 minutes. Finish up eating! |

#### During-Fast Encouragement
| Title | Body | Trigger |
|---|---|---|
| 12 Hours In 🔥 | Fat-burning mode activated. Your body is switching fuel sources. | 12h mark |
| Halfway There! | {X} hours down, {Y} to go. Keep going — momentum is on your side. | 50% mark |
| 16 Hours — Deep Ketosis | Growth hormone levels are climbing. Your body is in repair mode. | 16h mark |
| Autophagy Active 🧬 | At 18 hours, cellular cleanup kicks in. You're investing in longevity. | 18h mark |
| Almost Done 💪 | Just 1 hour left in your fast. The finish line is in sight! | 1h before end |

#### Fast Complete
| Title | Body |
|---|---|
| Fast Complete! 🎉 | You finished your {X}h fast. Time to refuel with something nutritious. |
| {X}-Hour Fast — Done! | Another fast in the books. Your {streak}-day streak continues! |
| You Did It 🏆 | {X} hours fasted. That's discipline. Tap to log how you feel. |

#### Streak & Motivation
| Title | Body |
|---|---|
| 🔥 {N}-Day Streak! | You've fasted {N} days in a row. Consistency compounds. |
| Don't Break the Chain | You fasted yesterday — keep it going today. |
| Weekly Recap | You fasted {X} hours this week across {Y} sessions. That's {Z}% more than last week. |

#### Re-engagement (for lapsed users)
| Title | Body |
|---|---|
| We Miss You | It's been {N} days since your last fast. Ready to jump back in? |
| Quick Win | Even a 12-hour overnight fast has real benefits. Start small today. |

### Copy Anti-Patterns to Avoid

- ❌ "You haven't fasted today!" (guilt-tripping)
- ❌ "Don't give up!" (implies they're failing)
- ❌ "WARNING: You broke your streak" (punitive)
- ❌ Multiple exclamation marks or ALL CAPS
- ❌ Generic "Open the app!" with no value proposition

### A/B Testing Recommendations

Test these variables:
- **Tone**: Coaching vs. scientific vs. casual
- **Emoji**: With vs. without in title
- **Personalization**: Name included vs. generic
- **Specificity**: "12 hours" vs. "halfway there"

---

## 4. Optimal Timing and Frequency

### Frequency Guidelines

Research shows that excessive notifications are the #1 reason users disable them. For a fasting app:

| Notification Type | Frequency | Rationale |
|---|---|---|
| Fast start reminder | 1x daily (user-chosen time) | Essential — the core value prop |
| Fast end alert | 1x per fast | Essential — must-have |
| Milestone check-ins | 2-3 per fast max | More than 3 feels spammy during a fast |
| Streak notifications | 1x daily max | Only when streak is active |
| Re-engagement | 1x per 3 days max | Back off if ignored |
| Weekly summary | 1x per week | Sunday evening works well |

**Total budget**: No more than 3-5 notifications per day during an active fast. On non-fasting days, zero or one at most.

### Timing Best Practices

1. **Respect quiet hours**: Never send between 10pm–7am unless it's a fast-end notification the user explicitly scheduled. iOS Focus modes will suppress many notifications, but don't rely on this.

2. **User-chosen times**: Let users pick their reminder time. Don't assume a schedule. Fasting patterns vary wildly (16:8, 20:4, OMAD, 5:2).

3. **Smart suppression**: If the user has the app open, consider not showing a banner (use `.list` only in `willPresent`). They're already engaged.

4. **Frequency capping**: Track notifications sent per day. If 3+ have been sent today, skip the motivational ones. Keep only functional notifications (fast start/end).

5. **Back off on dismissals**: If a user dismisses 3 notifications in a row without tapping them, reduce frequency for that notification type.

```swift
/// Simple frequency cap — track in UserDefaults or your persistence layer
struct NotificationFrequencyManager {
    
    private static let dailyCapKey = "notification_daily_count"
    private static let lastResetKey = "notification_last_reset"
    private static let maxDailyNotifications = 5
    
    static func canSendNotification() -> Bool {
        resetIfNewDay()
        let count = UserDefaults.standard.integer(forKey: dailyCapKey)
        return count < maxDailyNotifications
    }
    
    static func recordNotificationSent() {
        resetIfNewDay()
        let count = UserDefaults.standard.integer(forKey: dailyCapKey)
        UserDefaults.standard.set(count + 1, forKey: dailyCapKey)
    }
    
    private static func resetIfNewDay() {
        let lastReset = UserDefaults.standard.object(forKey: lastResetKey) as? Date ?? .distantPast
        if !Calendar.current.isDateInToday(lastReset) {
            UserDefaults.standard.set(0, forKey: dailyCapKey)
            UserDefaults.standard.set(Date(), forKey: lastResetKey)
        }
    }
}
```

### User Notification Preferences UI

Let users control granularity:

```swift
struct NotificationPreferences: Codable {
    var fastStartReminder: Bool = true
    var fastStartTime: DateComponents? // user-chosen
    var fastEndAlert: Bool = true
    var milestoneUpdates: Bool = true
    var streakReminders: Bool = true
    var weeklyDigest: Bool = true
    var motivationalMessages: Bool = false // opt-in, not default
    var quietHoursStart: Int = 22 // 10pm
    var quietHoursEnd: Int = 7   // 7am
}
```

---

## 5. Notification Categories and Actions

### Category Architecture for a Fasting App

Categories group related notifications and define action buttons. Register them at app launch.

```swift
import UserNotifications

enum NotificationCategory {
    static let fastReminder = "FAST_REMINDER"
    static let fastEnd = "FAST_END"
    static let milestone = "FAST_MILESTONE"
    static let streak = "STREAK"
    static let reEngagement = "RE_ENGAGEMENT"
}

enum NotificationAction {
    static let startFast = "START_FAST"
    static let snooze = "SNOOZE_30MIN"
    static let endFast = "END_FAST"
    static let extendFast = "EXTEND_FAST"
    static let logMood = "LOG_MOOD"
    static let dismiss = "DISMISS"
}

final class NotificationCategoryManager {
    
    static let shared = NotificationCategoryManager()
    
    func registerCategories() {
        let center = UNUserNotificationCenter.current()
        
        // --- Fast Reminder Category ---
        let startAction = UNNotificationAction(
            identifier: NotificationAction.startFast,
            title: "Start Fast",
            options: .foreground, // opens the app
            icon: UNNotificationActionIcon(systemImageName: "timer")
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: NotificationAction.snooze,
            title: "Snooze 30min",
            options: [], // runs in background
            icon: UNNotificationActionIcon(systemImageName: "clock.badge.questionmark")
        )
        
        let reminderCategory = UNNotificationCategory(
            identifier: NotificationCategory.fastReminder,
            actions: [startAction, snoozeAction],
            intentIdentifiers: [],
            options: .customDismissAction // track when user explicitly dismisses
        )
        
        // --- Fast End Category ---
        let endFastAction = UNNotificationAction(
            identifier: NotificationAction.endFast,
            title: "End Fast",
            options: .foreground,
            icon: UNNotificationActionIcon(systemImageName: "checkmark.circle")
        )
        
        let extendAction = UNNotificationAction(
            identifier: NotificationAction.extendFast,
            title: "Extend 2hrs",
            options: [], // background — reschedule without opening app
            icon: UNNotificationActionIcon(systemImageName: "plus.circle")
        )
        
        let fastEndCategory = UNNotificationCategory(
            identifier: NotificationCategory.fastEnd,
            actions: [endFastAction, extendAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // --- Milestone Category ---
        let logMoodAction = UNNotificationAction(
            identifier: NotificationAction.logMood,
            title: "Log How I Feel",
            options: .foreground,
            icon: UNNotificationActionIcon(systemImageName: "face.smiling")
        )
        
        let milestoneCategory = UNNotificationCategory(
            identifier: NotificationCategory.milestone,
            actions: [logMoodAction],
            intentIdentifiers: [],
            options: []
        )
        
        // --- Streak Category (no actions, just informational) ---
        let streakCategory = UNNotificationCategory(
            identifier: NotificationCategory.streak,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        // --- Re-engagement Category ---
        let startAction2 = UNNotificationAction(
            identifier: NotificationAction.startFast,
            title: "Start a Fast",
            options: .foreground,
            icon: UNNotificationActionIcon(systemImageName: "flame")
        )
        
        let reEngagementCategory = UNNotificationCategory(
            identifier: NotificationCategory.reEngagement,
            actions: [startAction2],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([
            reminderCategory,
            fastEndCategory,
            milestoneCategory,
            streakCategory,
            reEngagementCategory
        ])
    }
}
```

### Action Design Principles

1. **Maximum 4 actions per category** — iOS shows up to 4 on long-press. Use 2-3 for clarity.
2. **Mark destructive actions**: Use `.destructive` for actions like "End Fast" that can't be undone. This renders the button in red.
3. **Background vs foreground**: Snooze and extend can run in background (`.options: []`). "Start Fast" and "Log Mood" should open the app (`.foreground`).
4. **Action icons**: Available since iOS 15. Use SF Symbols for consistency.
5. **`.customDismissAction`**: Opt into this on categories where you want to track explicit dismissals. Without it, dismiss events are not reported to your delegate.

---

## 6. Provisional Notifications vs Full Permission

### The Permission Dilemma

iOS gives you one shot at the permission prompt. If the user taps "Don't Allow," you can only direct them to Settings. The industry average opt-in rate for iOS is 29–73% depending on category.

### Strategy: Progressive Permission

**Recommended approach for a fasting app: Start provisional → prove value → upgrade to full.**

```swift
@MainActor
final class NotificationPermissionManager: ObservableObject {
    
    @Published var status: UNAuthorizationStatus = .notDetermined
    
    private let center = UNUserNotificationCenter.current()
    
    // MARK: - Phase 1: Provisional (on first launch, no prompt)
    
    /// Call on first app launch. No dialog appears.
    /// Notifications go to Notification Center silently.
    func requestProvisionalAccess() async {
        do {
            try await center.requestAuthorization(
                options: [.alert, .badge, .sound, .provisional]
            )
            await refreshStatus()
        } catch {
            print("Provisional auth error: \(error)")
        }
    }
    
    // MARK: - Phase 2: Full (after user sees value)
    
    /// Call after the user completes their first fast,
    /// or after 3 days of use — when they understand the value
    /// of timely notifications.
    func upgradeToFullPermission() async -> Bool {
        let settings = await center.notificationSettings()
        
        // Only upgrade if currently provisional
        guard settings.authorizationStatus == .provisional else {
            return settings.authorizationStatus == .authorized
        }
        
        do {
            // This WILL show the system prompt
            let granted = try await center.requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            await refreshStatus()
            return granted
        } catch {
            return false
        }
    }
    
    func refreshStatus() async {
        let settings = await center.notificationSettings()
        status = settings.authorizationStatus
    }
    
    /// Check if we can send notifications (either provisional or full)
    var canSendNotifications: Bool {
        status == .authorized || status == .provisional
    }
}
```

### When to Upgrade: Contextual Permission Asking

```swift
// In your fasting completion view:
struct FastCompleteView: View {
    @EnvironmentObject var permissionManager: NotificationPermissionManager
    @State private var showPermissionExplainer = false
    
    var body: some View {
        VStack {
            Text("Fast Complete! 🎉")
                .font(.largeTitle)
            
            // ... celebration UI ...
        }
        .onAppear {
            if permissionManager.status == .provisional {
                // Show after a brief delay so user absorbs the celebration
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showPermissionExplainer = true
                }
            }
        }
        .sheet(isPresented: $showPermissionExplainer) {
            NotificationUpgradeSheet(permissionManager: permissionManager)
        }
    }
}

struct NotificationUpgradeSheet: View {
    let permissionManager: NotificationPermissionManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "bell.badge")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            
            Text("Never Miss a Fast")
                .font(.title2.bold())
            
            VStack(alignment: .leading, spacing: 12) {
                BenefitRow(icon: "timer", text: "Get alerts when your fast ends")
                BenefitRow(icon: "flame", text: "See milestone updates as you fast")
                BenefitRow(icon: "trophy", text: "Track your streak with daily reminders")
            }
            
            Button("Enable Notifications") {
                Task {
                    _ = await permissionManager.upgradeToFullPermission()
                    dismiss()
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("Not Now") {
                dismiss()
            }
            .foregroundStyle(.secondary)
        }
        .padding()
    }
}
```

### Provisional vs Full — Trade-offs

| Aspect | Provisional | Full |
|---|---|---|
| User prompt | None | System dialog (one chance) |
| Lock screen | ❌ Not shown | ✅ Shown |
| Banner | ❌ Not shown | ✅ Shown |
| Notification Center | ✅ Shown (with Keep/Turn Off) | ✅ Shown |
| Sound | ❌ Silent | ✅ Plays |
| Badge | ❌ Not set | ✅ Set |
| Best for | Proving value before asking | After user understands benefits |

### Recommendation

For a fasting app, use a **two-phase approach**:

1. **Day 1**: Request provisional. Schedule a welcome notification ("Your first fast tip") so the user sees it in Notification Center and can choose "Keep → Deliver Prominently."
2. **After first completed fast**: Show a custom pre-permission screen explaining what notifications will do, then trigger the real system prompt.

This avoids the cold-prompt problem where users deny permissions reflexively because they don't yet know why the app needs them.

---

## 7. Rich Notifications with Images/Progress

### Notification Service Extension

To add images, you need a Notification Service Extension (for remote notifications) or attach media directly for local notifications:

```swift
// For local notifications — attach an image from the app bundle
func scheduleRichMilestoneNotification(
    hours: Int,
    imageName: String
) {
    let content = UNMutableNotificationContent()
    content.title = "\(hours) Hours Complete!"
    content.body = "Check your fasting zone progress."
    content.categoryIdentifier = NotificationCategory.milestone
    content.threadIdentifier = "fasting-timer"
    
    // Attach an image
    if let imageURL = Bundle.main.url(forResource: imageName, withExtension: "png") {
        do {
            let attachment = try UNNotificationAttachment(
                identifier: "milestone-image",
                url: imageURL,
                options: [
                    UNNotificationAttachmentOptionsTypeHintKey: "public.png"
                ]
            )
            content.attachments = [attachment]
        } catch {
            print("Failed to create attachment: \(error)")
        }
    }
    
    let trigger = UNTimeIntervalNotificationTrigger(
        timeInterval: 5,
        repeats: false
    )
    
    let request = UNNotificationRequest(
        identifier: "rich-milestone-\(hours)",
        content: content,
        trigger: trigger
    )
    
    UNUserNotificationCenter.current().add(request)
}
```

### Notification Content Extension (Custom UI)

For fully custom notification UIs (e.g., a fasting progress ring), create a Notification Content Extension:

**Info.plist of the extension:**
```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>UNNotificationExtensionCategory</key>
        <array>
            <string>FAST_END</string>
            <string>FAST_MILESTONE</string>
        </array>
        <key>UNNotificationExtensionInitialContentSizeRatio</key>
        <real>0.5</real>
        <key>UNNotificationExtensionDefaultContentHidden</key>
        <true/>
    </dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.usernotifications.content-extension</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).NotificationViewController</string>
</dict>
```

**Content Extension ViewController:**
```swift
import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {
    
    @IBOutlet weak var progressRing: CircularProgressView!
    @IBOutlet weak var hoursLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    func didReceive(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        
        if let hours = userInfo["hours"] as? Int,
           let totalHours = userInfo["totalFastHours"] as? Int {
            
            let progress = Double(hours) / Double(totalHours)
            progressRing.setProgress(progress, animated: true)
            hoursLabel.text = "\(hours)h / \(totalHours)h"
            statusLabel.text = fastingZoneLabel(for: hours)
        }
    }
    
    func didReceive(
        _ response: UNNotificationResponse,
        completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void
    ) {
        switch response.actionIdentifier {
        case NotificationAction.endFast:
            completion(.dismissAndForwardAction)
        case NotificationAction.extendFast:
            // Update the UI to show the extension
            statusLabel.text = "Extended by 2 hours!"
            completion(.doNotDismiss)
        default:
            completion(.dismiss)
        }
    }
    
    private func fastingZoneLabel(for hours: Int) -> String {
        switch hours {
        case 0..<12: return "Anabolic Zone"
        case 12..<16: return "Catabolic Zone"
        case 16..<24: return "Fat Burning Zone"
        case 24..<48: return "Deep Ketosis Zone"
        default: return "Extended Fast Zone"
        }
    }
}
```

### Image Attachment Limits

| Media Type | Max Size | Format |
|---|---|---|
| Image | 10 MB | JPEG, GIF, PNG |
| Audio | 5 MB | AIFF, WAV, MP3, M4A |
| Video | 50 MB | MPEG, MPEG2, MP4, AVI |

For a fasting app, pre-bundle milestone images (progress rings, zone illustrations) in the app. Keep them under 1 MB for fast loading.

---

## 8. Notification Grouping and Summary

### Thread Identifiers

Group related notifications using `threadIdentifier`:

```swift
// All fasting timer notifications group together
content.threadIdentifier = "fasting-timer"

// Daily reminders group separately
content.threadIdentifier = "fasting-reminders"

// Streak/achievement notifications group separately
content.threadIdentifier = "fasting-achievements"
```

### Summary Grouping (iOS 15+)

Customize the summary text when notifications are grouped:

```swift
// When registering categories, configure the summary format
let milestoneCategory = UNNotificationCategory(
    identifier: NotificationCategory.milestone,
    actions: [logMoodAction],
    intentIdentifiers: [],
    hiddenPreviewsBodyPlaceholder: "Fasting update",
    categorySummaryFormat: "%u fasting updates",
    options: []
)
```

When 3+ milestone notifications stack, the summary shows: **"3 fasting updates"** instead of showing each one individually.

### Grouping Strategy for Fasting Apps

| Thread ID | Groups | Summary Format |
|---|---|---|
| `fasting-timer` | Fast end, milestones during active fast | "%u fasting updates" |
| `fasting-reminders` | Daily start reminders, snooze follow-ups | "Fasting reminders" |
| `fasting-achievements` | Streaks, personal bests, weekly recaps | "%u achievements" |

### Replacing vs Stacking

For some notifications, you want to **replace** the previous one rather than stacking. Use a stable identifier:

```swift
// This notification replaces the previous "fast-progress" notification
// instead of creating a new one in the stack
let request = UNNotificationRequest(
    identifier: "fast-progress", // stable ID = replacement
    content: content,
    trigger: trigger
)
```

This is useful for progress updates — you don't want 5 stacked "X hours in" notifications. Replace them so only the latest shows.

---

## 9. How Top Fasting Apps Handle Notifications

### Analysis Based on User Reviews and App Behavior

#### Zero (Fasting & Health Tracker)
- **Approach**: Minimal notifications. Timer notifications and reminders are available but not aggressive.
- **User feedback**: Some users explicitly praise the app for not being annoying with notifications. However, reviews also note that notification settings can be buggy — "Zero wouldn't update the settings I had left for the notifications" was a common complaint. A Google Play review noted the app would "still remind me 'only one hour to go!' despite the fast being over."
- **Lesson**: **Notification reliability is critical.** Cancel pending notifications immediately when a fast ends early. Stale notifications destroy trust.

#### Fastic
- **Approach**: Aggressive engagement strategy using MoEngage platform. Personalized push, in-app, and email across the user lifecycle. Uses "Happy Moments" tied to milestones (weight loss achievements) to time positive notifications.
- **Strategy**: Welcome series for new users over multiple days. Re-engagement "Welcome Back Offer" for lapsed users with 35% resubscription rate.
- **Lesson**: **Milestone-based positive notifications work.** Time them to achievements, not arbitrary schedules.

#### DoFasting
- **Approach**: Daily reminders about fast start/end. Positioned as "set it and forget it" — users appreciate that notifications "help keep you from clock-watching."
- **User feedback**: Notifications framed as helpful coaching rather than nagging. Timer notifications described as making "fast maintenance an afterthought."
- **Lesson**: **Notifications should reduce cognitive load**, not add to it. "Your fast ends in 1 hour" is helpful. "Don't forget to fast!" is nagging.

#### Easy Fast
- **Approach**: Simple, user-controlled notifications. Users praise the app for being non-intrusive.
- **User feedback**: One user specifically requested "an active notification in the notification bar" as a persistent progress indicator — showing that some users actually *want* more notification presence when it shows progress.
- **Lesson**: **Offer persistent/live notification as opt-in** for power users who want ongoing progress display.

#### BodyFast
- **Approach**: Automatic timer that runs on schedule. Notifications tied to scheduled fasts.
- **User feedback**: Frustrating for users with variable schedules — "if you start and end your fasts at varying times throughout the week" the automatic approach doesn't work.
- **Lesson**: **Don't assume a fixed schedule.** Let users trigger fast start/end manually. Notifications should adapt to actual behavior, not a preset plan.

### Consolidated Lessons from User Reviews

| Pattern | User Sentiment | Our Strategy |
|---|---|---|
| Stale notifications after ending fast early | Very negative — feels broken | Cancel all pending on fast end |
| Persistent progress notification | Requested by power users | Offer as opt-in via Live Activities |
| Too many upgrade prompts via notifications | "I'm deleting and switching" | Never use notifications for upselling |
| Unreliable notification settings | Frustrating, erodes trust | Verify settings with `getNotificationSettings()` |
| Milestone celebrations | Motivating, drives engagement | Core strategy — celebrate every milestone |
| Nagging tone | Causes opt-out | Coach, don't nag. Progress-oriented copy. |

---

## 10. Badge Count Strategy

### What the Badge Should Represent

The badge count should represent **actionable items** the user should address, not a notification counter. For a fasting app:

```swift
final class BadgeManager {
    
    static func updateBadge() async {
        var count = 0
        
        // Badge reasons:
        // 1. Completed fast not yet reviewed/logged
        if await hasUnreviewedCompletedFast() {
            count += 1
        }
        
        // 2. Streak at risk (didn't fast today, still time)
        if await isStreakAtRisk() {
            count += 1
        }
        
        // 3. Weekly summary ready to view
        if await hasUnreadWeeklySummary() {
            count += 1
        }
        
        await setBadge(count)
    }
    
    static func clearBadge() async {
        await setBadge(0)
    }
    
    @MainActor
    private static func setBadge(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }
    
    // ... data fetching methods ...
}
```

### Badge Rules

1. **Clear on app open**: Reset the badge when the user opens the app. Stale badges are worse than no badges.
2. **Low numbers only**: Badge counts over 5 lose meaning. Cap at 3-5 for a fasting app.
3. **Never use as marketing**: Don't set badge = 1 to lure users back. Only for genuine actionable items.
4. **Set via `setBadgeCount`**: Since iOS 16, use `UNUserNotificationCenter.setBadgeCount(_:)` instead of `UIApplication.shared.applicationIconBadgeNumber` (deprecated).

```swift
// Clear badge when app becomes active
// In your App or root view:
.onReceive(NotificationCenter.default.publisher(
    for: UIApplication.didBecomeActiveNotification
)) { _ in
    Task {
        await BadgeManager.clearBadge()
    }
}
```

### Badge Count Scenarios for Fasting App

| Scenario | Badge | Rationale |
|---|---|---|
| Fast completed, not logged | 1 | Action needed: log/review |
| Streak at risk today | 1 | Time-sensitive action |
| User opens app | 0 | Clear immediately |
| 3 unread milestone achievements | 1 (not 3) | Group achievements as one action |
| User is mid-fast | 0 | No action needed — they're engaged |
| App is fully caught up | 0 | Clean state |

---

## Implementation Priority

For a fasting app MVP, implement in this order:

1. **Fast start/end notifications** (essential — the core timer feature)
2. **Permission management** (provisional → full upgrade flow)
3. **Notification categories + actions** (snooze, end fast, extend)
4. **Milestone notifications** (12h, 16h, 18h markers)
5. **Daily reminder scheduling** (user-configurable time)
6. **Badge management** (clear on open, set for actionable items)
7. **Notification grouping** (thread identifiers)
8. **Streak notifications** (daily streak encouragement)
9. **Rich notifications** (images for milestones)
10. **Content extension** (custom progress ring UI)
11. **Re-engagement notifications** (for lapsed users)
12. **Weekly summary** (once enough data exists)

---

## Sources

1. Apple Developer Documentation — UNUserNotificationCenter
2. Hacking with Swift — Scheduling Notifications and Acting on Responses
3. Use Your Loaf — Provisional Authorization of User Notifications (Feb 2025)
4. Nil Coalescing — Sending Trial Notifications with Provisional Authorization (Mar 2024)
5. Nil Coalescing — Notification Action Buttons with Images
6. Alexander Weiss / Teabyte — Push Notifications in SwiftUI (Feb 2025)
7. tanaschita.com — How to Add Custom Actions to iOS Notifications in SwiftUI
8. OneUptime — iOS Push Notifications in Swift (Feb 2026)
9. Pushwoosh — 2025 Best Push Notification Strategies
10. Reteno — 14 Push Notification Best Practices for 2026
11. GetStream — How to Engage App Users with Push Notification Marketing
12. Storyly — 7 Push Notification Strategies for App Engagement
13. Fastic / MoEngage Case Study — Customer Engagement Platform Partnership (Sep 2024)
14. Zero Fasting — App Store Reviews and User Feedback
15. DoFasting / Innerbody Research — Fasting App Comparison Reviews
16. Easy Fast — App Store Reviews
17. Phiture — Provisional Push: Impact on Addressable Audience
18. Medium / Shobhakar Tiwari — iOS Push Notifications: Stop Asking Permission on Day One
