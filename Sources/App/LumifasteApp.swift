import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct LumifasteApp: App {
    let modelContainer: ModelContainer
    @State private var subscriptionManager = SubscriptionManager()
    @State private var themeManager = ThemeManager()
    @State private var dataController = DataController.shared
    @AppStorage("lf_onboarding_complete") private var hasCompletedOnboarding = false
    @AppStorage("lf_appearance_mode") private var appearanceMode: String = AppearanceMode.system.rawValue
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        do {
            let schema = Schema([FastingSession.self, WeightEntry.self, FastingJournal.self])
            let config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("[Lumifaste] CRITICAL: ModelContainer init failed: \(error)")
            print("[Lumifaste] Falling back to local-only store...")
            do {
                let schema = Schema([FastingSession.self, WeightEntry.self, FastingJournal.self])
                let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                let storeURL = config.url
                try? FileManager.default.removeItem(at: storeURL)
                try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
                try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
                modelContainer = try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("[Lumifaste] Cannot create ModelContainer: \(error)")
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
                        .task {
                            await subscriptionManager.checkSubscriptionStatus()
                        }
                        .task {
                            // Schedule inactivity nudge (#13) — checks every app foreground
                            await scheduleInactivityNudge()
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
                               isPresented: .constant(dataController.isStorageLow && hasCompletedOnboarding && !dataController.showSaveErrorAlert)) {
                            Button("OK") {}
                        } message: {
                            Text("Your device storage is low (\(dataController.availableStorageString) remaining). Fasting data may not save correctly. Please free up some space.")
                        }
                        .alert("Save Error",
                               isPresented: $dataController.showSaveErrorAlert) {
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
            print("[Lumifaste] Background refresh scheduling failed: \(error.localizedDescription)")
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
            if streak > 0 && !isActive {
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
