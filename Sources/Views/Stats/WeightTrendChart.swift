import SwiftUI
import Charts

/// Smooth line chart showing weight trend over time.
/// Uses Swift Charts with interpolation for a clean curve.
struct WeightTrendChart: View {
    let entries: [WeightEntry]
    @AppStorage("lf_weight_unit") private var useMetric = true
    
    private var displayEntries: [(date: Date, weight: Double)] {
        entries.map { entry in
            (date: entry.date, weight: useMetric ? entry.weightKg : entry.weightLbs)
        }
    }
    
    private var unit: String { useMetric ? "kg" : "lbs" }
    
    private var minWeight: Double {
        (displayEntries.map(\.weight).min() ?? 0) - 2
    }
    
    private var maxWeight: Double {
        (displayEntries.map(\.weight).max() ?? 100) + 2
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Summary
            if let latest = displayEntries.last, let first = displayEntries.first, displayEntries.count > 1 {
                let diff = latest.weight - first.weight
                HStack(spacing: 6) {
                    Text(String(format: "%.1f %@", latest.weight, unit))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    
                    HStack(spacing: 2) {
                        Image(systemName: diff <= 0 ? "arrow.down.right" : "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                        Text(String(format: "%+.1f", diff))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(diff <= 0 ? .green : .red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill((diff <= 0 ? Color.green : Color.red).opacity(0.12))
                    )
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Current weight")
                .accessibilityValue(String(format: "%.1f %@, %@ %.1f since first entry", latest.weight, unit, diff <= 0 ? "down" : "up", abs(diff)))
            }
            
            // Chart
            Chart {
                ForEach(Array(displayEntries.enumerated()), id: \.offset) { _, entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.pink.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    
                    AreaMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [Color.pink.opacity(0.3), Color.pink.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight)
                    )
                    .symbolSize(24)
                    .foregroundStyle(Color.pink)
                }
            }
            .chartYScale(domain: minWeight...maxWeight)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color(.systemGray4))
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.system(size: 10))
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Weight trend chart")
            .accessibilityValue(weightChartAccessibilitySummary)
        }
    }
    
    private var weightChartAccessibilitySummary: String {
        guard displayEntries.count > 1,
              let first = displayEntries.first,
              let last = displayEntries.last else {
            return "\(displayEntries.count) entries"
        }
        let diff = last.weight - first.weight
        return String(format: "%d entries from %.1f to %.1f %@, %@ %.1f overall",
                      displayEntries.count, first.weight, last.weight, unit,
                      diff <= 0 ? "down" : "up", abs(diff))
    }
}
