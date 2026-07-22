import BackgroundTasks
import os
import SwiftData
import SwiftUI

private let logger = Logger(subsystem: "com.theknack.lumifaste", category: "App")

@main
struct LumifasteApp: App {
    let modelContainer: ModelContainer
    @State private var subscriptionManager = SubscriptionManager()
    @State private var themeManager = ThemeManager()
    @State private var dataController = DataController.shared
    @State private var reviewPrompt = ReviewPromptManager()
    @AppStorage("lf_onboarding_complete") private var hasCompletedOnboarding = false
    @AppStorage("lf_appearance_mode") private var appearanceMode: String = AppearanceMode.system.rawValue
    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if DEBUG
            // Store-shots pipeline: apply demo launch state before the first view renders.
            ScreenshotTour.applyLaunchStateIfNeeded()
        #endif

        let schema = Schema([FastingSession.self, WeightEntry.self, FastingJournal.self, MealEntry.self])
        do {
            let config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            DataController.setCloudSyncAvailable(true)
        } catch {
            // CloudKit-backed store failed to open (e.g. no iCloud account, container
            // provisioning issue). Fall back to a LOCAL-ONLY store WITHOUT deleting the
            // on-disk data — the previous implementation wiped the user's database here,
            // which silently destroyed their history. Preserve the file so it re-syncs
            // once CloudKit is available again.
            logger.error("CloudKit ModelContainer init failed: \(error.localizedDescription)")
            logger.warning("Falling back to local-only store (data preserved)")
            DataController.setCloudSyncAvailable(false)
            do {
                let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                modelContainer = try ModelContainer(for: schema, configurations: [config])
            } catch {
                // Last resort: the on-disk store is unreadable even locally. Launch with an
                // in-memory store so the app still opens; the disk file is left untouched so
                // a future successful open can recover it. Never delete user data on launch.
                logger.error("Local-only store also failed: \(error.localizedDescription); using in-memory store")
                do {
                    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                    modelContainer = try ModelContainer(for: schema, configurations: [config])
                } catch {
                    fatalError("[Lumifaste] Cannot create any ModelContainer: \(error)")
                }
            }
        }

        // Register notification categories at launch
        NotificationManager.shared.registerCategories()

        // Register background app refresh task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.theknack.lumifaste.refresh",
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Self.handleBackgroundRefresh(refreshTask)
        }

        // Initial clock checkpoint
        _ = ClockGuard.checkClockIntegrity()
        _ = ClockGuard.checkTimezoneChange()
    }

    private var selectedAppearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceMode) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                        .environment(subscriptionManager)
                        .environment(themeManager)
                        .environment(dataController)
                        .environment(reviewPrompt)
                        .task {
                            await subscriptionManager.checkSubscriptionStatus()
                        }
                        .task {
                            // Count this launch toward the review-prompt session gate
                            // (never asks on the first runs).
                            reviewPrompt.trackSessionStart()
                        }
                        #if DEBUG
                        .task {
                            // Store-shots pipeline: seed demo history for filled-content shots.
                            DemoSeeder.seedIfNeeded(into: modelContainer.mainContext)
                        }
                        #endif
                        .task {
                            // Schedule inactivity nudge (#13) — checks every app foreground
                            await scheduleInactivityNudge()
                        }
                        .task {
                            // Reconcile the fasting Live Activity at launch (TheKnackKit
                            // SessionClock): ends an orphaned card left after an app kill,
                            // adopts a surviving one. Fixes the lingering/frozen LA bug.
                            await LiveActivityManager.reconcileOnLaunch(hasActiveFast: FastingManager().isActive)
                        }
                        .onOpenURL { url in
                            handleDeepLink(url)
                        }
                        .onChange(of: scenePhase) { _, newPhase in
                            if newPhase == .active {
                                // Re-check clock integrity on foreground
                                _ = ClockGuard.checkClockIntegrity()

                                // Re-check notification permission (user may have changed in Settings)
                                Task { @MainActor in
                                    await NotificationManager.shared.refreshPermissionStatus()
                                }
                            } else if newPhase == .background {
                                // Schedule background refresh for retention notifications
                                Self.scheduleBackgroundRefresh()
                            }
                        }
                        .alert("Storage Low",
                               isPresented: .constant(dataController.isStorageLow && hasCompletedOnboarding && !dataController.showSaveErrorAlert))
                        {
                            Button("OK") {}
                        } message: {
                            Text("Your device storage is low (\(dataController.availableStorageString) remaining). Fasting data may not save correctly. Please free up some space.")
                        }
                        .alert("Save Error",
                               isPresented: $dataController.showSaveErrorAlert)
                        {
                            Button("OK") {
                                dataController.showSaveErrorAlert = false
                            }
                        } message: {
                            Text(dataController.lastSaveError?.userMessage ?? "An error occurred while saving data.")
                        }
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                        .environment(subscriptionManager)
                        .environment(themeManager)
                }
            }
            .tint(themeManager.selectedTheme.accent)
            .preferredColorScheme(selectedAppearance.colorScheme)
            .animation(.smooth(duration: 0.35), value: themeManager.selectedTheme)
        }
        .modelContainer(modelContainer)
    }

    // MARK: - Deep Link Handling

    /// Handle lumifaste:// URL scheme for shared content.
    /// lumifaste://start — timer tab
    /// lumifaste://achievements — settings tab (achievements)
    /// lumifaste://share — opens app
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "lumifaste" else { return }
        let host = url.host() ?? url.host
        switch host {
        case "achievements":
            NotificationCenter.default.post(name: .deepLinkReceived, object: nil, userInfo: ["tab": 2])
        default:
            break
        }
    }

    /// Schedule a local notification nudge if user hasn't fasted in 3+ days (#13)
    @MainActor
    private func scheduleInactivityNudge() async {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<FastingSession>(
            predicate: #Predicate<FastingSession> { $0.isCompleted },
            sortBy: [SortDescriptor(\FastingSession.startDate, order: .reverse)]
        )

        guard let sessions = try? context.fetch(descriptor) else { return }

        if FastingManager.shouldShowNudge(sessions: sessions) {
            // Schedule nudge notification for tomorrow 10 AM if not already fasting
            let manager = FastingManager()
            guard !manager.isActive else { return }

            let content = UNMutableNotificationContent()
            content.title = "Ready to Fast? 🌿"
            content.body = "It's been a few days since your last fast. Your body benefits from consistency — even a short 12h fast helps!"
            content.sound = .default
            content.categoryIdentifier = NotificationCategory.dailyReminder.rawValue

            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date.now.addingTimeInterval(86400))
            components.hour = 10
            components.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "inactivity_nudge", content: content, trigger: trigger)

            try? await UNUserNotificationCenter.current().add(request)
        } else {
            // Cancel any pending nudge
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["inactivity_nudge"])
        }
    }

    // MARK: - Background Task Scheduling

    /// Schedule the background app refresh task. Called when the app enters background.
    private static func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.theknack.lumifaste.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 3600) // 4 hours from now
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            logger.warning("Background refresh scheduling failed: \(error.localizedDescription)")
        }
    }

    /// Handle background refresh — reschedule retention notifications (streak protection, inactivity nudge).
    private static func handleBackgroundRefresh(_ task: BGAppRefreshTask) {
        // Schedule the next refresh before doing work
        scheduleBackgroundRefresh()

        let workTask = Task { @MainActor in
            let manager = FastingManager()
            let isActive = manager.isActive

            // Reschedule streak and inactivity notifications
            let status = await NotificationManager.shared.authorizationStatus()
            guard status == .authorized else { return }

            // Streak reminder — protect streak if user hasn't fasted today
            let streak = UserDefaults.standard.integer(forKey: "lf_current_streak_cache")
            if streak > 0, !isActive {
                NotificationManager.shared.scheduleStreakReminder(currentStreak: streak)
            }

            // Inactivity nudge
            if !isActive {
                let content = UNMutableNotificationContent()
                content.title = "Ready to Fast? 🌿"
                content.body = "Keep your streak alive — start a fast today!"
                content.sound = .default

                var components = DateComponents()
                components.hour = 10
                components.minute = 0
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: "bg_inactivity_nudge", content: content, trigger: trigger)
                try? await UNUserNotificationCenter.current().add(request)
            }
        }

        task.expirationHandler = {
            workTask.cancel()
        }

        Task {
            await workTask.value
            task.setTaskCompleted(success: true)
        }
    }
}
