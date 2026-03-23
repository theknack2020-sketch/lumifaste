import SwiftUI

struct ContentView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var selectedTab = 0
    @State private var fastingStatusManager = FastingManager()
    
    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                TimerView()
                    .tabItem {
                        Label("Timer", systemImage: "timer")
                    }
                    .tag(0)
                    .accessibilityLabel("Timer tab")
                    .accessibilityHint("Fasting timer and controls")
                
                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                    .tag(1)
                    .accessibilityLabel("History tab")
                    .accessibilityHint("View past fasting sessions")
                
                LearnView()
                    .tabItem {
                        Label("Learn", systemImage: "book.fill")
                    }
                    .tag(2)
                    .accessibilityLabel("Learn tab")
                    .accessibilityHint("Educational content about fasting")
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .tag(3)
                    .accessibilityLabel("Settings tab")
                    .accessibilityHint("App settings and preferences")
            }
            .tint(themeManager.selectedTheme.accent)
            .animation(.smoothSpring, value: selectedTab)
            .onAppear {
                let tabBarAppearance = UITabBarAppearance()
                tabBarAppearance.configureWithDefaultBackground()
                tabBarAppearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.92)
                tabBarAppearance.shadowColor = UIColor.label.withAlphaComponent(0.08)
                UITabBar.appearance().standardAppearance = tabBarAppearance
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
            .onChange(of: selectedTab) { _, _ in
                HapticManager.shared.selectionChanged()
            }
            .onReceive(NotificationCenter.default.publisher(for: .deepLinkReceived)) { notification in
                if let tab = notification.userInfo?["tab"] as? Int {
                    selectedTab = tab
                }
            }
            
            // Global fasting status indicator — visible on non-timer tabs (#13)
            if fastingStatusManager.isActive && selectedTab != 0 {
                FastingStatusBar(manager: fastingStatusManager, themeAccent: themeManager.selectedTheme.accent) {
                    withAnimation(.smoothSpring) {
                        selectedTab = 0
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.smoothSpring, value: selectedTab)
            }
        }
    }
}

// MARK: - Global Fasting Status Bar

/// Floating status bar shown on non-timer tabs when a fast is active.
/// Tapping it navigates back to the timer tab.
private struct FastingStatusBar: View {
    let manager: FastingManager
    let themeAccent: Color
    let onTap: () -> Void
    
    @State private var pulsePhase = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Pulsing dot
                Circle()
                    .fill(manager.isPaused ? Color.orange : Color.green)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulsePhase ? 1.3 : 1.0)
                    .opacity(pulsePhase ? 0.7 : 1.0)
                
                Image(systemName: manager.isPaused ? "pause.fill" : "timer")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(manager.isPaused ? .orange : themeAccent)
                
                Text(formatElapsed(manager.elapsedTime))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText(countsDown: false))
                
                Text("·")
                    .foregroundStyle(.tertiary)
                
                Text(manager.currentStage.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(manager.currentStage.color)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
        .onAppear {
            if !manager.isPaused {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulsePhase = true
                }
            }
        }
        .accessibilityLabel("Currently fasting, \(formatElapsed(manager.elapsedTime)) elapsed, \(manager.currentStage.rawValue) stage. Tap to return to timer.")
    }
    
    private func formatElapsed(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600
        let m = (Int(t) % 3600) / 60
        let s = Int(t) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FastingSession.self, WeightEntry.self], inMemory: true)
        .environment(SubscriptionManager())
        .environment(ThemeManager())
}
