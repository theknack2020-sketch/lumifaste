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
    @State private var showHealthKitImport = false
    @State private var healthKitImportCount = 0
    @State private var isLoading = true
    
    // MARK: - Dynamic Type Support
    @ScaledMetric(relativeTo: .body) private var cardPadding: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var sectionSpacing: CGFloat = 20
    
    private var completedSessions: [FastingSession] {
        sessions.filter(\.isCompleted)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        Spacer()
                        ProgressView()
                            .controlSize(.large)
                        Text("Crunching your numbers…")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
                    .accessibilityLabel("Loading insights")
                } else if sessions.isEmpty {
                    emptyState
                } else {
                    statsContent
                }
            }
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.shared.lightTap()
                        if subscriptionManager.isSubscribed {
                            showWeightLog = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "scalemass")
                                .font(.system(size: 15))
                            if !subscriptionManager.isSubscribed {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .accessibilityIdentifier("weightLogButton")
                    .accessibilityLabel(subscriptionManager.isSubscribed ? "Log weight" : "Log weight — Pro feature")
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .sheet(isPresented: $showWeightLog) {
                WeightLogView()
            }
            .onAppear {
                if isLoading {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isLoading = false
                        }
                    }
                }
                // Fetch today's step count from Apple Health
                Task {
                    await HealthKitManager.shared.fetchTodaySteps()
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 28) {
            Spacer()
            
            // Hero illustration — layered rings with glow
            ZStack {
                // Outer ambient glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [themeManager.selectedTheme.accent.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                
                // Decorative ring 1
                Circle()
                    .stroke(themeManager.selectedTheme.accent.opacity(0.08), lineWidth: 1.5)
                    .frame(width: 180, height: 180)
                
                // Decorative ring 2
                Circle()
                    .stroke(themeManager.selectedTheme.accent.opacity(0.15), lineWidth: 2)
                    .frame(width: 120, height: 120)
                
                // Center icon with glass background
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 80, height: 80)
                        .shadow(color: themeManager.selectedTheme.accent.opacity(0.3), radius: 16, y: 4)
                    
                    Image(systemName: "chart.bar.xaxis.ascending")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(themeManager.selectedTheme.accentGradient)
                        .symbolEffect(.pulse, options: .repeating.speed(0.4))
                }
            }
            .entranceAnimation(delay: 0.1)
            
            // Text content
            VStack(spacing: 10) {
                Text("Insights Await")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                
                Text("Complete a few fasts to unlock\ncharts, streaks, and trends.")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Your journey starts with a single fast")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(themeManager.selectedTheme.accent.opacity(0.7))
                    .padding(.top, 4)
            }
            .entranceAnimation(delay: 0.25)
            
            // Feature preview badges — what they'll unlock
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    InsightPreviewBadge(icon: "flame.fill", title: "Streaks", color: .orange)
                    InsightPreviewBadge(icon: "chart.line.uptrend.xyaxis", title: "Trends", color: .green)
                    InsightPreviewBadge(icon: "calendar", title: "Calendar", color: .blue)
                }
                HStack(spacing: 12) {
                    InsightPreviewBadge(icon: "drop.fill", title: "Hydration", color: .cyan)
                    InsightPreviewBadge(icon: "face.smiling", title: "Mood", color: .yellow)
                    InsightPreviewBadge(icon: "scalemass.fill", title: "Weight", color: .purple)
                }
            }
            .entranceAnimation(delay: 0.4)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Insights await. Complete a few fasts to unlock charts, streaks, and trends.")
        .accessibilityIdentifier("statsEmptyState")
    }
    
    // MARK: - Stats Content
    
    private var statsContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Summary card — always visible (free: total fasts, streak, best streak)
                summaryCard
                    .staggeredEntrance(index: 0, appeared: cardsAppeared)
                
                // Motivational badge — always visible
                motivationalBadge
                    .staggeredEntrance(index: 1, appeared: cardsAppeared)
                
                // Pro-only sections: blurred preview + lock overlay for free users
                proGatedSection(index: 2) {
                    weeklyComparisonSection
                }
                
                proGatedSection(index: 3) {
                    weeklyChartSection
                }
                
                proGatedSection(index: 4) {
                    monthlyCalendarSection
                }
                
                proGatedSection(index: 5) {
                    streakHeatmapSection
                }
                
                proGatedSection(index: 6) {
                    moodTrendSection
                }
                
                proGatedSection(index: 7) {
                    hydrationSection
                }
                
                proGatedSection(index: 8) {
                    timeAnalysisSection
                }
                
                proGatedSection(index: 9) {
                    weightSection
                }
                
                proGatedSection(index: 10) {
                    consistencySection
                }
            }
            .padding(.horizontal, cardPadding)
            .padding(.vertical, 12)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    cardsAppeared = true
                }
            }
        }
    }
    
    /// Wraps a section with a blur + lock overlay for free users, or shows it fully for Pro.
    private func proGatedSection<Content: View>(index: Int, @ViewBuilder content: () -> Content) -> some View {
        Group {
            if subscriptionManager.isSubscribed {
                content()
                    .staggeredEntrance(index: index, appeared: cardsAppeared)
            } else {
                content()
                    .blur(radius: 6)
                    .allowsHitTesting(false)
                    .overlay {
                        proLockedOverlay
                    }
                    .staggeredEntrance(index: index, appeared: cardsAppeared)
            }
        }
    }
    
    /// Lock overlay shown on premium-only chart sections
    private var proLockedOverlay: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
            Text("Pro Feature")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
            Text("Upgrade to unlock full charts & trends")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Button {
                HapticManager.shared.lightTap()
                showPaywall = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                    Text("Upgrade to Pro")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: .purple.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(.pressable)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.7))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pro feature. Upgrade to unlock full charts and trends.")
        .accessibilityAddTraits(.isButton)
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
        let todaySteps = HealthKitManager.shared.todayStepCount
        
        return InsightCard(title: "Summary", icon: "square.grid.2x2.fill", color: accent) {
            VStack(spacing: 12) {
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
                
                // Today's step count from Apple Health
                if HealthKitManager.shared.isAvailable && todaySteps > 0 {
                    Divider()
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.red)
                        Image(systemName: "figure.walk")
                            .font(.system(size: 13))
                            .foregroundStyle(.green)
                        Text(todaySteps.formatted(.number.grouping(.automatic)))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text("steps today")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    .accessibilityLabel("\(todaySteps) steps today from Apple Health")
                }
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
    
    // MARK: - Streak Heatmap
    
    private var streakHeatmapSection: some View {
        InsightCard(title: "Streak Heatmap", icon: "square.grid.3x3.fill", color: .orange) {
            StreakHeatmapView(
                sessions: Array(sessions),
                isPro: subscriptionManager.isSubscribed
            )
        }
    }
    
    // MARK: - Mood Trends
    
    private var moodTrendSection: some View {
        MoodTrendChart()
    }
    
    // MARK: - Hydration
    
    private var hydrationSection: some View {
        HydrationChart()
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
            VStack(spacing: 12) {
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
                        .buttonStyle(.pressable)
                        .accessibilityLabel("Log your first weight entry")
                        .accessibilityHint("Opens weight logging sheet")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                } else {
                    WeightTrendChart(entries: Array(weightEntries.reversed()))
                        .frame(height: 180)
                }
                
                // HealthKit import button
                if HealthKitManager.shared.isAvailable {
                    healthKitImportButton
                }
            }
        }
    }
    
    // MARK: - HealthKit Import
    
    private var healthKitImportButton: some View {
        let hkManager = HealthKitManager.shared
        
        return VStack(spacing: 8) {
            Divider()
            
            Button {
                HapticManager.shared.lightTap()
                Task {
                    if !hkManager.hasRequestedPermission {
                        _ = await hkManager.requestAuthorization()
                    }
                    let existingDates = Set(weightEntries.map(\.date))
                    let imports = await hkManager.fetchWeightsForImport(existingDates: existingDates)
                    
                    if imports.isEmpty {
                        healthKitImportCount = 0
                        showHealthKitImport = true
                    } else {
                        for entry in imports {
                            let weightEntry = WeightEntry(date: entry.date, weightKg: entry.weightKg)
                            modelContext.insert(weightEntry)
                        }
                        let success = DataController.shared.save(modelContext, operation: "import weights from HealthKit")
                        healthKitImportCount = success ? imports.count : 0
                        showHealthKitImport = true
                        if success {
                            HapticManager.shared.success()
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                    Text("Import from Apple Health")
                        .font(.system(size: 13, weight: .medium))
                    
                    if hkManager.isImporting {
                        ProgressView()
                            .controlSize(.mini)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.pressable)
            .disabled(hkManager.isImporting)
            .accessibilityIdentifier("healthKitImportButton")
            .accessibilityLabel("Import weight data from Apple Health")
            .accessibilityHint("Fetches weight entries from HealthKit that are not already in the app")
        }
        .alert(
            healthKitImportCount > 0 ? "Imported" : "No New Data",
            isPresented: $showHealthKitImport
        ) {
            Button("OK") {}
        } message: {
            Text(
                healthKitImportCount > 0
                    ? "Imported \(healthKitImportCount) weight entries from Apple Health."
                    : "No new weight data found in Apple Health, or all entries are already imported."
            )
        }
    }
    
    // MARK: - Consistency
    
    private var consistencySection: some View {
        let total = sessions.count
        let completed = completedSessions.count
        let pct = total > 0 ? Double(completed) / Double(total) * 100 : 0
        
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
                .contentTransition(.numericText())
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

// MARK: - Insight Preview Badge (empty state)

private struct InsightPreviewBadge: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.1), radius: 8, y: 3)
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [FastingSession.self, WeightEntry.self, FastingJournal.self], inMemory: true)
        .environment(SubscriptionManager())
        .environment(ThemeManager())
}
