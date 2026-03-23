import SwiftUI
import SwiftData
import Charts

/// Main insights/stats screen — charts, streaks, trends.
/// Free: basic stats (total, avg, streak counts). Premium: full charts, weight, time analysis.
struct StatsView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FastingSession.startDate, order: .reverse)
    private var sessions: [FastingSession]
    @Query(sort: \WeightEntry.date, order: .reverse)
    private var weightEntries: [WeightEntry]
    
    @State private var showPaywall = false
    @State private var showWeightLog = false
    
    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    emptyState
                } else {
                    statsContent
                }
            }
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showWeightLog = true
                    } label: {
                        Image(systemName: "scalemass")
                            .font(.system(size: 15))
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showWeightLog) {
                WeightLogView()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No data yet")
                .font(.system(size: 20, weight: .semibold))
            
            Text("Complete your first fast to\nsee your insights here.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Stats Content
    
    private var statsContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Hero stats cards
                heroStats
                
                // Streak display
                streakSection
                
                // Weekly chart
                weeklyChartSection
                
                // Weekly comparison
                weeklyComparisonSection
                
                // Monthly calendar
                monthlyCalendarSection
                
                // Time analysis
                timeAnalysisSection
                
                // Weight trend
                weightSection
                
                // Consistency
                consistencySection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Hero Stats
    
    private var heroStats: some View {
        let completed = sessions.filter(\.isCompleted)
        let totalHours = completed.reduce(0.0) { $0 + $1.actualDuration } / 3600
        let avgDuration = completed.isEmpty ? 0 : completed.reduce(0.0) { $0 + $1.actualDuration } / Double(completed.count)
        let longestFast = completed.map(\.actualDuration).max() ?? 0
        
        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                HeroStatCard(
                    title: "Total Hours",
                    value: String(format: "%.0f", totalHours),
                    subtitle: "fasted",
                    icon: "clock.fill",
                    color: .blue
                )
                HeroStatCard(
                    title: "Avg Duration",
                    value: formatHoursMinutes(avgDuration),
                    subtitle: "per fast",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
            }
            
            HStack(spacing: 12) {
                HeroStatCard(
                    title: "Total Fasts",
                    value: "\(completed.count)",
                    subtitle: "completed",
                    icon: "flame.fill",
                    color: .orange
                )
                HeroStatCard(
                    title: "Longest Fast",
                    value: formatHoursMinutes(longestFast),
                    subtitle: "personal best",
                    icon: "trophy.fill",
                    color: .yellow
                )
            }
        }
    }
    
    // MARK: - Streak Section
    
    private var streakSection: some View {
        let (current, best) = computeStreaks()
        
        return InsightCard(title: "Streaks", icon: "bolt.fill", color: .yellow) {
            HStack(spacing: 0) {
                VStack(spacing: 6) {
                    Text("\(current)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Current Streak")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text(current == 1 ? "day" : "days")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 50)
                
                VStack(spacing: 6) {
                    Text("\(best)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Best Streak")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text(best == 1 ? "day" : "days")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Weekly Chart Section
    
    private var weeklyChartSection: some View {
        InsightCard(title: "This Week", icon: "chart.bar.fill", color: .blue) {
            WeeklyFastingChart(sessions: sessions)
                .frame(height: 180)
        }
    }
    
    // MARK: - Weekly Comparison
    
    private var weeklyComparisonSection: some View {
        let (thisWeek, lastWeek) = weeklyComparison()
        let thisWeekHours = thisWeek.reduce(0.0) { $0 + $1.actualDuration } / 3600
        let lastWeekHours = lastWeek.reduce(0.0) { $0 + $1.actualDuration } / 3600
        let diff = thisWeekHours - lastWeekHours
        let pctChange: Double = lastWeekHours > 0 ? (diff / lastWeekHours) * 100 : (thisWeekHours > 0 ? 100 : 0)
        
        return InsightCard(title: "Week vs Week", icon: "arrow.left.arrow.right", color: .purple) {
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("This Week")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1fh", thisWeekHours))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text("\(thisWeek.count) fasts")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: diff >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 12, weight: .bold))
                        Text(String(format: "%+.0f%%", pctChange))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(diff >= 0 ? .green : .red)
                }
                .frame(width: 70)
                
                VStack(spacing: 4) {
                    Text("Last Week")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1fh", lastWeekHours))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text("\(lastWeek.count) fasts")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Monthly Calendar
    
    private var monthlyCalendarSection: some View {
        InsightCard(title: "This Month", icon: "calendar", color: .green) {
            MonthlyCalendarView(sessions: sessions)
        }
    }
    
    // MARK: - Time Analysis
    
    private var timeAnalysisSection: some View {
        InsightCard(title: "Time Patterns", icon: "clock.badge.checkmark", color: .cyan) {
            TimeAnalysisView(sessions: sessions)
        }
    }
    
    // MARK: - Weight Section
    
    private var weightSection: some View {
        InsightCard(title: "Weight Trend", icon: "scalemass.fill", color: .pink) {
            if weightEntries.isEmpty {
                VStack(spacing: 8) {
                    Text("No weight data yet")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    Button {
                        showWeightLog = true
                    } label: {
                        Label("Log Weight", systemImage: "plus.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                WeightTrendChart(entries: Array(weightEntries.reversed()))
                    .frame(height: 160)
            }
        }
    }
    
    // MARK: - Consistency
    
    private var consistencySection: some View {
        let total = sessions.count
        let completed = sessions.filter(\.isCompleted).count
        let pct = total > 0 ? Double(completed) / Double(total) * 100 : 0
        
        return InsightCard(title: "Consistency", icon: "checkmark.seal.fill", color: .mint) {
            VStack(spacing: 8) {
                Text(String(format: "%.0f%%", pct))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(pct >= 80 ? .green : pct >= 50 ? .orange : .red)
                
                Text("of fasts completed")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 24) {
                    Label("\(completed) done", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.green)
                    Label("\(total - completed) missed", systemImage: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Computation Helpers
    
    private func computeStreaks() -> (current: Int, best: Int) {
        let calendar = Calendar.current
        let completedDays = Set(
            sessions
                .filter(\.isCompleted)
                .map { calendar.startOfDay(for: $0.startDate) }
        )
        .sorted(by: >)
        
        guard !completedDays.isEmpty else { return (0, 0) }
        
        var currentStreak = 0
        var bestStreak = 0
        var tempStreak = 0
        var checkDate = calendar.startOfDay(for: .now)
        
        // Current streak — must include today or yesterday
        for day in completedDays {
            if day == checkDate {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if day == calendar.date(byAdding: .day, value: -1, to: checkDate)! {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: day)!
            } else {
                break
            }
        }
        
        // Best streak — scan all days
        let sortedAsc = completedDays.sorted()
        for (i, day) in sortedAsc.enumerated() {
            if i == 0 {
                tempStreak = 1
            } else {
                let prev = sortedAsc[i - 1]
                let diff = calendar.dateComponents([.day], from: prev, to: day).day ?? 0
                if diff == 1 {
                    tempStreak += 1
                } else {
                    tempStreak = 1
                }
            }
            bestStreak = max(bestStreak, tempStreak)
        }
        
        return (currentStreak, bestStreak)
    }
    
    private func weeklyComparison() -> (thisWeek: [FastingSession], lastWeek: [FastingSession]) {
        let calendar = Calendar.current
        let now = Date.now
        let startOfThisWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let startOfLastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfThisWeek)!
        
        let completed = sessions.filter(\.isCompleted)
        let thisWeek = completed.filter { $0.startDate >= startOfThisWeek }
        let lastWeek = completed.filter { $0.startDate >= startOfLastWeek && $0.startDate < startOfThisWeek }
        
        return (thisWeek, lastWeek)
    }
    
    private func formatHoursMinutes(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}

// MARK: - Hero Stat Card

private struct HeroStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Insight Card Container

struct InsightCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [FastingSession.self, WeightEntry.self], inMemory: true)
        .environment(SubscriptionManager())
        .environment(ThemeManager())
}
