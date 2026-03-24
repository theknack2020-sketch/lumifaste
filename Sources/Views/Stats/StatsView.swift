import SwiftUI
import SwiftData
import Charts

/// Main insights/stats screen — charts, streaks, trends.
/// Free: basic stats (total, avg, streak counts). Premium: full charts, weight, time analysis.
struct StatsView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FastingSession.startDate, order: .reverse)
    private var sessions: [FastingSession]
    @Query(sort: \WeightEntry.date, order: .reverse)
    private var weightEntries: [WeightEntry]
    
    @State private var showPaywall = false
    @State private var showWeightLog = false
    @State private var cardsAppeared = false
    
    private var completedSessions: [FastingSession] {
        sessions.filter(\.isCompleted)
    }
    
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
                    .accessibilityIdentifier("weightLogButton")
                    .accessibilityLabel("Log weight")
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
        let accent = themeManager.selectedTheme.accent
        
        return VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(accent.opacity(0.08), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .stroke(Color.green.opacity(0.1), lineWidth: 8)
                    .frame(width: 88, height: 88)
                
                Circle()
                    .stroke(Color.orange.opacity(0.12), lineWidth: 6)
                    .frame(width: 60, height: 60)
                
                Image(systemName: "chart.bar.xaxis.ascending")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(accent)
            }
            .accessibilityHidden(true)
            
            VStack(spacing: 10) {
                Text("Insights Await")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                
                Text("Complete a few fasts to unlock\ncharts, streaks, and trends.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Insights await. Complete a few fasts to unlock charts, streaks, and trends.")
            
            HStack(spacing: 16) {
                InsightPreviewPill(icon: "flame.fill", label: "Streaks", color: .orange)
                InsightPreviewPill(icon: "chart.line.uptrend.xyaxis", label: "Trends", color: .green)
                InsightPreviewPill(icon: "calendar", label: "Calendar", color: accent)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Unlock Streaks, Trends, and Calendar views")
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Stats Content
    
    private var statsContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Summary card — 3x2 grid with key metrics
                summaryCard
                    .staggeredEntrance(index: 0, appeared: cardsAppeared)
                
                // Motivational badge
                motivationalBadge
                    .staggeredEntrance(index: 1, appeared: cardsAppeared)
                
                // This Week vs Last Week comparison
                weeklyComparisonSection
                    .staggeredEntrance(index: 2, appeared: cardsAppeared)
                
                // Weekly chart
                weeklyChartSection
                    .staggeredEntrance(index: 3, appeared: cardsAppeared)
                
                // Monthly calendar
                monthlyCalendarSection
                    .staggeredEntrance(index: 4, appeared: cardsAppeared)
                
                // Time analysis
                timeAnalysisSection
                    .staggeredEntrance(index: 5, appeared: cardsAppeared)
                
                // Weight trend
                weightSection
                    .staggeredEntrance(index: 6, appeared: cardsAppeared)
                
                // Consistency
                consistencySection
                    .staggeredEntrance(index: 7, appeared: cardsAppeared)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    cardsAppeared = true
                }
            }
        }
    }
    
    // MARK: - Summary Card (3x2 Grid)
    
    private var summaryCard: some View {
        let accent = themeManager.selectedTheme.accent
        let completed = completedSessions
        let totalFasts = completed.count
        let totalHours = completed.reduce(0.0) { $0 + $1.actualDuration } / 3600
        let avgDuration = completed.isEmpty ? 0 : completed.reduce(0.0) { $0 + $1.actualDuration } / Double(completed.count)
        let completionRate = sessions.isEmpty ? 0 : Double(completed.count) / Double(sessions.count) * 100
        let (currentStreak, bestStreak) = computeStreaks()
        
        return InsightCard(title: "Summary", icon: "square.grid.2x2.fill", color: accent) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 12) {
                SummaryMetricCell(icon: "flame.fill", value: "\(totalFasts)", label: "Total Fasts", color: .orange)
                SummaryMetricCell(icon: "clock.fill", value: String(format: "%.0f", totalHours), label: "Total Hours", color: accent)
                SummaryMetricCell(icon: "chart.line.uptrend.xyaxis", value: formatHoursMinutes(avgDuration), label: "Avg Duration", color: .green)
                SummaryMetricCell(icon: "checkmark.circle.fill", value: String(format: "%.0f%%", completionRate), label: "Completion", color: completionRate >= 70 ? .green : .orange)
                SummaryMetricCell(icon: "bolt.fill", value: "\(currentStreak)", label: "Streak", color: .yellow)
                SummaryMetricCell(icon: "trophy.fill", value: "\(bestStreak)", label: "Best Streak", color: .purple)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Summary: \(totalFasts) fasts, \(String(format: "%.0f", totalHours)) hours, \(formatHoursMinutes(avgDuration)) average, \(String(format: "%.0f%%", completionRate)) completion, \(currentStreak) day streak, \(bestStreak) best streak")
        }
    }
    
    // MARK: - Motivational Badge
    
    private var motivationalBadge: some View {
        let accent = themeManager.selectedTheme.accent
        let completed = completedSessions
        let completionRate = sessions.isEmpty ? 0 : Double(completed.count) / Double(sessions.count) * 100
        let (currentStreak, _) = computeStreaks()
        
        let badge = determineBadge(fastCount: completed.count, completionRate: completionRate, currentStreak: currentStreak)
        
        return HStack(spacing: 12) {
            Text(badge.emoji)
                .font(.system(size: 28))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(badge.title)
                    .font(.system(.headline, design: .rounded))
                Text(badge.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.1), accent.opacity(0.02)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .shadow(color: accent.opacity(0.1), radius: 12, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(badge.title): \(badge.subtitle)")
    }
    
    // MARK: - Weekly Comparison
    
    private var weeklyComparisonSection: some View {
        let accent = themeManager.selectedTheme.accent
        let (thisWeek, lastWeek) = weeklyComparison()
        let thisWeekHours = thisWeek.reduce(0.0) { $0 + $1.actualDuration } / 3600
        let lastWeekHours = lastWeek.reduce(0.0) { $0 + $1.actualDuration } / 3600
        let diff = thisWeekHours - lastWeekHours
        let pctChange: Double = lastWeekHours > 0 ? (diff / lastWeekHours) * 100 : (thisWeekHours > 0 ? 100 : 0)
        let countDiff = thisWeek.count - lastWeek.count
        
        return InsightCard(title: "This Week vs Last Week", icon: "arrow.left.arrow.right", color: .purple) {
            VStack(spacing: 12) {
                // Hours comparison
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("This Week")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1fh", thisWeekHours))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("\(thisWeek.count) fasts")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("This week")
                    .accessibilityValue(String(format: "%.1f hours, %d fasts", thisWeekHours, thisWeek.count))
                    
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: diff >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 12, weight: .bold))
                            Text(String(format: "%+.0f%%", pctChange))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .monospacedDigit()
                        }
                        .foregroundStyle(diff >= 0 ? .green : .red)
                    }
                    .frame(width: 70)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Weekly change")
                    .accessibilityValue(String(format: "%+.0f percent", pctChange))
                    
                    VStack(spacing: 4) {
                        Text("Last Week")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1fh", lastWeekHours))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("\(lastWeek.count) fasts")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Last week")
                    .accessibilityValue(String(format: "%.1f hours, %d fasts", lastWeekHours, lastWeek.count))
                }
                
                // Delta indicators row
                Divider()
                
                HStack(spacing: 16) {
                    ComparisonDelta(
                        label: "Hours",
                        delta: diff,
                        format: "%+.1fh",
                        accent: accent
                    )
                    ComparisonDelta(
                        label: "Fasts",
                        delta: Double(countDiff),
                        format: "%+.0f",
                        accent: accent
                    )
                    
                    if !thisWeek.isEmpty && !lastWeek.isEmpty {
                        let thisAvg = thisWeekHours / Double(thisWeek.count)
                        let lastAvg = lastWeekHours / Double(lastWeek.count)
                        ComparisonDelta(
                            label: "Avg/Fast",
                            delta: thisAvg - lastAvg,
                            format: "%+.1fh",
                            accent: accent
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Weekly Chart Section
    
    private var weeklyChartSection: some View {
        InsightCard(title: "This Week", icon: "chart.bar.fill", color: .blue) {
            WeeklyFastingChart(sessions: sessions)
                .frame(height: 200)
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
                    .accessibilityLabel("Log your first weight entry")
                    .accessibilityHint("Opens weight logging sheet")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                WeightTrendChart(entries: Array(weightEntries.reversed()))
                    .frame(height: 180)
            }
        }
    }
    
    // MARK: - Consistency
    
    private var consistencySection: some View {
        let total = sessions.count
        let completed = completedSessions.count
        let pct = total > 0 ? Double(completed) / Double(total) * 100 : 0
        let accent = themeManager.selectedTheme.accent
        
        return InsightCard(title: "Consistency", icon: "checkmark.seal.fill", color: .mint) {
            VStack(spacing: 8) {
                Text(String(format: "%.0f%%", pct))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                pct >= 80 ? .green : pct >= 50 ? .orange : .red,
                                pct >= 80 ? .mint : pct >= 50 ? .yellow : .orange
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Text("of fasts completed")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 24) {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.green)
                        Text("\(completed) done")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(.green.opacity(0.1))
                    )
                    
                    HStack(spacing: 5) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                        Text("\(total - completed) missed")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(.red.opacity(0.1))
                    )
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Consistency rate")
            .accessibilityValue(String(format: "%.0f percent, %d completed, %d missed", pct, completed, total - completed))
        }
    }
    
    // MARK: - Badge Determination
    
    private struct BadgeInfo {
        let emoji: String
        let title: String
        let subtitle: String
    }
    
    private func determineBadge(fastCount: Int, completionRate: Double, currentStreak: Int) -> BadgeInfo {
        if currentStreak >= 30 {
            return BadgeInfo(emoji: "👑", title: "Fasting Legend", subtitle: "\(currentStreak)-day streak! Unstoppable.")
        } else if currentStreak >= 14 {
            return BadgeInfo(emoji: "🔥", title: "On Fire", subtitle: "\(currentStreak) days in a row — incredible focus.")
        } else if currentStreak >= 7 {
            return BadgeInfo(emoji: "⭐", title: "Week Warrior", subtitle: "A full week of consistency. Keep going!")
        } else if completionRate >= 80 {
            return BadgeInfo(emoji: "🏆", title: "Consistent Faster", subtitle: "\(Int(completionRate))% completion. You're building a habit.")
        } else if completionRate >= 70 {
            return BadgeInfo(emoji: "💪", title: "Building Momentum", subtitle: "\(Int(completionRate))% completion rate. Strong trajectory.")
        } else if fastCount >= 10 {
            return BadgeInfo(emoji: "📈", title: "Finding Your Rhythm", subtitle: "\(fastCount) fasts done. Your pattern is forming.")
        } else if fastCount >= 5 {
            return BadgeInfo(emoji: "🌱", title: "Growing Stronger", subtitle: "\(fastCount) fasts completed. Momentum building!")
        } else {
            return BadgeInfo(emoji: "🚀", title: "Getting Started", subtitle: "\(fastCount) fast\(fastCount == 1 ? "" : "s") so far. Every journey starts here.")
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
        
        for day in completedDays {
            if day == checkDate {
                currentStreak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else if let prev = calendar.date(byAdding: .day, value: -1, to: checkDate), day == prev {
                currentStreak += 1
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
                checkDate = prevDay
            } else {
                break
            }
        }
        
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
        let startOfLastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfThisWeek) ?? startOfThisWeek
        
        let completed = completedSessions
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

// MARK: - Summary Metric Cell

private struct SummaryMetricCell: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: color.opacity(0.12), radius: 4, y: 2)
    }
}

// MARK: - Comparison Delta

private struct ComparisonDelta: View {
    let label: String
    let delta: Double
    let format: String
    let accent: Color
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: delta > 0 ? "arrow.up" : delta < 0 ? "arrow.down" : "equal")
                    .font(.system(size: 9, weight: .bold))
                Text(String(format: format, delta))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(delta > 0 ? .green : delta < 0 ? .red : .secondary)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(String(format: format, delta))")
    }
}

// MARK: - Staggered Entrance Animation

private extension View {
    func staggeredEntrance(index: Int, appeared: Bool) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .scaleEffect(appeared ? 1 : 0.97, anchor: .top)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.78)
                .delay(Double(index) * 0.06),
                value: appeared
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
                    .font(.system(.headline, design: .rounded))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.15), color.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .shadow(color: color.opacity(0.08), radius: 12, y: 2)
    }
}

// MARK: - Insight Preview Pill (empty state)

private struct InsightPreviewPill: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.08))
                )
        )
        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [FastingSession.self, WeightEntry.self], inMemory: true)
        .environment(SubscriptionManager())
        .environment(ThemeManager())
}
