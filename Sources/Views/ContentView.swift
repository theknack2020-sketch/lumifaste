import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TimerView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
        }
        .tint(Color.accentColor)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: FastingSession.self, inMemory: true)
}
