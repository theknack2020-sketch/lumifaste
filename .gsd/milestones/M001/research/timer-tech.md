# Timer & Countdown Implementation — Technical Research

> Research for a fasting app's timer system on iOS/SwiftUI.
> Covers background execution, notifications, Live Activities, timer precision, and battery optimization.

---

## Summary

iOS does not allow timers to run continuously in the background. The correct architecture for a fasting countdown is **timestamp-based**: persist the start time and end time, then compute remaining time on-the-fly whenever the UI is visible. Local notifications handle the "timer done" alert, and Live Activities provide a glanceable countdown on the Lock Screen / Dynamic Island without waking the app. The timer display in-app uses `Timer.publish` from Combine for simple 1-second UI ticks, while the actual elapsed time is always derived from `Date()` math — never from counting tick callbacks.

---

## 1. Reliable Countdown Timer (Survives Background & Kill)

### Core Principle: Persist Timestamps, Not Counters

The fundamental pattern every production timer app uses: **store the `startDate` and `targetEndDate` to persistent storage (UserDefaults, Core Data, or SwiftData), then recompute the remaining time from `Date.now` whenever the app returns to the foreground.**

A timer that decrements a counter variable by 1 each second will drift, lose state when backgrounded, and break completely when the app is killed.

```swift
// FastingTimer.swift — Timestamp-based timer model
import Foundation
import SwiftUI

@Observable
class FastingTimer {
    // Persisted state
    var startDate: Date? {
        didSet { UserDefaults.standard.set(startDate, forKey: "fasting_start") }
    }
    var targetEndDate: Date? {
        didSet { UserDefaults.standard.set(targetEndDate, forKey: "fasting_end") }
    }
    var isActive: Bool {
        didSet { UserDefaults.standard.set(isActive, forKey: "fasting_active") }
    }
    
    // Computed — always derived from real clock
    var remainingSeconds: TimeInterval {
        guard let end = targetEndDate, isActive else { return 0 }
        return max(0, end.timeIntervalSince(.now))
    }
    
    var elapsedSeconds: TimeInterval {
        guard let start = startDate, isActive else { return 0 }
        return Date.now.timeIntervalSince(start)
    }
    
    var isComplete: Bool { isActive && remainingSeconds <= 0 }
    
    init() {
        // Restore from persistence on launch (survives kill)
        self.startDate = UserDefaults.standard.object(forKey: "fasting_start") as? Date
        self.targetEndDate = UserDefaults.standard.object(forKey: "fasting_end") as? Date
        self.isActive = UserDefaults.standard.bool(forKey: "fasting_active")
    }
    
    func startFast(duration: TimeInterval) {
        startDate = .now
        targetEndDate = Date.now.addingTimeInterval(duration)
        isActive = true
    }
    
    func stopFast() {
        isActive = false
    }
}
```

### Handling App Lifecycle with `scenePhase`

When the app returns to the foreground, the timer simply recalculates from the persisted timestamps. No background execution is needed for the countdown itself.

```swift
// FastingApp.swift
@main
struct FastingApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var timer = FastingTimer()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(timer)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                // Timer auto-recalculates from Date.now — nothing to do
                // But check if the fast completed while we were away
                if timer.isComplete {
                    timer.stopFast()
                    // Handle completion (log, show congrats, etc.)
                }
            case .background:
                // Schedule notification for timer end (see Section 3)
                NotificationManager.shared.scheduleFastEndNotification(
                    at: timer.targetEndDate
                )
            default:
                break
            }
        }
    }
}
```

### Using BackgroundTasks Framework

The `BackgroundTasks` framework (`BGAppRefreshTaskRequest` / `BGProcessingTaskRequest`) is **not suitable for driving a countdown timer**. It's designed for periodic content refresh (data sync, ML model updates, etc.) and the system controls when your task actually runs.

However, it **is** useful for a fasting app in one specific way: updating widgets or Live Activities with fresh data when the system gives you background time.

```swift
import BackgroundTasks

func scheduleAppRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "com.app.fasting.refresh")
    request.earliestBeginDate = .now.addingTimeInterval(15 * 60) // 15 min minimum
    try? BGTaskScheduler.shared.submit(request)
}

// In your App struct:
.backgroundTask(.appRefresh("com.app.fasting.refresh")) {
    // Update widget timeline, refresh Live Activity if needed
    await updateWidgetTimeline()
    // Re-schedule for next refresh
    scheduleAppRefresh()
}
```

**Key constraint**: The `earliestBeginDate` is a *hint* — iOS decides the actual execution time based on battery, user patterns, and system load. You may get background time minutes or hours after requesting it. The background task time limit is approximately 30 seconds.

**Sources**: [Apple Developer Forums — Quinn's Background Execution Notes](https://developer.apple.com/forums/thread/685525), [Swift with Majid — Background tasks in SwiftUI](https://swiftwithmajid.com/2022/07/06/background-tasks-in-swiftui/), [WWDC22 — Efficiency awaits: Background tasks in SwiftUI](https://developer.apple.com/videos/play/wwdc2022/10142/)

---

## 2. iOS Background Execution Limits

### What iOS Actually Does

iOS suspends your app shortly after the user moves it to the background. Suspension prevents the process from running any code — timers stop firing, network requests pause, and your run loop is frozen.

Per Apple's Quinn (DTS engineer): *"iOS puts strict limits on background execution. Its default behaviour is to suspend your app shortly after the user has moved it to the background."*

### Time Limits

| Mechanism | Runtime | Notes |
|---|---|---|
| `beginBackgroundTask` | ~30 seconds | For finishing in-flight work. Not extendable. |
| `BGAppRefreshTask` | ~30 seconds | System-scheduled. Timing not guaranteed. |
| `BGProcessingTask` | Several minutes | Requires charger + Wi-Fi. Heavy tasks only. |
| Audio background mode | Indefinite | Must be actively playing audio. Abuse = rejection. |
| Location background mode | Indefinite | Must be tracking location. Abuse = rejection. |

### What This Means for a Fasting Timer

**You cannot run a timer in the background.** Period. This is by design. The correct approach:

1. **Persist `startDate` + `endDate`** to UserDefaults/SwiftData on fast start
2. **Schedule a local notification** for the end time (see Section 3)
3. **Start a Live Activity** so the user sees the countdown without opening the app (see Section 4)
4. **Recompute elapsed/remaining time** from `Date.now` when app returns to foreground

### Factors That Affect Background Task Scheduling

The system considers multiple factors when deciding whether to honor a `BGAppRefreshTask` request:

- **App usage patterns**: iOS learns when the user typically opens your app and tries to schedule refreshes accordingly
- **Battery level**: Background execution pauses below ~20% or in Low Power Mode
- **Background App Refresh setting**: User can toggle this per-app in Settings
- **App Switcher presence**: Only apps visible in the App Switcher get background opportunities
- **System energy/data budgets**: Distributed across all apps throughout the day
- **Rate limiting**: System spaces out launches to prevent abuse
- **Force quit**: If the user swipes the app away from the App Switcher, background tasks will not run until the user manually opens the app again

### AlarmKit (iOS 17.4+)

Apple explicitly recommends the new `AlarmKit` framework for timer apps. For older systems, use local notifications.

**Sources**: [Apple Developer Forums — Background Execution Limits](https://developer.apple.com/forums/thread/685525), [Andy Ibanez — Common Reasons for Background Tasks to Fail](https://www.andyibanez.com/posts/common-reasons-background-tasks-fail-ios/), [Apple Energy Efficiency Guide](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/WorkLessInTheBackground.html)

---

## 3. Local Notification Scheduling for Timer Completion

When the user starts a fast, immediately schedule a local notification for the target end time. This is the **only reliable way** to alert the user when backgrounded or killed.

### Implementation

```swift
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }
    
    func scheduleFastEndNotification(at endDate: Date?) {
        guard let endDate else { return }
        
        let center = UNUserNotificationCenter.current()
        
        // Remove any existing fasting notification
        center.removePendingNotificationRequests(
            withIdentifiers: ["fasting-complete"]
        )
        
        let content = UNMutableNotificationContent()
        content.title = "Fasting Complete! 🎉"
        content.body = "Congratulations! You've completed your fast."
        content.sound = .default
        content.categoryIdentifier = "FASTING_COMPLETE"
        content.interruptionLevel = .timeSensitive
        
        // Use UNTimeIntervalNotificationTrigger with seconds until end
        let timeInterval = endDate.timeIntervalSince(.now)
        guard timeInterval > 0 else { return }
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "fasting-complete",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    /// Schedule milestone notifications (e.g., "12 hours done!", "You're halfway!")
    func scheduleMilestoneNotifications(
        startDate: Date,
        totalDuration: TimeInterval,
        milestones: [Double] // e.g., [0.25, 0.5, 0.75]
    ) {
        let center = UNUserNotificationCenter.current()
        
        // Remove old milestones
        let ids = milestones.map { "fasting-milestone-\(Int($0 * 100))" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        
        for milestone in milestones {
            let elapsed = totalDuration * milestone
            let fireDate = startDate.addingTimeInterval(elapsed)
            let remaining = fireDate.timeIntervalSince(.now)
            guard remaining > 0 else { continue }
            
            let hours = Int(elapsed) / 3600
            let content = UNMutableNotificationContent()
            content.title = "\(hours) hours done! 💪"
            content.body = "You're \(Int(milestone * 100))% through your fast. Keep going!"
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: remaining,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "fasting-milestone-\(Int(milestone * 100))",
                content: content,
                trigger: trigger
            )
            
            center.add(request)
        }
    }
    
    func cancelAllFastingNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }
}
```

### Handling Notification Actions

Register actionable notifications so users can interact directly from the notification:

```swift
// In AppDelegate or App init
func registerNotificationCategories() {
    let extendAction = UNNotificationAction(
        identifier: "EXTEND_FAST",
        title: "Extend by 2 hours",
        options: .foreground
    )
    let endAction = UNNotificationAction(
        identifier: "END_FAST",
        title: "End Fast",
        options: []
    )
    
    let category = UNNotificationCategory(
        identifier: "FASTING_COMPLETE",
        actions: [extendAction, endAction],
        intentIdentifiers: []
    )
    
    UNUserNotificationCenter.current()
        .setNotificationCategories([category])
}
```

### Key Limits

- **64 scheduled notifications** maximum per app at any time
- Notifications fire even if the app is killed (they're managed by the system)
- `UNTimeIntervalNotificationTrigger` minimum interval for repeating is 60 seconds
- `UNCalendarNotificationTrigger` is an alternative for date-based scheduling

**Sources**: [Hacking with Swift — Scheduling local notifications](https://www.hackingwithswift.com/books/ios-swiftui/scheduling-local-notifications), [Kodeco — Local Notifications Getting Started](https://www.kodeco.com/21458686-local-notifications-getting-started), [Apple Documentation — Scheduling and Handling Local Notifications](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/SchedulingandHandlingLocalNotifications.html)

---

## 4. Live Activity / Dynamic Island (iOS 16.1+)

Live Activities are the **ideal solution** for displaying a fasting countdown on the Lock Screen and Dynamic Island without waking the app. The system renders the widget-like UI and handles the countdown display.

### Architecture

```
┌──────────────────────────────────────────────┐
│ Main App                                      │
│  ├── FastingTimer (model)                     │
│  ├── Starts/updates/ends Activity<>           │
│  └── Schedules local notifications            │
├──────────────────────────────────────────────┤
│ Widget Extension                              │
│  ├── FastingActivityAttributes                │
│  ├── Lock Screen UI                           │
│  ├── Dynamic Island (compact/expanded/minimal)│
│  └── Text(timerInterval:) for live countdown  │
└──────────────────────────────────────────────┘
```

### Data Model

```swift
// FastingActivityAttributes.swift (shared between app and widget extension)
import ActivityKit
import Foundation

struct FastingActivityAttributes: ActivityAttributes {
    // Static data — set once at start, doesn't change
    var fastingPlanName: String   // e.g., "16:8 Intermittent Fast"
    var startDate: Date
    var targetEndDate: Date
    
    // Dynamic data — can be updated via ActivityKit
    struct ContentState: Codable, Hashable {
        var currentPhase: FastingPhase
        var motivationalMessage: String
    }
}

enum FastingPhase: String, Codable, Hashable {
    case burning       // 0-12h
    case ketosis       // 12-18h
    case autophagy     // 18-24h
    case deepAutophagy // 24h+
}
```

### Widget Extension UI

```swift
// FastingLiveActivity.swift (in widget extension target)
import ActivityKit
import WidgetKit
import SwiftUI

struct FastingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FastingActivityAttributes.self) { context in
            // LOCK SCREEN / BANNER
            lockScreenView(context: context)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.white)
                
        } dynamicIsland: { context in
            DynamicIsland {
                // EXPANDED
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.fastingPlanName, systemImage: "flame")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.currentPhase.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // This Text view counts down automatically — no app wake needed
                    Text(timerInterval:
                        context.attributes.startDate...context.attributes.targetEndDate,
                        countsDown: true
                    )
                    .font(.system(.title, design: .monospaced))
                    .multilineTextAlignment(.center)
                    
                    Text(context.state.motivationalMessage)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                // Compact countdown in Dynamic Island bar
                Text(timerInterval:
                    context.attributes.startDate...context.attributes.targetEndDate,
                    countsDown: true
                )
                .monospacedDigit()
                .font(.caption)
                .frame(width: 56)
            } minimal: {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
            }
        }
    }
    
    @ViewBuilder
    func lockScreenView(context: ActivityViewContext<FastingActivityAttributes>) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text(context.attributes.fastingPlanName)
                    .font(.headline)
                Spacer()
                Text(context.state.currentPhase.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            // Auto-updating countdown — the key feature
            Text(timerInterval:
                context.attributes.startDate...context.attributes.targetEndDate,
                countsDown: true
            )
            .font(.system(.largeTitle, design: .monospaced))
            .fontWeight(.bold)
            
            ProgressView(
                timerInterval: context.attributes.startDate...context.attributes.targetEndDate,
                countsDown: true
            )
            .tint(.orange)
        }
        .padding()
    }
}
```

### Key Insight: `Text(timerInterval:countsDown:)`

SwiftUI's `Text(timerInterval:)` is special — **it updates the displayed time every second without any app code running**. The system renders the countdown natively. This is how Apple's own Timer app works in the Dynamic Island.

This is the only way to show a live-updating countdown in a Live Activity. You cannot use a `Timer.publish` or manually update the content state every second.

### Managing the Live Activity from the App

```swift
import ActivityKit

class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<FastingActivityAttributes>?
    
    func startFastingActivity(
        planName: String,
        startDate: Date,
        endDate: Date,
        phase: FastingPhase
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = FastingActivityAttributes(
            fastingPlanName: planName,
            startDate: startDate,
            targetEndDate: endDate
        )
        
        let state = FastingActivityAttributes.ContentState(
            currentPhase: phase,
            motivationalMessage: "Stay strong! 💪"
        )
        
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: endDate),
                pushType: nil // Use .token if you have a push server
            )
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    func updatePhase(_ phase: FastingPhase, message: String) async {
        let state = FastingActivityAttributes.ContentState(
            currentPhase: phase,
            motivationalMessage: message
        )
        await currentActivity?.update(.init(state: state, staleDate: nil))
    }
    
    func endActivity() async {
        let finalState = FastingActivityAttributes.ContentState(
            currentPhase: .deepAutophagy,
            motivationalMessage: "Fast complete! 🎉"
        )
        await currentActivity?.end(
            .init(state: finalState, staleDate: nil),
            dismissalPolicy: .after(.now.addingTimeInterval(4 * 3600)) // Show for 4h
        )
    }
}
```

### Constraints

- **Data size limit**: Combined static + dynamic data cannot exceed 4 KB
- **Max active**: System limits to ~5 concurrent Live Activities across all apps
- Each Live Activity runs in a sandbox — no network access, no location
- Updates from the app require the app to be running (foreground or brief background)
- For updates while killed, use ActivityKit push notifications (requires server)
- Live Activities auto-end after 8 hours (can be extended to 12 with `staleDate`)
- `Text(timerInterval:)` does NOT fire callbacks when it reaches zero — you need a notification or push to end the activity

**Sources**: [Apple Developer Forums — Countdown Timer in Dynamic Island](https://developer.apple.com/forums/thread/759250), [Canopas — Live Activity and Dynamic Island Guide](https://canopas.com/integrating-live-activity-and-dynamic-island-in-i-os-a-complete-guide), [Create with Swift — Implementing Live Activities](https://www.createwithswift.com/implementing-live-activities-in-a-swiftui-app/)

---

## 5. Timer Precision: NSTimer vs DispatchSourceTimer vs Combine Timer.publish

For the **in-app UI tick** (updating the displayed countdown every second while the app is in the foreground), there are three options:

### Comparison

| Approach | Precision | Thread | SwiftUI Integration | Best For |
|---|---|---|---|---|
| `Timer.publish` (Combine) | ~100ms tolerance | Main (RunLoop) | Native `.onReceive` | UI countdown display |
| `Timer.scheduledTimer` | ~100ms tolerance | Main (RunLoop) | Manual bridge | UIKit-based apps |
| `DispatchSourceTimer` | Microsecond capable | Any queue | Manual bridge | Precise background timing |

### Recommended: `Timer.publish` for SwiftUI Countdown Display

```swift
struct CountdownView: View {
    @Environment(FastingTimer.self) var fastingTimer
    
    // Fires every second on the main RunLoop
    let displayTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var now = Date.now
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let remaining = fastingTimer.targetEndDate?
                .timeIntervalSince(timeline.date) ?? 0
            
            VStack {
                Text(formatDuration(max(0, remaining)))
                    .font(.system(.largeTitle, design: .monospaced))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
        }
    }
    
    func formatDuration(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
```

### Alternative: `TimelineView` (iOS 15+, Recommended)

`TimelineView` is actually the **best approach for SwiftUI** — it's purpose-built for views that need periodic updates:

```swift
// Best practice: Use TimelineView for countdown display
struct FastingCountdownView: View {
    let startDate: Date
    let endDate: Date
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            let elapsed = context.date.timeIntervalSince(startDate)
            let remaining = endDate.timeIntervalSince(context.date)
            
            VStack(spacing: 8) {
                Text(formatTime(max(0, remaining)))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .contentTransition(.numericText())
                    .animation(.default, value: Int(remaining))
                
                ProgressView(value: elapsed, total: endDate.timeIntervalSince(startDate))
                    .tint(.orange)
            }
        }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
```

### When to Use Each

- **`TimelineView`**: SwiftUI countdown display. Preferred. Automatically pauses when view is not visible.
- **`Timer.publish` + `.onReceive`**: SwiftUI, when you need to trigger side effects on each tick (not just UI updates).
- **`DispatchSourceTimer`**: Background-thread work that needs sub-second precision (audio, haptics). Overkill for a fasting timer.

### Critical Rule

**Never rely on timer tick count for elapsed time.** Always compute from `Date.now - startDate`. Timer callbacks can be delayed, skipped, or coalesced by the system.

```swift
// ❌ WRONG — will drift
@State var secondsRemaining = 3600
// .onReceive(timer) { _ in secondsRemaining -= 1 }

// ✅ RIGHT — always accurate
var secondsRemaining: TimeInterval {
    max(0, targetEndDate.timeIntervalSince(.now))
}
```

---

## 6. Battery Optimization for Always-Running Timers

### Guidelines

1. **Do not use background modes for a timer.** Apple will reject your app (App Store Review Guidelines 2.5.4) if you use audio, location, or VoIP background modes to keep a timer alive.

2. **Stop the display timer when the app is backgrounded.** Use `scenePhase` or `TimelineView` (which auto-pauses).

```swift
struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
    @State private var isTimerActive = true
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text("Timer")
            .onReceive(timer) { _ in
                guard isTimerActive else { return }
                // Update UI
            }
            .onChange(of: scenePhase) { _, phase in
                isTimerActive = (phase == .active)
            }
    }
}
```

3. **Use `.common` RunLoop mode** for `Timer.publish` so the timer fires even during scrolling. But note this means slightly higher CPU during scroll.

4. **Use 1-second intervals** for the display timer. Sub-second updates are unnecessary for a fasting timer and waste battery.

5. **Prefer `TimelineView`** over `Timer.publish` — it automatically manages lifecycle and stops updating when the view is offscreen or the app is backgrounded.

6. **Avoid wake-ups in the background.** The combination of:
   - Persisted timestamps (UserDefaults / SwiftData)
   - Local notifications (for completion alert)
   - Live Activity (for Lock Screen / Dynamic Island display)
   
   means **zero background CPU usage** for your timer.

### Energy Impact Summary

| Approach | Battery Impact | Notes |
|---|---|---|
| Timestamp + foreground Timer.publish | Negligible | Only ticks when app is visible |
| TimelineView | Negligible | Auto-pauses, most efficient |
| Background audio mode abuse | Very High | Will get app rejected |
| BGAppRefreshTask (for widget update) | Very Low | System-managed, infrequent |
| Live Activity | Very Low | System-rendered, no app CPU |

---

## 7. How Top Fasting Apps Handle Background Timer State

### Zero (by Big Sky Health) — Industry Standard

Zero, the most popular fasting app, uses the timestamp-based architecture described throughout this document:

1. **Start a fast** → Persist `startDate` and `targetEndDate` to Core Data / cloud sync
2. **Schedule a local notification** for the target end time
3. **Show a Live Activity** on iOS 16.1+ with `Text(timerInterval:)` for the countdown
4. **When app reopens** → Recompute remaining time from `Date.now - startDate`
5. **Sync to server** → The fast record lives server-side, so switching devices works
6. **Widget** → Uses `TimelineProvider` with entries at key milestones (phase changes)

Zero does NOT run anything in the background. The "timer" is pure math.

### Common Architecture Pattern (Zero, LIFE Fasting, Fastic, etc.)

```
┌─────────────────────────────────────────────────┐
│                   App Layer                      │
│                                                  │
│  ┌──────────┐   ┌────────────┐   ┌───────────┐ │
│  │ SwiftData │   │ CloudKit / │   │ HealthKit │ │
│  │ FastLog   │   │ API Sync   │   │ Write     │ │
│  └─────┬─────┘   └─────┬──────┘   └─────┬─────┘ │
│        │               │               │        │
│  ┌─────┴───────────────┴───────────────┴─────┐  │
│  │          FastingSessionManager             │  │
│  │  • startDate: Date                         │  │
│  │  • targetEndDate: Date                     │  │
│  │  • state: .active / .completed / .canceled │  │
│  └──────────┬────────────────────────────────┘  │
│             │                                    │
│  ┌──────────┴──────────┐                        │
│  │ On state change:     │                        │
│  │ • Schedule/cancel    │                        │
│  │   local notification │                        │
│  │ • Start/update/end   │                        │
│  │   Live Activity      │                        │
│  │ • Reload widget      │                        │
│  │   timeline           │                        │
│  └─────────────────────┘                        │
│                                                  │
│            UI Layer (foreground only)             │
│  ┌─────────────────────────────────────────────┐│
│  │ TimelineView(.periodic(from: .now, by: 1))  ││
│  │ → remaining = endDate - context.date        ││
│  │ → display formatted HH:MM:SS               ││
│  └─────────────────────────────────────────────┘│
└─────────────────────────────────────────────────┘
```

### What These Apps Do NOT Do

- ❌ Run a timer in the background
- ❌ Use audio/location background modes to keep alive
- ❌ Use `BGAppRefreshTask` to drive the timer
- ❌ Count timer ticks to calculate elapsed time
- ❌ Use `DispatchSourceTimer` for the countdown display

### What They DO

- ✅ Persist start/end timestamps to durable storage
- ✅ Derive all displayed times from `Date.now` arithmetic
- ✅ Schedule local notifications at fast start
- ✅ Use Live Activities for glanceable Lock Screen countdown
- ✅ Use widgets with `TimelineProvider` for Home Screen display
- ✅ Sync fast records to a server for cross-device continuity
- ✅ Write fasting data to HealthKit
- ✅ Use `TimelineView` or `Timer.publish` for foreground-only display updates

---

## Recommended Implementation Order

1. **Core model**: `FastingTimer` with persisted timestamps (UserDefaults → SwiftData)
2. **Foreground display**: `TimelineView` with `HH:MM:SS` countdown
3. **Local notifications**: Schedule on fast start, cancel on fast stop
4. **Live Activity**: Lock Screen + Dynamic Island countdown with `Text(timerInterval:)`
5. **Widget**: Home Screen with `TimelineProvider`
6. **HealthKit integration**: Write fasting duration on completion
7. **Cloud sync**: Sync fast records for multi-device

---

## Sources

1. [Apple Developer Forums — iOS Background Execution Limits (Quinn)](https://developer.apple.com/forums/thread/685525)
2. [Swift with Majid — Background tasks in SwiftUI](https://swiftwithmajid.com/2022/07/06/background-tasks-in-swiftui/)
3. [WWDC22 — Efficiency awaits: Background tasks in SwiftUI](https://developer.apple.com/videos/play/wwdc2022/10142/)
4. [Hacking with Swift — Counting down with a Timer](https://www.hackingwithswift.com/books/ios-swiftui/counting-down-with-a-timer)
5. [Hacking with Swift — Scheduling local notifications](https://www.hackingwithswift.com/books/ios-swiftui/scheduling-local-notifications)
6. [Kodeco — Local Notifications Getting Started](https://www.kodeco.com/21458686-local-notifications-getting-started)
7. [Create with Swift — Implementing Live Activities](https://www.createwithswift.com/implementing-live-activities-in-a-swiftui-app/)
8. [Canopas — Integrating Live Activity and Dynamic Island](https://canopas.com/integrating-live-activity-and-dynamic-island-in-i-os-a-complete-guide)
9. [Apple Developer Forums — Countdown Timer in Dynamic Island](https://developer.apple.com/forums/thread/759250)
10. [Andy Ibanez — Common Reasons for Background Tasks to Fail](https://www.andyibanez.com/posts/common-reasons-background-tasks-fail-ios/)
11. [Andy Ibanez — Background Execution on iOS](https://www.andyibanez.com/posts/background-execution-in-ios/)
12. [Medium — Overcoming iOS Background Limits: A Time Tracker](https://medium.com/deuk/overcoming-ios-background-limits-a-time-tracker-app-in-swift-ui-5d157a58df68)
13. [FocusPasta — Behind the Timer: Building a Reliable Countdown in Swift](https://focuspasta.substack.com/p/behind-the-timer-building-a-reliable)
14. [Apple Documentation — Extending your app's background execution time](https://developer.apple.com/documentation/uikit/extending-your-app-s-background-execution-time)
15. [Apple Energy Efficiency Guide — Work Less in the Background](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/WorkLessInTheBackground.html)
16. [Filip Němeček — Dynamic Island Quick Start Tutorial](https://nemecek.be/blog/171/dynamic-island-and-live-activities-quick-start-tutorial)
17. [Create with Swift — Creating Local Notifications with async/await](https://www.createwithswift.com/notifications-tutorial-creating-and-scheduling-user-notifications-with-async-await/)
