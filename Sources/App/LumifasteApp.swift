import SwiftUI
import SwiftData

@main
struct LumifasteApp: App {
    let modelContainer: ModelContainer
    @State private var subscriptionManager = SubscriptionManager()
    @AppStorage("lf_onboarding_complete") private var hasCompletedOnboarding = false
    
    init() {
        do {
            modelContainer = try ModelContainer(for: FastingSession.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environment(subscriptionManager)
                    .task {
                        await subscriptionManager.checkSubscriptionStatus()
                    }
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .modelContainer(modelContainer)
    }
}
