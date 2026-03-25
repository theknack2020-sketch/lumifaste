import SwiftUI
import Charts

/// Smooth line chart showing weight trend over time.
/// Enhanced: linear regression trend line, total change badge, animated line entrance.
struct WeightTrendChart: View {
    let entries: [WeightEntry]
    @Environment(ThemeManager.self) private var themeManager
    @AppStorage("lf_weight_unit") private var useMetric = true
    @State private var animateChart = false
    @State private var animationProgress: CGFloat = 0
    
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
    
    /// Linear regression: returns (slope, intercept) for the trend line
    private var trendLine: (slope: Double, intercept: Double)? {
        guard displayEntries.count >= 2 else { return nil }
        
        let firstDate = (displayEntries.first?.date.timeIntervalSince1970 ?? 0)
        let n = Double(displayEntries.count)
        
        // x = days since first entry, y = weight
        let points = displayEntries.map { entry -> (x: Double, y: Double) in
            let days = (entry.date.timeIntervalSince1970 - firstDate) / 86400
            return (days, entry.weight)
        }
        
        let sumX = points.reduce(0.0) { $0 + $1.x }
        let sumY = points.reduce(0.0) { $0 + $1.y }
        let sumXY = points.reduce(0.0) { $0 + $1.x * $1.y }
        let sumX2 = points.reduce(0.0) { $0 + $1.x * $1.x }
        
        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return nil }
        
        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n
        
        return (slope, intercept)
    }
    
    /// Trend line endpoints for chart overlay
    private var trendLinePoints: [(date: Date, weight: Double)]? {
        guard let trend = trendLine, displayEntries.count >= 2 else { return nil }
        
        let firstDate = displayEntries.first?.date ?? Date()
        let lastDate = displayEntries.last?.date ?? Date()
        let firstDays = 0.0
        let lastDays = lastDate.timeIntervalSince(firstDate) / 86400
        
        let startWeight = trend.intercept + trend.slope * firstDays
        let endWeight = trend.intercept + trend.slope * lastDays
        
        return [
            (date: firstDate, weight: startWeight),
            (date: lastDate, weight: endWeight)
        ]
    }
    
    /// Total change from first to last entry
    private var totalChange: Double? {
        guard displayEntries.count > 1,
              let first = displayEntries.first,
              let last = displayEntries.last else { return nil }
        return last.weight - first.weight
    }
    
    /// Weekly rate of change (from regression)
    private var weeklyRate: Double? {
        guard let trend = trendLine else { return nil }
        return trend.slope * 7 // slope is per-day
    }
    
    var body: some View {
        let accent = themeManager.selectedTheme.accent
        
        VStack(alignment: .leading, spacing: 10) {
            // Summary row
            if let latest = displayEntries.last, displayEntries.count > 1 {
                summaryRow(latest: latest, accent: accent)
            }
            
            // Total change badge
            if let change = totalChange, let first = displayEntries.first {
                totalChangeBadge(change: change, sinceDate: first.date, accent: accent)
            }
            
            // Chart
            Chart {
                // Area fill
                ForEach(Array(displayEntries.enumerated()), id: \.offset) { _, entry in
                    AreaMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", animateChart ? entry.weight : displayEntries.first?.weight ?? entry.weight)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [Color.pink.opacity(0.3), Color.pink.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                // Main line
                ForEach(Array(displayEntries.enumerated()), id: \.offset) { _, entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", animateChart ? entry.weight : displayEntries.first?.weight ?? entry.weight)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.pink.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    
                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", animateChart ? entry.weight : displayEntries.first?.weight ?? entry.weight)
                    )
                    .symbolSize(24)
                    .foregroundStyle(Color.pink)
                }
                
                // Trend line (linear regression)
                if let trendPoints = trendLinePoints, animateChart {
                    ForEach(Array(trendPoints.enumerated()), id: \.offset) { _, point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Trend", point.weight),
                            series: .value("Series", "Trend")
                        )
                        .foregroundStyle(accent.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    }
                }
            }
            .chartYScale(domain: minWeight...maxWeight)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color(.systemGray4))
                    AxisValueLabel()
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.system(size: 10, design: .rounded))
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Weight trend chart")
            .accessibilityValue(weightChartAccessibilitySummary)
        }
        .onAppear {
            withAnimation(.spring(duration: 1.0, bounce: 0.1).delay(0.2)) {
                animateChart = true
            }
        }
    }
    
    // MARK: - Summary Row
    
    private func summaryRow(latest: (date: Date, weight: Double), accent: Color) -> some View {
        let diff = totalChange ?? 0
        
        return HStack(spacing: 6) {
            Text(String(format: "%.1f %@", latest.weight, unit))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .monospacedDigit()
            
            HStack(spacing: 2) {
                Image(systemName: diff <= 0 ? "arrow.down.right" : "arrow.up.right")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                Text(String(format: "%+.1f", diff))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(diff <= 0 ? .green : .red)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .fill((diff <= 0 ? Color.green : Color.red).opacity(0.12))
                    )
            )
            .shadow(color: (diff <= 0 ? Color.green : Color.red).opacity(0.15), radius: 4, y: 2)
            
            if let rate = weeklyRate, abs(rate) > 0.01 {
                Text(String(format: "%+.1f/wk", rate))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current weight")
        .accessibilityValue(String(format: "%.1f %@, %@ %.1f since first entry", latest.weight, unit, diff <= 0 ? "down" : "up", abs(diff)))
    }
    
    // MARK: - Total Change Badge
    
    private func totalChangeBadge(change: Double, sinceDate: Date, accent: Color) -> some View {
        let daysSince = max(1, Int(Date.now.timeIntervalSince(sinceDate) / 86400))
        let isLoss = change <= 0
        
        return HStack(spacing: 8) {
            Image(systemName: isLoss ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(isLoss ? .green : .red)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(String(format: "%+.1f %@ since start", change, unit))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                Text("\(daysSince) day\(daysSince == 1 ? "" : "s") tracked")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill((isLoss ? Color.green : Color.red).opacity(0.06))
                )
        )
        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: "Total change: %+.1f %@ over %d days", change, unit, daysSince))
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
