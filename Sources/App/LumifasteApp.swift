import SwiftUI
import SwiftData

@main
struct LumifasteApp: App {
    let modelContainer: ModelContainer
    @State private var subscriptionManager = SubscriptionManager()
    
    init() {
        do {
            modelContainer = try ModelContainer(for: FastingSession.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(subscriptionManager)
                .task {
                    await subscriptionManager.checkSubscriptionStatus()
                }
        }
        .modelContainer(modelContainer)
    }
}
