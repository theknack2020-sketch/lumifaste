# iOS Widgets & Live Activities for a Fasting App

> Research for iOS 17+ (2025–2026) — WidgetKit, ActivityKit, Dynamic Island, Lock Screen, StandBy, Apple Watch

---

## 1. WidgetKit Basics — Widget Families

WidgetKit renders widgets as SwiftUI views in a separate process. Widgets are **not** mini-apps — they are glanceable, timeline-driven displays that project content from your app onto the Home Screen, Lock Screen, StandBy, and Apple Watch.

### Available Widget Families

| Family | Location | Size | Best For (Fasting App) |
|---|---|---|---|
| `systemSmall` | Home Screen, StandBy | 2×2 grid unit | Current fast status, circular timer |
| `systemMedium` | Home Screen | 4×2 grid unit | Timer + progress bar + next meal time |
| `systemLarge` | Home Screen | 4×4 grid unit | Full fast details, history summary |
| `systemExtraLarge` | iPad Home Screen | 8×4 grid unit | Fasting calendar / weekly overview |
| `accessoryCircular` | Lock Screen, Watch | Small circle | Circular progress gauge |
| `accessoryRectangular` | Lock Screen, Watch | Small rectangle | Timer text + progress bar |
| `accessoryInline` | Lock Screen, Watch | Single text line | "Fasting: 14h 23m remaining" |
| `accessoryCorner` | Apple Watch only | Corner of watch face | Gauge with label |

### Widget Extension Setup

```swift
import WidgetKit
import SwiftUI

@main
struct FastingWidgetBundle: WidgetBundle {
    var body: some Widget {
        FastingHomeWidget()         // Home Screen widget
        FastingLockScreenWidget()   // Lock Screen / Watch complications
        FastingLiveActivity()       // Live Activity (Dynamic Island + Lock Screen)
    }
}
```

### Supporting Multiple Families

```swift
struct FastingHomeWidget: Widget {
    let kind: String = "FastingHomeWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: FastingWidgetIntent.self,
            provider: FastingTimelineProvider()
        ) { entry in
            FastingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Fasting Timer")
        .description("Track your current fast progress.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge
        ])
        // iOS 17+: required for Lock Screen / StandBy
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
```

> **Key requirement (iOS 17+):** You must adopt `.containerBackground(_:for:)` on your widget views. Without this, widgets show a "Please adopt containerBackground API" message instead of your content.

---

## 2. Lock Screen Widgets for Fasting Timer Display

Lock Screen widgets use the `accessory` families. They render in a constrained, tinted style — no full-color by default.

### Lock Screen Widget Implementation

```swift
struct FastingLockScreenWidget: Widget {
    let kind: String = "FastingLockScreen"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: FastingWidgetIntent.self,
            provider: FastingTimelineProvider()
        ) { entry in
            FastingAccessoryView(entry: entry)
        }
        .configurationDisplayName("Fasting Timer")
        .description("See your fast progress on the Lock Screen.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}
```

### Accessory Views

```swift
struct FastingAccessoryView: View {
    let entry: FastingEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) var renderingMode

    var body: some View {
        switch family {
        case .accessoryCircular:
            FastingCircularView(entry: entry)
        case .accessoryRectangular:
            FastingRectangularView(entry: entry)
        case .accessoryInline:
            FastingInlineView(entry: entry)
        default:
            EmptyView()
        }
    }
}

// Circular gauge — perfect for fasting progress
struct FastingCircularView: View {
    let entry: FastingEntry

    var body: some View {
        Gauge(value: entry.progress, in: 0...1) {
            Image(systemName: "fork.knife")
        } currentValueLabel: {
            Text(entry.fastEndDate, style: .timer)
                .font(.system(.caption2, design: .rounded))
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }
}

// Rectangular — shows more detail
struct FastingRectangularView: View {
    let entry: FastingEntry

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "timer")
                Text(entry.isFasting ? "Fasting" : "Eating Window")
                    .font(.headline)
            }
            Text(entry.fastEndDate, style: .timer)
                .font(.system(.title3, design: .rounded))
                .monospacedDigit()
            ProgressView(value: entry.progress)
        }
    }
}

// Inline — single line of text
struct FastingInlineView: View {
    let entry: FastingEntry

    var body: some View {
        if entry.isFasting {
            Text("Fasting: \(entry.fastEndDate, style: .timer) left")
        } else {
            Text("Eating window • \(entry.eatingEndDate, style: .timer)")
        }
    }
}
```

### Rendering Modes

Lock Screen widgets render in different modes depending on the watch face / Lock Screen style. Use `@Environment(\.widgetRenderingMode)` to adapt:

- **`fullColor`** — Full-color rendering (Home Screen, some watch faces)
- **`vibrant`** — Desaturated, translucent (iOS Lock Screen)
- **`accented`** — Two-tone with user's accent color (watchOS)

---

## 3. Home Screen Widget — Current Fast Status & Progress

### Timeline Entry Model

```swift
import WidgetKit

struct FastingEntry: TimelineEntry {
    let date: Date               // When this entry becomes current
    let isFasting: Bool
    let fastStartDate: Date
    let fastEndDate: Date        // Target end of current phase
    let eatingEndDate: Date
    let progress: Double         // 0.0 to 1.0
    let fastingProtocol: String  // e.g. "16:8", "18:6", "20:4"
    let currentStreakDays: Int
}
```

### Home Screen Widget Views

```swift
struct FastingWidgetEntryView: View {
    let entry: FastingEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallFastingView(entry: entry)
        case .systemMedium:
            MediumFastingView(entry: entry)
        case .systemLarge:
            LargeFastingView(entry: entry)
        default:
            SmallFastingView(entry: entry)
        }
    }
}

struct SmallFastingView: View {
    let entry: FastingEntry

    var body: some View {
        VStack(spacing: 8) {
            // Circular progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(
                        entry.isFasting ? Color.orange : Color.green,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Image(systemName: entry.isFasting ? "flame.fill" : "fork.knife")
                        .font(.title3)
                    // Live countdown — updates in real-time without timeline refresh
                    Text(entry.fastEndDate, style: .timer)
                        .font(.system(.caption, design: .rounded))
                        .monospacedDigit()
                }
            }
            .frame(width: 90, height: 90)

            Text(entry.isFasting ? "Fasting" : "Eating")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumFastingView: View {
    let entry: FastingEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: circular progress
            SmallFastingView(entry: entry)

            // Right: details
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.fastingProtocol)
                    .font(.headline)
                    .foregroundColor(.primary)

                Label {
                    Text(entry.isFasting ? "Fast ends" : "Eating ends")
                        .font(.subheadline)
                } icon: {
                    Image(systemName: "clock")
                }

                Text(entry.fastEndDate, style: .relative)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if entry.currentStreakDays > 0 {
                    Label("\(entry.currentStreakDays) day streak", systemImage: "flame")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
```

---

## 4. Live Activity — Dynamic Island & Lock Screen

Live Activities are the **ideal** surface for an active fasting timer. They provide persistent, real-time visibility on the Lock Screen and Dynamic Island without burning timeline refresh budget.

### Key Differences from Widgets

| Aspect | Widget | Live Activity |
|---|---|---|
| Update mechanism | Timeline entries (budgeted) | ActivityKit API or Push Notifications |
| Real-time display | `Text(date, style: .timer)` only | Full control via updates |
| Lifespan | Permanent until removed | Temporary (max 12 hours active, persists 4 hours after ending on Lock Screen) |
| Interactivity | Buttons/Toggles (iOS 17+) | Buttons/Toggles + deep links |
| Surfaces | Home Screen, Lock Screen, StandBy | Lock Screen, Dynamic Island, StandBy, Apple Watch (mirrored) |

### ActivityAttributes for Fasting

```swift
import ActivityKit

struct FastingActivityAttributes: ActivityAttributes {
    // Static data — set when activity starts, never changes
    let fastingProtocol: String    // "16:8"
    let fastStartDate: Date
    let targetEndDate: Date

    // Dynamic data — updates over the life of the activity
    struct ContentState: Codable, Hashable {
        let currentPhase: FastingPhase
        let elapsedSeconds: Int
        let progress: Double           // 0.0 to 1.0
        let phaseEndDate: Date         // For countdown timer display
    }
}

enum FastingPhase: String, Codable {
    case fasting = "Fasting"
    case eating = "Eating Window"
    case completed = "Fast Complete"
}
```

### Live Activity Widget (UI)

```swift
struct FastingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FastingActivityAttributes.self) { context in
            // LOCK SCREEN / BANNER presentation
            FastingLockScreenLiveView(context: context)

        } dynamicIsland: { context in
            DynamicIsland {
                // EXPANDED view — shown when user long-presses Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Label("Fasting", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text(context.attributes.fastingProtocol)
                            .font(.caption2)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text("Remaining")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(context.state.phaseEndDate, style: .timer)
                            .font(.system(.title3, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.orange)
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    ProgressView(value: context.state.progress)
                        .tint(.orange)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        // Interactive button (iOS 17+)
                        Button(intent: EndFastIntent()) {
                            Label("End Fast", systemImage: "stop.circle")
                                .font(.caption)
                        }
                        .tint(.red)

                        Spacer()

                        Text("\(Int(context.state.progress * 100))% complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            // COMPACT view — default Dynamic Island appearance
            compactLeading: {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
            }
            compactTrailing: {
                Text(context.state.phaseEndDate, style: .timer)
                    .monospacedDigit()
                    .font(.caption)
                    .frame(width: 56)
            }
            // MINIMAL view — when multiple Live Activities compete
            minimal: {
                Gauge(value: context.state.progress) {
                    Image(systemName: "flame.fill")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(.orange)
            }
        }
    }
}

// Lock Screen banner for the Live Activity
struct FastingLockScreenLiveView: View {
    let context: ActivityViewContext<FastingActivityAttributes>

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text(context.state.currentPhase.rawValue)
                    .font(.headline)
                Spacer()
                Text(context.attributes.fastingProtocol)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: context.state.progress)
                .tint(.orange)

            HStack {
                VStack(alignment: .leading) {
                    Text("Started")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(context.attributes.fastStartDate, style: .time)
                        .font(.caption)
                }

                Spacer()

                VStack {
                    Text("Remaining")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(context.state.phaseEndDate, style: .timer)
                        .font(.system(.title2, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.orange)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Goal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(context.attributes.targetEndDate, style: .time)
                        .font(.caption)
                }
            }
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.8))
        .activitySystemActionForegroundColor(.white)
    }
}
```

### Dynamic Island Presentations

The Dynamic Island has **four** distinct presentations:

1. **Compact** (Leading + Trailing): Default view when your activity owns the island. Two small areas flanking the TrueDepth camera.
2. **Minimal**: Shown when another Live Activity takes priority — your app gets a tiny circle on one side.
3. **Expanded**: Shown on long-press. Has four regions: `.leading`, `.trailing`, `.center`, `.bottom`.
4. **Lock Screen Banner**: The full-width banner on the Lock Screen (same as the `content` closure).

---

## 5. ActivityKit Implementation — Starting, Updating, Ending

### Starting a Live Activity

```swift
import ActivityKit

class FastingLiveActivityManager {
    static let shared = FastingLiveActivityManager()
    private var currentActivity: Activity<FastingActivityAttributes>?

    func startFastingActivity(
        protocol fastingProtocol: String,
        startDate: Date,
        targetEndDate: Date
    ) throws {
        // Check if Live Activities are available
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }

        let attributes = FastingActivityAttributes(
            fastingProtocol: fastingProtocol,
            fastStartDate: startDate,
            targetEndDate: targetEndDate
        )

        let initialState = FastingActivityAttributes.ContentState(
            currentPhase: .fasting,
            elapsedSeconds: 0,
            progress: 0.0,
            phaseEndDate: targetEndDate
        )

        let content = ActivityContent(
            state: initialState,
            staleDate: targetEndDate.addingTimeInterval(300) // stale after 5 min past end
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil // Use .token for push-based updates
            )
            print("Started Live Activity: \(currentActivity?.id ?? "unknown")")
        } catch {
            print("Failed to start Live Activity: \(error)")
            throw error
        }
    }
```

### Updating a Live Activity

```swift
    func updateFastingActivity(
        phase: FastingPhase,
        elapsedSeconds: Int,
        progress: Double,
        phaseEndDate: Date
    ) async {
        let updatedState = FastingActivityAttributes.ContentState(
            currentPhase: phase,
            elapsedSeconds: elapsedSeconds,
            progress: progress,
            phaseEndDate: phaseEndDate
        )

        let content = ActivityContent(
            state: updatedState,
            staleDate: phaseEndDate.addingTimeInterval(300)
        )

        await currentActivity?.update(content)
    }
```

### Ending a Live Activity

```swift
    func endFastingActivity(completed: Bool) async {
        let finalState = FastingActivityAttributes.ContentState(
            currentPhase: completed ? .completed : .eating,
            elapsedSeconds: 0,
            progress: completed ? 1.0 : 0.0,
            phaseEndDate: Date()
        )

        let content = ActivityContent(
            state: finalState,
            staleDate: Date().addingTimeInterval(3600) // Keep on Lock Screen for 1 hour
        )

        await currentActivity?.end(
            content,
            dismissalPolicy: .after(Date().addingTimeInterval(3600)) // Auto-dismiss after 1 hour
            // Other options: .default (4 hours), .immediate
        )
    }
}
```

### Info.plist Requirements

```xml
<key>NSSupportsLiveActivities</key>
<true/>
<!-- Optional: for frequent updates (sports scores, etc.) -->
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>
```

### Important Constraints

- **Data size limit:** Combined static + dynamic data cannot exceed **4 KB** per update.
- **Max active:** System allows multiple concurrent Live Activities per app, but practically ~5 total across all apps.
- **Duration:** Active for up to **12 hours** (8 hours in iOS 16), then automatically ended by the system.
- **After ending:** Remains on Lock Screen for up to **4 hours** (or until user dismisses, or `dismissalPolicy` fires).
- **No network access:** Live Activity views run in a sandbox. All data must come through ActivityKit updates or push notifications.
- **Push updates:** Use ActivityKit push notifications for server-driven updates when the app isn't running. Requires APNs setup.

---

## 6. Widget Timeline & Refresh Strategy for a Countdown Timer

This is the trickiest part of widget development for a fasting app. Widgets don't run continuously — they use pre-computed timelines.

### The Core Problem

Widgets are budgeted to approximately **40–70 refreshes per day** in production (roughly every 15–60 minutes). You cannot refresh every second.

### Strategy: Use `Text(date, style: .timer)` for Real-Time Countdowns

SwiftUI provides special date-formatting text styles that update **live** without consuming timeline budget:

```swift
// Counts down to the target date — updates every second automatically
Text(entry.fastEndDate, style: .timer)
// Output: "4:23:15" → "4:23:14" → "4:23:13" ...

// Shows relative time
Text(entry.fastEndDate, style: .relative)
// Output: "4 hours, 23 minutes"

// Shows absolute time
Text(entry.fastEndDate, style: .time)
// Output: "3:30 PM"
```

You can also use `ProgressView(timerInterval:countsDown:)` for a live progress bar:

```swift
ProgressView(
    timerInterval: entry.fastStartDate...entry.fastEndDate,
    countsDown: true
) {
    Text("Fasting")
}
```

### Timeline Provider Implementation

```swift
struct FastingTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = FastingEntry
    typealias Intent = FastingWidgetIntent

    func placeholder(in context: Context) -> FastingEntry {
        FastingEntry(
            date: Date(),
            isFasting: true,
            fastStartDate: Date(),
            fastEndDate: Date().addingTimeInterval(16 * 3600),
            eatingEndDate: Date().addingTimeInterval(24 * 3600),
            progress: 0.65,
            fastingProtocol: "16:8",
            currentStreakDays: 7
        )
    }

    func snapshot(for configuration: FastingWidgetIntent, in context: Context) async -> FastingEntry {
        await getCurrentFastingEntry()
    }

    func timeline(for configuration: FastingWidgetIntent, in context: Context) async -> Timeline<FastingEntry> {
        var entries: [FastingEntry] = []
        let currentData = await loadFastingData()

        if let fast = currentData.activeFast {
            let now = Date()

            // Entry 1: Current state
            entries.append(makeEntry(date: now, fast: fast))

            // Entry 2: At phase transition (fast end / eating window start)
            entries.append(makeEntry(date: fast.endDate, fast: fast, transitioned: true))

            // Entries 3-N: Periodic updates every 30 min for progress changes
            // (updates the non-timer parts like progress ring, streak count)
            var nextUpdate = now.addingTimeInterval(30 * 60)
            while nextUpdate < fast.endDate {
                entries.append(makeEntry(date: nextUpdate, fast: fast))
                nextUpdate = nextUpdate.addingTimeInterval(30 * 60)
            }

            // Reload timeline after the fast ends
            return Timeline(entries: entries, policy: .after(fast.endDate))
        } else {
            // Not fasting — show "not fasting" state
            let entry = makeNotFastingEntry(date: Date())
            entries.append(entry)

            // Check again in an hour
            return Timeline(entries: entries, policy: .after(Date().addingTimeInterval(3600)))
        }
    }
}
```

### Refresh Triggers

| Method | When to Use |
|---|---|
| Timeline with `.atEnd` / `.after(date)` | Scheduled future updates |
| `WidgetCenter.shared.reloadTimelines(ofKind:)` | User starts/stops a fast in the app |
| `WidgetCenter.shared.reloadAllTimelines()` | Significant data change |
| Push notifications (iOS 26+) | Server-driven updates via APNs |

### Best Practice for Fasting Timers

1. **Use `Text(date, style: .timer)`** for the countdown — this updates live every second with zero timeline cost.
2. **Use `ProgressView(timerInterval:...)`** for live-animating progress bars.
3. **Schedule timeline entries** at key moments: phase transitions, 30-min intervals for non-time UI updates.
4. **Call `reloadTimelines`** from the main app when the user starts, pauses, or ends a fast.
5. **Use App Groups** (`UserDefaults(suiteName:)`) to share data between app and widget extension.

### Caveats with `Text(date, style: .timer)`

- Cannot be styled beyond standard font modifiers — shows `H:MM:SS` format.
- Counts into **negative** values after the target date passes (shows `-0:01`, `-0:02`...).
- Does not support "X days, HH:MM:SS" format — hours accumulate past 24 (e.g., `36:45:12`).
- **Workaround:** Use timeline entries to break countdown into <24-hour segments, displaying the "days" part as static text alongside the timer.

---

## 7. Interactive Widgets (iOS 17+) — Start/Stop Fast from Widget

Starting with iOS 17, widgets support **buttons and toggles** powered by App Intents. Users can perform actions directly from the widget without opening the app.

### What's Possible for a Fasting App

| Action | Feasible? | Implementation |
|---|---|---|
| Start a fast | ✅ Yes | Button with `AppIntent` |
| End a fast early | ✅ Yes | Button with `AppIntent` |
| Pause a fast | ✅ Yes | Toggle with `AppIntent` |
| Choose fasting protocol | ❌ No | Requires full app UI (widget configuration can pre-select) |
| Log water/supplement | ✅ Yes | Button with `AppIntent` |

### App Intent for Starting a Fast

```swift
import AppIntents

struct StartFastIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Fast"
    static var description = IntentDescription("Start a new fasting period")

    // Optional: let user choose protocol from widget
    @Parameter(title: "Fasting Protocol")
    var fastingProtocol: FastingProtocolEntity?

    func perform() async throws -> some IntentResult {
        // Access your shared data store (App Group)
        let store = FastingDataStore.shared

        let protocolType = fastingProtocol?.id ?? store.defaultProtocol
        try await store.startFast(protocol: protocolType)

        // Start the Live Activity
        try FastingLiveActivityManager.shared.startFastingActivity(
            protocol: protocolType,
            startDate: Date(),
            targetEndDate: store.currentFastEndDate!
        )

        // Refresh widgets
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}

struct EndFastIntent: AppIntent {
    static var title: LocalizedStringResource = "End Fast"
    static var description = IntentDescription("End the current fast")

    func perform() async throws -> some IntentResult {
        let store = FastingDataStore.shared
        try await store.endFast()

        // End Live Activity
        await FastingLiveActivityManager.shared.endFastingActivity(completed: false)

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
```

### Using Intents in Widget Views

```swift
struct SmallFastingView: View {
    let entry: FastingEntry

    var body: some View {
        VStack {
            if entry.isFasting {
                // Show timer and progress
                Text(entry.fastEndDate, style: .timer)
                    .font(.title2)
                ProgressView(value: entry.progress)

                // Interactive button — ends fast directly from widget
                Button(intent: EndFastIntent()) {
                    Label("End Fast", systemImage: "stop.circle.fill")
                        .font(.caption)
                }
                .tint(.red)
            } else {
                Text("Not Fasting")
                    .font(.headline)

                // Interactive button — starts fast directly from widget
                Button(intent: StartFastIntent()) {
                    Label("Start Fast", systemImage: "play.circle.fill")
                        .font(.caption)
                }
                .tint(.green)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
```

### Constraints on Interactive Widgets

- Only `Button` and `Toggle` are supported — no text fields, sliders, pickers, etc.
- Buttons execute `AppIntent` — the intent runs in the app's process (app doesn't need to be foregrounded).
- Buttons work on **Home Screen, Lock Screen, StandBy**, and in **Live Activities**.
- On the always-on display, interactive widgets are visible but "you won't be able to directly interact with them without waking the screen up first."
- iOS 17 interactive widgets also work within Live Activity views (Dynamic Island expanded view and Lock Screen banner).

---

## 8. StandBy Mode Support

StandBy mode (iOS 17+) turns a charging iPhone in landscape orientation into a smart display. Widgets appear prominently in this mode.

### Key Facts

- **Only `systemSmall` widgets** appear in StandBy mode. If your app has `systemSmall` Home Screen widgets, they automatically appear in the StandBy widget gallery.
- Widgets in StandBy are displayed at a **much larger size** — rendered larger and zoomed up for visibility at distance.
- **Interactive widgets work** in StandBy — users can tap buttons and toggles.
- **Live Activities** appear in StandBy mode as well.
- StandBy renders widgets in a **dark style** — design for dark backgrounds.

### StandBy Design Considerations

```swift
struct SmallFastingView: View {
    let entry: FastingEntry
    @Environment(\.showsWidgetContainerBackground) var showsBackground

    var body: some View {
        VStack {
            // Your content...
        }
        .containerBackground(for: .widget) {
            // StandBy and Lock Screen may remove background
            // Use containerBackground to provide an appropriate one
            if showsBackground {
                Color.black.opacity(0.8)
            } else {
                Color.clear
            }
        }
    }
}
```

### Opting Out

If your widget doesn't make sense in StandBy (e.g., it needs HealthKit which is unavailable when locked), you can discourage placement:

```swift
.disfavoredLocations([.standBy], for: [.systemSmall])
```

### StandBy-Specific Tips for Fasting App

1. **Use high-contrast** colors — StandBy is viewed at a distance.
2. **Large, legible timer text** — the countdown should be the dominant element.
3. **Avoid small detail** — at nightstand distance, fine print is unreadable.
4. **Consider night mode** — StandBy uses a red-tinted UI at night. Test your widget in this mode.
5. **Interactive start/stop fast buttons** are valuable — users can control fasting from their nightstand.

---

## 9. Apple Watch Complications (Brief Overview)

Since watchOS 9, Apple Watch complications are built with the **same WidgetKit framework** as iOS widgets. You share code between Lock Screen widgets and Watch complications.

### Watch-Specific Families

| Family | Where | Notes |
|---|---|---|
| `accessoryCircular` | Watch face | Same as iOS Lock Screen circular |
| `accessoryRectangular` | Watch face | Same as iOS Lock Screen rectangular |
| `accessoryInline` | Watch face | May render curved on some faces |
| `accessoryCorner` | **watchOS only** | Corner of watch face, with gauge |

### Shared Code

```swift
struct FastingLockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "FastingAccessory",
            intent: FastingWidgetIntent.self,
            provider: FastingTimelineProvider()
        ) { entry in
            FastingAccessoryView(entry: entry)
        }
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            #if os(watchOS)
            .accessoryCorner,
            #endif
        ])
    }
}
```

### watchOS-Specific Considerations

- **WidgetKit Developer Mode** on watchOS (Settings > Developer) can help debug refresh issues — complications may not update promptly without it in development.
- **Data sharing:** Cannot use shared `UserDefaults` across iPhone ↔ Watch. Must use `WatchConnectivity` framework to sync fasting data.
- **Live Activities on Apple Watch:** Starting with watchOS 11 / iOS 18, Live Activities from iPhone can mirror to Apple Watch automatically — no extra code required.
- **Smart Stack:** watchOS widgets appear in the Smart Stack. System surfaces "relevant" widgets based on time, location, and user behavior.
- **Always-on display:** Use `@Environment(\.isLuminanceReduced)` to detect always-on mode and simplify your complication UI.

### Complication-Specific Fasting View

```swift
#if os(watchOS)
struct FastingCornerView: View {
    let entry: FastingEntry

    var body: some View {
        Image(systemName: "flame.fill")
            .font(.title3)
            .widgetLabel {
                Gauge(value: entry.progress) {
                    Text("Fast")
                }
                .gaugeStyle(.accessoryLinearCapacity)
            }
    }
}
#endif
```

---

## 10. Widget Design Best Practices — What Information to Show

### Information Hierarchy by Widget Size

| Size | Primary | Secondary | Tertiary |
|---|---|---|---|
| **accessoryInline** | Phase + time remaining | — | — |
| **accessoryCircular** | Progress gauge | Time remaining | — |
| **accessoryRectangular** | Countdown timer | Progress bar | Phase label |
| **systemSmall** | Circular timer / progress | Phase label | Protocol |
| **systemMedium** | Timer + progress | Protocol + streak | Next meal time |
| **systemLarge** | Full timer + progress | Schedule visualization | History / streak graph |
| **Live Activity (compact)** | Timer countdown | Flame icon | — |
| **Live Activity (expanded)** | Timer + progress | Start/end times | End fast button + protocol |

### Design Principles

1. **Glanceability is king.** Users spend seconds, not minutes, looking at widgets. The fast status and time remaining should be instantly readable.

2. **Use system date styles.** `Text(date, style: .timer)` gives you a live countdown for free. `Text(date, style: .relative)` gives natural language. Use them.

3. **Color-code phases.** Fasting = warm color (orange/red). Eating window = cool color (green/teal). Completed = gold/checkmark.

4. **Show progress, not just time.** A progress ring at 75% communicates more instantly than "4:12:33 remaining."

5. **Deep link intelligently.** Tapping the widget should open the relevant screen:
   ```swift
   .widgetURL(URL(string: "fastingapp://current-fast"))
   ```

6. **Handle the "not fasting" state gracefully.** Show the next scheduled fast, or a clear CTA to start one.

7. **Privacy.** Mark sensitive content (if any) with `.privacySensitive()` for Lock Screen redaction.

8. **Accessibility.** Add `.accessibilityLabel()` to provide VoiceOver descriptions:
   ```swift
   .accessibilityLabel("Fasting timer, 4 hours 23 minutes remaining, 72% complete")
   ```

---

## 11. Performance Considerations

### Widget Extension Memory & CPU

- Widget extensions have **strict memory limits** (~30 MB). Keep data structures lean.
- Timeline generation should be fast. Avoid heavy computation, network calls (if possible), or file I/O in `getTimeline`.
- Use **App Groups** with `UserDefaults` for fast data sharing between app and widget. Avoid Core Data in the widget extension if possible (use a lightweight read-only approach).

### Timeline Budget

- ~40–70 refreshes per day for frequently viewed widgets.
- **Never** rely on per-second timeline entries in production. In debug mode there are no limits, which can mislead.
- Generate timeline entries at meaningful intervals (phase transitions, 30-min progress updates).
- Call `reloadTimelines(ofKind:)` rather than `reloadAllTimelines()` when only specific widgets need updating.

### Live Activity Performance

- Combined attribute + state data must be **< 4 KB** per update.
- Live Activities run in their own sandbox — no network, no location, no HealthKit access from the view.
- Use `staleDate` to indicate when content is no longer fresh — the system shows a visual indicator.
- Limit update frequency: don't update more than once every few minutes from the app. Push-based updates have their own throttling.

### Data Sharing Architecture

```
┌─────────────────┐     App Group      ┌──────────────────────┐
│   Main App      │ ◄──UserDefaults──► │  Widget Extension    │
│                 │    (suiteName)      │  - Timeline Provider │
│  FastingStore   │                     │  - Widget Views      │
│  ActivityKit    │                     │  - Live Activity UI  │
│  HealthKit      │                     │                      │
│  Notifications  │                     │  (No network access  │
└─────────────────┘                     │   in Live Activity)  │
        │                               └──────────────────────┘
        │
        ▼
  WidgetCenter.shared
  .reloadTimelines(ofKind:)
```

### Battery Optimization

1. **Prefer `Text(date, style: .timer)`** over frequent timeline entries for countdowns.
2. **Use `ProgressView(timerInterval:...)`** for live progress bars — zero timeline cost.
3. **Batch timeline entries** — provide all foreseeable entries at once rather than requesting frequent reloads.
4. **Cache previous data** in case HealthKit or other data sources are unavailable when locked:
   ```swift
   func timeline(for config: Intent, in context: Context) async -> Timeline<Entry> {
       do {
           let data = try await loadFreshData()
           cache.store(data) // Save for next time
           return makeTimeline(from: data)
       } catch {
           // HealthKit unavailable (phone locked), use cached data
           if let cached = cache.load() {
               return makeTimeline(from: cached)
           }
           return Timeline(entries: [placeholder()], policy: .after(Date().addingTimeInterval(900)))
       }
   }
   ```
5. **Set appropriate `staleDate`** on Live Activity content so the system knows when to dim/indicate staleness.

### What's New in iOS 26 / WWDC 2025

- **Widget push updates via APNs** — widgets across all WidgetKit platforms can now be updated by push notifications, not just Live Activities.
- **CarPlay widgets** — WidgetKit widgets can appear in CarPlay.
- **visionOS widgets** — iOS/iPad widgets automatically available in visionOS 26.
- **Accented rendering modes** — new desaturated/accented options for Home Screen blending.
- **Live Activities on macOS** — Live Activities from iPhone (iOS 18+) can appear on a paired Mac.
- **Controls in more places** — macOS Control Center, menu bar, watchOS Control Center.
- **Relevant widgets in Smart Stack** — watchOS can automatically surface relevant widgets.

---

## Summary: Recommended Widget Strategy for a Fasting App

| Surface | Widget Type | Priority |
|---|---|---|
| **Live Activity** (Dynamic Island + Lock Screen) | `ActivityConfiguration` | 🔴 **P0** — Best UX for active fast |
| **Home Screen small** | `systemSmall` | 🔴 **P0** — Glanceable timer |
| **Home Screen medium** | `systemMedium` | 🟡 **P1** — Timer + details |
| **Lock Screen circular** | `accessoryCircular` | 🔴 **P0** — Progress gauge |
| **Lock Screen rectangular** | `accessoryRectangular` | 🟡 **P1** — Timer + progress bar |
| **Lock Screen inline** | `accessoryInline` | 🟢 **P2** — Text summary |
| **StandBy** | `systemSmall` (automatic) | 🟡 **P1** — Nightstand timer |
| **Apple Watch** | Accessory families | 🟡 **P1** — Wrist-glanceable |
| **Home Screen large** | `systemLarge` | 🟢 **P2** — Detailed view |

### Implementation Order

1. **Phase 1:** Shared data layer (App Groups), `FastingEntry` model, `TimelineProvider`
2. **Phase 2:** `systemSmall` + `systemMedium` Home Screen widgets with `Text(date, style: .timer)`
3. **Phase 3:** Live Activity with Dynamic Island (the hero feature)
4. **Phase 4:** Lock Screen accessory widgets (share views with Watch)
5. **Phase 5:** Interactive widgets (start/stop fast buttons)
6. **Phase 6:** Apple Watch complications
7. **Phase 7:** Polish — StandBy optimization, always-on display, night mode

---

## Sources

1. [Apple WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
2. [Apple ActivityKit Documentation](https://developer.apple.com/documentation/activitykit)
3. [Adding interactivity to widgets and Live Activities — Apple Docs](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities)
4. [Displaying live data with Live Activities — Apple Docs](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)
5. [What's new in widgets — WWDC25](https://developer.apple.com/videos/play/wwdc2025/278/)
6. [Keeping a widget up to date — Apple Docs](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date)
7. [Displaying dynamic dates in widgets — Apple Docs](https://developer.apple.com/documentation/widgetkit/displaying-dynamic-dates)
8. [Creating accessory widgets and watch complications — Apple Docs](https://developer.apple.com/documentation/widgetkit/creating-accessory-widgets-and-watch-complications)
9. [Migrating ClockKit complications to WidgetKit — Apple Docs](https://developer.apple.com/documentation/widgetkit/converting-a-clockkit-app)
10. [Complications and widgets: Reloaded — WWDC22](https://developer.apple.com/videos/play/wwdc2022/10050/)
11. [Go further with Complications in WidgetKit — WWDC22](https://developer.apple.com/videos/play/wwdc2022/10051/)
12. [Integrating Live Activity and Dynamic Island — Canopas Guide](https://canopas.com/integrating-live-activity-and-dynamic-island-in-i-os-a-complete-guide)
13. [How to Update or Refresh a Widget? — Swift Senpai](https://swiftsenpai.com/development/refreshing-widget/)
14. [Mastering Live Activities in iOS — Gaurav Harkhani](https://medium.com/@gauravharkhani01/mastering-live-activities-in-ios-the-complete-developers-guide-5357eb35d520)
15. [Developer Tips for Adding StandBy Widgets — David Steppenbeck](https://blog.stackademic.com/developer-tips-for-adding-standby-widgets-to-your-iphone-app-271001b0ea4d)
16. [WidgetKit in iOS 26 — Shubham Sanghavi](https://medium.com/@shubhamsanghavi100/widgetkit-in-ios-26-building-dynamic-interactive-widgets-18cc0a973624)
