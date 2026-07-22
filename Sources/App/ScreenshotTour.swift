#if DEBUG
    import Foundation
    import SwiftData

    /// DEBUG-only launch-argument harness for the store-shots pipeline. Routes the app
    /// to a specific screen (`-uiState <key>`) and seeds attractive, deterministic demo
    /// content (`-demoData`) so marketing screenshots photograph a filled, outcome state
    /// instead of empty first-run UIs. Zero release impact — the whole file is compiled
    /// out of Release builds. Canonical pattern: Selfora `ScreenshotTour`.
    enum ScreenshotTour {
        private static var args: [String] { ProcessInfo.processInfo.arguments }

        /// Seed demo data + skip onboarding for a clean capture state.
        static var wantsDemoData: Bool { args.contains("-demoData") }

        /// The requested screen key (maps to a tab / the paywall).
        static var uiState: String? {
            guard let i = args.firstIndex(of: "-uiState"), args.indices.contains(i + 1) else { return nil }
            return args[i + 1]
        }

        /// Initial ContentView tab for the requested state.
        static var initialTab: Int {
            switch uiState {
            case "history": 1
            case "insights": 2
            case "learn": 3
            case "settings": 4
            default: 0 // timer / paywall / unknown
            }
        }

        /// Whether to auto-present the paywall over the timer tab.
        static var showsPaywall: Bool { uiState == "paywall" }

        /// Apply launch state that must exist BEFORE the first view renders: skip
        /// onboarding and seed an in-progress fast (11h12m into a 16:8, i.e. the Fat
        /// Burning stage — matches the Live Activity hero) straight into the same
        /// UserDefaults keys `FastingManager` reads from.
        static func applyLaunchStateIfNeeded() {
            guard wantsDemoData else { return }
            let d = UserDefaults.standard
            d.set(true, forKey: "lf_onboarding_complete")

            // Active fast: started 11h12m ago on 16:8 (Fat Burning), target 16h.
            let start = Date.now.addingTimeInterval(-(11 * 3600 + 12 * 60))
            let target = start.addingTimeInterval(16 * 3600)
            d.set(true, forKey: "lf_fasting_active")
            d.set(start, forKey: "lf_fasting_start")
            d.set(target, forKey: "lf_fasting_end")
            d.set(FastingPlan.sixteenEight.rawValue, forKey: "lf_fasting_plan")
            d.set(false, forKey: "lf_fasting_paused")
            d.removeObject(forKey: "lf_fasting_pause_start")
            d.set(0.0, forKey: "lf_fasting_paused_total")
            d.set(4, forKey: "lf_fasting_water")

            // Streak cache so the status bar / insights read a healthy number.
            d.set(12, forKey: "lf_current_streak_cache")
        }
    }

    /// Seeds ~5 weeks of completed fasts (plus a few weight entries) so Insights,
    /// History, streak heatmap, and achievements render a real, filled outcome state.
    /// Idempotent: only seeds when the store is empty.
    enum DemoSeeder {
        @MainActor
        static func seedIfNeeded(into context: ModelContext) {
            guard ScreenshotTour.wantsDemoData else { return }
            let existing = try? context.fetch(FetchDescriptor<FastingSession>())
            guard (existing?.isEmpty ?? true) else { return }

            let cal = Calendar.current
            let plans: [FastingPlan] = [.sixteenEight, .eighteenSix, .sixteenEight, .fourteenTen, .sixteenEight, .twentyFour, .eighteenSix]
            let moods = ["😊", "🔥", "😊", "😐", "🔥", "😊", "🔥"]

            // Current-streak window: the last 14 days (today back through -13) are
            // consecutive completed fasts so `computeStreaks()` reads a healthy current
            // streak. Older days (−16…−34) carry a couple of gaps so the heatmap looks
            // real rather than a solid block. Each session starts ~09:00 ON its own day
            // so startOfDay(startDate) lands on that calendar day (what the streak walk
            // keys off).
            let skipOffsets: Set<Int> = [17, 23, 30]
            let recent = Array(0 ... 13)
            let older = Array(16 ... 34).filter { !skipOffsets.contains($0) }
            for dayOffset in (recent + older) {
                guard let day = cal.date(byAdding: .day, value: -dayOffset, to: Date.now) else { continue }
                // 01:00 on the target day — always in the past and keys startOfDay onto
                // that exact calendar day (what the streak walk counts).
                let start = cal.startOfDay(for: day).addingTimeInterval(3600)
                let plan = plans[dayOffset % plans.count]
                let planned = plan.fastingHours * 3600
                // Slight natural variance around the planned window.
                let actual = planned + Double((dayOffset % 3) - 1) * 900
                let session = FastingSession(startDate: start, targetEndDate: start.addingTimeInterval(planned), planType: plan)
                session.endDate = start.addingTimeInterval(actual)
                session.actualDuration = actual
                session.stageReached = FastingStage.stage(for: actual).rawValue
                session.isCompleted = true
                session.mood = moods[dayOffset % moods.count]
                session.waterCount = 3 + (dayOffset % 4)
                context.insert(session)
            }

            // A downward weight trend (kg) for the weight chart.
            let baseWeight = 78.5
            for (i, dayOffset) in stride(from: 35, through: 1, by: -5).enumerated() {
                guard let day = cal.date(byAdding: .day, value: -dayOffset, to: Date.now) else { continue }
                let entry = WeightEntry(date: day, weightKg: baseWeight - Double(i) * 0.6)
                context.insert(entry)
            }

            try? context.save()
        }
    }
#endif
