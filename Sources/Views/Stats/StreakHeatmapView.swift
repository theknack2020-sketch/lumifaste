import SwiftUI

/// GitHub-style contribution heatmap showing last 90 days of fasting activity.
/// Each cell is colored by fasting duration intensity using the theme accent.
/// Free users: basic heatmap (30 days). Pro users: full 90 days + streak stats.
struct StreakHeatmapView: View {
    let sessions: [FastingSession]
    let isPro: Bool

    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    /// Number of days to display
    private var dayCount: Int {
        isPro ? 90 : 30
    }

    /// Number of columns (weeks)
    private var columnCount: Int {
        (dayCount + 6) / 7
    }

    private let cellSize: CGFloat = 14
    private let cellSpacing: CGFloat = 3

    private let weekdayLabels = ["M", "", "W", "", "F", "", ""]

    var body: some View {
        let accent = themeManager.selectedTheme.accent
        let heatmapData = buildHeatmapData()
        let (currentStreak, bestStreak) = computeStreaks()

        VStack(alignment: .leading, spacing: 14) {
            // Streak badges
            streakBadges(current: currentStreak, best: bestStreak, accent: accent)

            // Heatmap grid
            heatmapGrid(data: heatmapData, accent: accent)

            // Legend
            heatmapLegend(accent: accent)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("streakHeatmap")
        .accessibilityLabel("Fasting streak heatmap showing \(dayCount) days. Current streak: \(currentStreak) days. Best streak: \(bestStreak) days.")
    }

    // MARK: - Streak Badges

    private func streakBadges(current: Int, best: Int, accent _: Color) -> some View {
        HStack(spacing: 12) {
            StreakBadge(
                icon: "flame.fill",
                value: "\(current)",
                label: "Current",
                color: current > 0 ? .orange : .secondary
            )
            .accessibilityIdentifier("currentStreakBadge")

            StreakBadge(
                icon: "trophy.fill",
                value: "\(best)",
                label: "Best",
                color: .purple
            )
            .accessibilityIdentifier("bestStreakBadge")

            if isPro {
                let completedInPeriod = sessionsInPeriod().count
                StreakBadge(
                    icon: "checkmark.circle.fill",
                    value: "\(completedInPeriod)",
                    label: "\(dayCount)d Total",
                    color: .green
                )
                .accessibilityIdentifier("totalFastsBadge")
            }

            Spacer()
        }
    }

    // MARK: - Heatmap Grid

    private func heatmapGrid(data: [Date: Double], accent: Color) -> some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {
                // Weekday labels column
                VStack(alignment: .trailing, spacing: cellSpacing) {
                    ForEach(0 ..< 7, id: \.self) { row in
                        Text(weekdayLabels[row])
                            .font(.adaptiveSmallLabel(isRegular: isRegular))
                            .foregroundStyle(.tertiary)
                            .frame(width: 16, height: cellSize)
                    }
                }
                .padding(.trailing, 4)

                // Grid columns (each column = 1 week)
                HStack(spacing: cellSpacing) {
                    ForEach(0 ..< columnCount, id: \.self) { col in
                        VStack(spacing: cellSpacing) {
                            ForEach(0 ..< 7, id: \.self) { row in
                                let dayOffset = dayCount - 1 - (col * 7 + (6 - row))
                                if let cellDate = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                                    let cellDay = calendar.startOfDay(for: cellDate)

                                    if dayOffset >= 0, dayOffset < dayCount, cellDay <= today {
                                        let intensity = data[cellDay] ?? 0
                                        heatmapCell(intensity: intensity, accent: accent, date: cellDay, isToday: cellDay == today)
                                    } else {
                                        // Empty cell (future or out of range)
                                        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                                            .fill(.clear)
                                            .frame(width: cellSize, height: cellSize)
                                    }
                                } else {
                                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                                        .fill(.clear)
                                        .frame(width: cellSize, height: cellSize)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .accessibilityIdentifier("heatmapGrid")
    }

    private func heatmapCell(intensity: Double, accent: Color, date: Date, isToday: Bool) -> some View {
        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
            .fill(cellColor(intensity: intensity, accent: accent))
            .frame(width: cellSize, height: cellSize)
            .overlay {
                if isToday {
                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .stroke(accent, lineWidth: 1.5)
                }
            }
            .accessibilityLabel(cellAccessibilityLabel(intensity: intensity, date: date))
    }

    /// Map fasting duration intensity (0...1) to a color.
    /// 0 = no fast (empty), 0.01-0.33 = light, 0.34-0.66 = medium, 0.67-1.0 = dark
    private func cellColor(intensity: Double, accent: Color) -> Color {
        if intensity <= 0 {
            Color(.systemGray6)
        } else if intensity < 0.33 {
            accent.opacity(0.25)
        } else if intensity < 0.66 {
            accent.opacity(0.55)
        } else {
            accent.opacity(0.9)
        }
    }

    private func cellAccessibilityLabel(intensity: Double, date: Date) -> String {
        let dateStr = date.formatted(.dateTime.month(.abbreviated).day())
        if intensity <= 0 {
            return "\(dateStr): no fasting"
        } else if intensity < 0.33 {
            return "\(dateStr): short fast"
        } else if intensity < 0.66 {
            return "\(dateStr): moderate fast"
        } else {
            return "\(dateStr): long fast"
        }
    }

    // MARK: - Legend

    private func heatmapLegend(accent: Color) -> some View {
        HStack(spacing: 6) {
            Text("Less")
                .font(.adaptiveSmallLabel(isRegular: isRegular))
                .foregroundStyle(.tertiary)

            ForEach([0.0, 0.25, 0.55, 0.9], id: \.self) { opacity in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(opacity == 0 ? Color(.systemGray6) : accent.opacity(opacity))
                    .frame(width: 10, height: 10)
            }

            Text("More")
                .font(.adaptiveSmallLabel(isRegular: isRegular))
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .accessibilityHidden(true)
    }

    // MARK: - Data Helpers

    /// Build a map of date -> intensity (0...1) for the heatmap period.
    /// Intensity = actualDuration / 24h, clamped to 0...1
    private func buildHeatmapData() -> [Date: Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let startDate = calendar.date(byAdding: .day, value: -(dayCount - 1), to: today) else { return [:] }

        let completedSessions = sessions.filter { $0.isCompleted && $0.startDate >= startDate }

        var map: [Date: Double] = [:]

        for session in completedSessions {
            let day = calendar.startOfDay(for: session.startDate)
            let hoursOfFasting = session.actualDuration / 3600
            // Normalize: 24h fast = 1.0 intensity
            let intensity = min(hoursOfFasting / 24.0, 1.0)
            // If multiple fasts in a day, take the max intensity
            map[day] = max(map[day] ?? 0, intensity)
        }

        return map
    }

    /// Completed sessions within the heatmap period
    private func sessionsInPeriod() -> [FastingSession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let startDate = calendar.date(byAdding: .day, value: -(dayCount - 1), to: today) else { return [] }
        return sessions.filter { $0.isCompleted && $0.startDate >= startDate }
    }

    /// Compute current and best streaks from all sessions.
    private func computeStreaks() -> (current: Int, best: Int) {
        let calendar = Calendar.current
        let completedDays = Set(
            sessions
                .filter(\.isCompleted)
                .map { calendar.startOfDay(for: $0.startDate) }
        )
        .sorted(by: >)

        guard !completedDays.isEmpty else { return (0, 0) }

        // Current streak: count consecutive days ending today or yesterday
        var currentStreak = 0
        var checkDate = calendar.startOfDay(for: .now)

        // Allow starting from today or yesterday
        if !completedDays.contains(checkDate) {
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) {
                checkDate = yesterday
            }
        }

        for day in completedDays {
            if day == checkDate {
                currentStreak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else if day < checkDate {
                break
            }
        }

        // Best streak
        var bestStreak = 0
        var tempStreak = 0
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
}

// MARK: - Streak Badge

private struct StreakBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.adaptiveDetail(isRegular: isRegular))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.adaptiveHeadline(isRegular: isRegular).weight(.bold))
                    .monospacedDigit()
                Text(label)
                    .font(.adaptiveCaption(isRegular: isRegular).weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: color.opacity(0.12), radius: 4, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview {
    StreakHeatmapView(sessions: [], isPro: true)
        .padding()
        .environment(ThemeManager())
}
