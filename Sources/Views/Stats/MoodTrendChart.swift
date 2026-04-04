import Charts
import SwiftData
import SwiftUI

/// Mood & energy trend chart over the last 30 days.
/// Displays mood as a line (tired=1 → great=4) with emoji point marks,
/// optional energy overlay, and summary cards below.
struct MoodTrendChart: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    @Query(sort: \FastingJournal.date, order: .reverse)
    private var allEntries: [FastingJournal]

    // MARK: - Computed

    /// Entries from the last 30 days, sorted ascending by date.
    private var entries: [FastingJournal] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        return allEntries
            .filter { $0.date >= cutoff }
            .sorted { $0.date < $1.date }
    }

    private var averageMood: Double {
        guard !entries.isEmpty else { return 0 }
        return entries.map { moodNumeric($0.mood) }.reduce(0, +) / Double(entries.count)
    }

    private var averageEnergy: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map(\.energy).reduce(0, +)) / Double(entries.count)
    }

    private var hasEnergyData: Bool {
        entries.contains { $0.energy > 0 }
    }

    var body: some View {
        let accent = themeManager.selectedTheme.accent

        InsightCard(title: "Mood Trends", icon: "face.smiling", color: .pink) {
            if entries.isEmpty {
                emptyState
            } else {
                VStack(spacing: 16) {
                    chartView(accent: accent)
                        .frame(height: 200)
                        .accessibilityLabel(chartAccessibilityLabel)

                    summaryRow(accent: accent)
                }
            }
        }
    }

    // MARK: - Chart

    private func chartView(accent: Color) -> some View {
        Chart {
            // Area fill under mood line
            ForEach(entries, id: \.id) { entry in
                AreaMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Mood", moodNumeric(entry.mood))
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [accent.opacity(0.25), accent.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Mood line
            ForEach(entries, id: \.id) { entry in
                LineMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Mood", moodNumeric(entry.mood))
                )
                .foregroundStyle(accent)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
                .symbol {
                    Text(entry.mood.emoji)
                        .font(.adaptiveCaption(isRegular: isRegular))
                }
            }

            // Average mood dashed line
            RuleMark(y: .value("Average", averageMood))
                .foregroundStyle(.secondary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                .annotation(position: .top, alignment: .trailing) {
                    Text("avg")
                        .font(.adaptiveSmallLabel(isRegular: isRegular))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                }

            // Energy line (if data exists)
            if hasEnergyData {
                ForEach(entries, id: \.id) { entry in
                    LineMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("Energy", Double(entry.energy) * 0.8)
                    )
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    .interpolationMethod(.catmullRom)
                }
            }
        }
        .chartYScale(domain: 0.5 ... 4.5)
        .chartYAxis {
            AxisMarks(values: [1, 2, 3, 4]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                    .foregroundStyle(.secondary.opacity(0.3))
                AxisValueLabel {
                    if let intVal = value.as(Int.self) {
                        Text(moodLabel(for: intVal))
                            .font(.adaptiveCaption2(isRegular: isRegular))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                    .foregroundStyle(.secondary.opacity(0.3))
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    .font(.adaptiveCaption2(isRegular: isRegular))
            }
        }
        .chartLegend(.hidden)
    }

    // MARK: - Summary Row

    private func summaryRow(accent: Color) -> some View {
        HStack(spacing: 12) {
            MoodSummaryCard(
                icon: "face.smiling",
                label: "Average Mood",
                value: moodLabel(for: Int(averageMood.rounded())),
                color: accent
            )

            MoodSummaryCard(
                icon: "bolt.fill",
                label: "Average Energy",
                value: String(format: "%.1f / 5", averageEnergy),
                color: .orange
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Average mood: \(moodLabel(for: Int(averageMood.rounded()))). Average energy: \(String(format: "%.1f out of 5", averageEnergy)).")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "face.dashed")
                .font(.adaptiveDisplay(size: 32, weight: .regular, design: .default, isRegular: isRegular))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse, options: .repeating.speed(0.5))
                .accessibilityHidden(true)

            Text("Complete fasts and log your mood to see trends here")
                .font(.adaptiveDetail(isRegular: isRegular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No mood data yet. Complete fasts and log your mood to see trends here.")
    }

    // MARK: - Helpers

    private func moodNumeric(_ mood: FastingMood) -> Double {
        switch mood {
        case .tired: 1
        case .neutral: 2
        case .good: 3
        case .great: 4
        }
    }

    private func moodLabel(for value: Int) -> String {
        switch value {
        case 1: "Tired"
        case 2: "Okay"
        case 3: "Good"
        case 4: "Great"
        default: "—"
        }
    }

    private var chartAccessibilityLabel: String {
        let count = entries.count
        let avgMoodText = moodLabel(for: Int(averageMood.rounded()))
        let energyText = hasEnergyData ? ", average energy \(String(format: "%.1f", averageEnergy)) out of 5" : ""
        return "Mood trend chart, \(count) entries over the last 30 days. Average mood: \(avgMoodText)\(energyText)."
    }
}

// MARK: - Summary Card

private struct MoodSummaryCard: View {
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
                .font(.adaptiveSubheadline(isRegular: isRegular))
                .foregroundStyle(color)

            Text(value)
                .font(.adaptiveSubheadline(isRegular: isRegular).weight(.bold))
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
    MoodTrendChart()
        .modelContainer(for: [FastingJournal.self], inMemory: true)
        .environment(ThemeManager())
}
