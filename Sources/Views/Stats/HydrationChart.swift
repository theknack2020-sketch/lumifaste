import Charts
import SwiftData
import SwiftUI

/// Daily water intake bar chart over the last 14 days.
/// Bars colored green when meeting goal, blue otherwise.
/// Shows daily goal line, average annotation, and summary row.
struct HydrationChart: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    @Query(sort: \FastingSession.startDate, order: .reverse)
    private var allSessions: [FastingSession]
    @AppStorage("lf_water_goal") private var dailyGoal: Int = 8

    // MARK: - Data Model

    private struct DayWater: Identifiable {
        let id: Date // start of day
        let glasses: Int
        let metGoal: Bool
    }

    // MARK: - Computed

    /// Aggregate water per calendar day for the last 14 days.
    private var dailyData: [DayWater] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let cutoff = calendar.date(byAdding: .day, value: -13, to: today) else { return [] }

        // Sum waterCount per calendar day
        var dayMap: [Date: Int] = [:]
        for session in allSessions {
            guard session.waterCount > 0 else { continue }
            let day = calendar.startOfDay(for: session.startDate)
            guard day >= cutoff else { continue }
            dayMap[day, default: 0] += session.waterCount
        }

        // Build 14-day array (fill gaps with 0)
        var result: [DayWater] = []
        for offset in 0 ..< 14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: cutoff) else { continue }
            let glasses = dayMap[day] ?? 0
            result.append(DayWater(id: day, glasses: glasses, metGoal: glasses >= dailyGoal))
        }
        return result
    }

    private var hasAnyWater: Bool {
        dailyData.contains { $0.glasses > 0 }
    }

    private var dailyAverage: Double {
        let daysWithWater = dailyData.filter { $0.glasses > 0 }
        guard !daysWithWater.isEmpty else { return 0 }
        return Double(daysWithWater.map(\.glasses).reduce(0, +)) / Double(daysWithWater.count)
    }

    private var bestDay: Int {
        dailyData.map(\.glasses).max() ?? 0
    }

    private var goalHitDays: Int {
        dailyData.filter(\.metGoal).count
    }

    var body: some View {
        InsightCard(title: "Hydration", icon: "drop.fill", color: .cyan) {
            if !hasAnyWater {
                emptyState
            } else {
                VStack(spacing: 16) {
                    chartView
                        .frame(height: 180)
                        .accessibilityLabel(chartAccessibilityLabel)

                    summaryRow
                }
            }
        }
    }

    // MARK: - Chart

    private var chartView: some View {
        Chart {
            ForEach(dailyData) { day in
                BarMark(
                    x: .value("Date", day.id, unit: .day),
                    y: .value("Glasses", day.glasses)
                )
                .foregroundStyle(
                    day.metGoal
                        ? LinearGradient(
                            colors: [.green.opacity(0.8), .green.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        : LinearGradient(
                            colors: [.blue.opacity(0.7), .cyan.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                )
                .cornerRadius(4)
            }

            // Daily goal line
            RuleMark(y: .value("Goal", dailyGoal))
                .foregroundStyle(.orange)
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .annotation(position: .top, alignment: .leading) {
                    Text("Goal: \(dailyGoal)")
                        .font(.adaptiveSmallLabel(isRegular: isRegular))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                }

            // Average annotation
            RuleMark(y: .value("Average", dailyAverage))
                .foregroundStyle(.secondary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .annotation(position: .bottom, alignment: .trailing) {
                    Text(String(format: "avg %.1f", dailyAverage))
                        .font(.adaptiveSmallLabel(isRegular: isRegular))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                    .foregroundStyle(.secondary.opacity(0.3))
                AxisValueLabel {
                    if let intVal = value.as(Int.self) {
                        Text("\(intVal)")
                            .font(.adaptiveCaption2(isRegular: isRegular))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                    .foregroundStyle(.secondary.opacity(0.3))
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    .font(.adaptiveCaption2(isRegular: isRegular))
            }
        }
        .chartLegend(.hidden)
    }

    // MARK: - Summary Row

    private var summaryRow: some View {
        HStack(spacing: 8) {
            HydrationSummaryCell(
                icon: "drop.fill",
                label: "Daily Avg",
                value: String(format: "%.1f", dailyAverage),
                color: .blue
            )

            HydrationSummaryCell(
                icon: "star.fill",
                label: "Best Day",
                value: "\(bestDay)",
                color: .orange
            )

            HydrationSummaryCell(
                icon: "checkmark.circle.fill",
                label: "Goal Hit",
                value: "\(goalHitDays)/14",
                color: .green
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily average: \(String(format: "%.1f", dailyAverage)) glasses. Best day: \(bestDay) glasses. Goal hit \(goalHitDays) out of 14 days.")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "drop.triangle")
                .font(.adaptiveDisplay(size: 32, weight: .regular, design: .default, isRegular: isRegular))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse, options: .repeating.speed(0.5))
                .accessibilityHidden(true)

            Text("Track water during your fasts to see hydration trends here")
                .font(.adaptiveDetail(isRegular: isRegular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No water data yet. Track water during your fasts to see hydration trends here.")
    }

    // MARK: - Helpers

    private var chartAccessibilityLabel: String {
        "Hydration chart, last 14 days. Daily average: \(String(format: "%.1f", dailyAverage)) glasses. Best day: \(bestDay). Goal met \(goalHitDays) of 14 days."
    }
}

// MARK: - Summary Cell

private struct HydrationSummaryCell: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.adaptiveDetail(isRegular: isRegular))
                .foregroundStyle(color)

            Text(value)
                .font(.adaptiveSubheadline(isRegular: isRegular).weight(.bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.adaptiveCaption(isRegular: isRegular))
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

#Preview {
    HydrationChart()
        .modelContainer(for: [FastingSession.self], inMemory: true)
        .environment(ThemeManager())
}
