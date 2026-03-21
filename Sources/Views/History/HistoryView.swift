import SwiftUI
import SwiftData

/// Geçmiş oruçların listesi — tarih sıralı, en yeni üstte.
struct HistoryView: View {
    @Query(sort: \FastingSession.startDate, order: .reverse)
    private var sessions: [FastingSession]
    
    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }
            .navigationTitle("History")
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No fasts yet")
                .font(.system(size: 20, weight: .semibold))
            
            Text("Complete your first fast and\nit will appear here.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Session List
    
    private var sessionList: some View {
        List {
            // Stats header
            statsSection
            
            // Sessions
            Section {
                ForEach(sessions) { session in
                    FastingSessionRow(session: session)
                }
            } header: {
                Text("Recent Fasts")
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        Section {
            HStack(spacing: 0) {
                StatCard(
                    title: "Total Fasts",
                    value: "\(sessions.count)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Current Streak",
                    value: "\(currentStreak)",
                    icon: "bolt.fill",
                    color: .yellow
                )
                
                StatCard(
                    title: "Avg Duration",
                    value: formatHours(averageDuration),
                    icon: "clock.fill",
                    color: .blue
                )
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Computed Stats
    
    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: .now)
        
        for session in sessions where session.isCompleted {
            let sessionDay = calendar.startOfDay(for: session.startDate)
            if sessionDay == checkDate || sessionDay == calendar.date(byAdding: .day, value: -1, to: checkDate)! {
                streak += 1
                checkDate = sessionDay
            } else if sessionDay < calendar.date(byAdding: .day, value: -1, to: checkDate)! {
                break
            }
        }
        return streak
    }
    
    private var averageDuration: TimeInterval {
        let completed = sessions.filter(\.isCompleted)
        guard !completed.isEmpty else { return 0 }
        let total = completed.reduce(0.0) { $0 + $1.actualDuration }
        return total / Double(completed.count)
    }
    
    private func formatHours(_ duration: TimeInterval) -> String {
        let hours = duration / 3600
        if hours < 1 {
            return "\(Int(duration / 60))m"
        }
        return String(format: "%.1fh", hours)
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
            
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: FastingSession.self, inMemory: true)
}
