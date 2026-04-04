import Charts
import SwiftUI

/// Weekly bar chart — shows fasting hours per day for the current week.
/// Enhanced: average line, color coding (completed vs cancelled), tap-to-detail, animated entrance.
struct WeeklyFastingChart: View {
    let sessions: [FastingSession]
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    @State private var animateChart = false
    @State private var selectedDay: DayData?

    private var weekData: [DayData] {
        let calendar = Calendar.current
        let now = Date.now
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now

        return (0 ..< 7).compactMap { dayOffset -> DayData? in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else { return nil }
            let dayStart = calendar.startOfDay(for: date)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return nil }

            let daySessions = sessions.filter { $0.startDate >= dayStart && $0.startDate < dayEnd }
            let completedHours = daySessions.filter(\.isCompleted)
                .reduce(0.0) { $0 + $1.actualDuration / 3600 }
            let cancelledHours = daySessions.filter { !$0.isCompleted && $0.endDate != nil }
                .reduce(0.0) { $0 + $1.actualDuration / 3600 }

            let dayName = date.formatted(.dateTime.weekday(.abbreviated))
            let isToday = calendar.isDateInToday(date)
            let completedCount = daySessions.filter(\.isCompleted).count
            let cancelledCount = daySessions.count(where: { !$0.isCompleted && $0.endDate != nil })

            return DayData(
                day: dayName,
                completedHours: completedHours,
                cancelledHours: cancelledHours,
                isToday: isToday,
                date: date,
                completedCount: completedCount,
                cancelledCount: cancelledCount
            )
        }
    }

    private var averageHours: Double {
        let activeDays = weekData.filter { $0.totalHours > 0 }
        guard !activeDays.isEmpty else { return 0 }
        return activeDays.reduce(0.0) { $0 + $1.totalHours } / Double(activeDays.count)
    }

    var body: some View {
        let accent = themeManager.selectedTheme.accent

        VStack(spacing: 8) {
            Chart {
                // Completed hours bars
                ForEach(weekData) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Hours", animateChart ? item.completedHours : 0)
                    )
                    .foregroundStyle(
                        item.isToday
                            ? accent.gradient
                            : Color.green.opacity(0.7).gradient
                    )
                    .cornerRadius(6)
                }

                // Cancelled hours bars (stacked on top)
                ForEach(weekData.filter { $0.cancelledHours > 0 }) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        yStart: .value("Start", animateChart ? item.completedHours : 0),
                        yEnd: .value("End", animateChart ? item.totalHours : 0)
                    )
                    .foregroundStyle(Color.orange.opacity(0.6).gradient)
                    .cornerRadius(6)
                }

                // Average line
                if averageHours > 0, animateChart {
                    RuleMark(y: .value("Average", averageHours))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                        .foregroundStyle(accent.opacity(0.6))
                        .annotation(position: .top, alignment: .trailing) {
                            Text(String(format: "avg %.1fh", averageHours))
                                .font(.adaptiveSmallLabel(isRegular: isRegular))
                                .foregroundStyle(accent)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(accent.opacity(0.08))
                                )
                        }
                }
            }
            .chartYAxisLabel("hours")
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color(.systemGray4))
                    AxisValueLabel()
                        .font(.adaptiveCaption(isRegular: isRegular))
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.adaptiveBadge(isRegular: isRegular).weight(.medium))
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            guard let plotFrame = proxy.plotFrame else { return }
                            let xPos = location.x - geo[plotFrame].origin.x
                            if let dayValue: String = proxy.value(atX: xPos) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if selectedDay?.day == dayValue {
                                        selectedDay = nil
                                    } else {
                                        selectedDay = weekData.first { $0.day == dayValue }
                                    }
                                }
                                HapticManager.shared.lightTap()
                            }
                        }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Weekly fasting chart")
            .accessibilityValue(weeklyAccessibilitySummary)

            // Tap detail popup
            if let day = selectedDay {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                            .font(.adaptiveDetail(isRegular: isRegular).weight(.semibold))

                        HStack(spacing: 8) {
                            if day.completedHours > 0 {
                                Label(String(format: "%.1fh completed", day.completedHours), systemImage: "checkmark.circle.fill")
                                    .font(.adaptiveBadge(isRegular: isRegular))
                                    .foregroundStyle(.green)
                            }
                            if day.cancelledHours > 0 {
                                Label(String(format: "%.1fh cancelled", day.cancelledHours), systemImage: "xmark.circle.fill")
                                    .font(.adaptiveBadge(isRegular: isRegular))
                                    .foregroundStyle(.orange)
                            }
                            if day.totalHours == 0 {
                                Text("No fasts")
                                    .font(.adaptiveBadge(isRegular: isRegular))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Spacer()

                    Button {
                        withAnimation { selectedDay = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.adaptiveSubheadline(isRegular: isRegular))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Dismiss detail")
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
            }

            // Legend
            if weekData.contains(where: { $0.cancelledHours > 0 }) {
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Circle().fill(.green).frame(width: 7, height: 7)
                        Text("Completed").font(.adaptiveCaption(isRegular: isRegular)).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(.orange).frame(width: 7, height: 7)
                        Text("Cancelled").font(.adaptiveCaption(isRegular: isRegular)).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.15).delay(0.2)) {
                animateChart = true
            }
        }
    }

    private var weeklyAccessibilitySummary: String {
        let totalHours = weekData.reduce(0.0) { $0 + $1.completedHours }
        let activeDays = weekData.count(where: { $0.completedHours > 0 })
        if totalHours == 0 {
            return "No fasting this week"
        }
        return String(format: "%.1f total hours fasted across %d day%@, average %.1f hours per active day", totalHours, activeDays, activeDays == 1 ? "" : "s", averageHours)
    }
}

// MARK: - Data Model

private struct DayData: Identifiable {
    let day: String
    let completedHours: Double
    let cancelledHours: Double
    let isToday: Bool
    let date: Date
    let completedCount: Int
    let cancelledCount: Int
    var id: String {
        day
    }

    var totalHours: Double {
        completedHours + cancelledHours
    }
}
