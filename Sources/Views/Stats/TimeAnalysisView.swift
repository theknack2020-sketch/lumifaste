import SwiftUI
import Charts

/// Time-of-day analysis — when users typically start and end fasts.
/// Enhanced: best time recommendation, day-of-week analysis, visual heatmap.
struct TimeAnalysisView: View {
    let sessions: [FastingSession]
    @Environment(ThemeManager.self) private var themeManager
    
    private var completed: [FastingSession] {
        sessions.filter(\.isCompleted)
    }
    
    // MARK: - Computed Data
    
    private var hourData: [HourBucket] {
        guard !completed.isEmpty else { return [] }
        let calendar = Calendar.current
        
        var startCounts = [Int: Int]()
        var endCounts = [Int: Int]()
        
        for session in completed {
            let startHour = calendar.component(.hour, from: session.startDate)
            startCounts[startHour, default: 0] += 1
            
            if let endDate = session.endDate {
                let endHour = calendar.component(.hour, from: endDate)
                endCounts[endHour, default: 0] += 1
            }
        }
        
        var buckets: [HourBucket] = []
        for hour in 0..<24 {
            let label = formatHour(hour)
            if let starts = startCounts[hour], starts > 0 {
                buckets.append(HourBucket(hour: hour, label: label, count: starts, type: .start))
            }
            if let ends = endCounts[hour], ends > 0 {
                buckets.append(HourBucket(hour: hour, label: label, count: ends, type: .end))
            }
        }
        
        return buckets
    }
    
    private var peakStartHour: Int? {
        guard !completed.isEmpty else { return nil }
        let calendar = Calendar.current
        var counts = [Int: Int]()
        for s in completed {
            let h = calendar.component(.hour, from: s.startDate)
            counts[h, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }
    
    private var peakEndHour: Int? {
        let withEnd = completed.filter { $0.endDate != nil }
        guard !withEnd.isEmpty else { return nil }
        let calendar = Calendar.current
        var counts = [Int: Int]()
        for s in withEnd {
            if let end = s.endDate {
                let h = calendar.component(.hour, from: end)
                counts[h, default: 0] += 1
            }
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }
    
    /// Day-of-week data: count + average duration per weekday
    private var dayOfWeekData: [DayOfWeekData] {
        let calendar = Calendar.current
        var counts = [Int: Int]()
        var durations = [Int: TimeInterval]()
        
        for session in completed {
            let weekday = calendar.component(.weekday, from: session.startDate) // 1=Sun
            counts[weekday, default: 0] += 1
            durations[weekday, default: 0] += session.actualDuration
        }
        
        let maxCount = counts.values.max() ?? 1
        
        return (1...7).map { weekday in
            let date = calendar.date(bySetting: .weekday, value: weekday, of: Date.now) ?? Date.now
            let name = date.formatted(.dateTime.weekday(.abbreviated))
            let count = counts[weekday] ?? 0
            let avgDuration = count > 0 ? (durations[weekday] ?? 0) / Double(count) : 0
            return DayOfWeekData(
                weekday: weekday,
                name: name,
                count: count,
                avgDuration: avgDuration,
                maxCount: maxCount
            )
        }
    }
    
    /// Best time to start recommendation
    private var bestTimeRecommendation: (hour: Int, reason: String)? {
        guard completed.count >= 3 else { return nil }
        let calendar = Calendar.current
        
        // Find the start hour that leads to the highest completion rate and longest average duration
        var hourStats = [Int: (completedCount: Int, totalDuration: TimeInterval)]()
        
        for session in completed {
            let h = calendar.component(.hour, from: session.startDate)
            var stat = hourStats[h] ?? (0, 0)
            stat.completedCount += 1
            stat.totalDuration += session.actualDuration
            hourStats[h] = stat
        }
        
        // Score: fasts started at this hour × average duration
        let scored = hourStats.map { (hour, stat) -> (Int, Double) in
            let avgDuration = stat.totalDuration / Double(stat.completedCount)
            let score = Double(stat.completedCount) * avgDuration
            return (hour, score)
        }
        
        guard let best = scored.max(by: { $0.1 < $1.1 }),
              let stat = hourStats[best.0] else { return nil }
        let avgH = Int(stat.totalDuration / Double(stat.completedCount)) / 3600
        
        return (best.0, "\(stat.completedCount) successful fasts, avg \(avgH)h each")
    }
    
    // MARK: - Heatmap data (hour x weekday)
    
    private var heatmapData: [HeatmapCell] {
        let calendar = Calendar.current
        var counts = [String: Int]()
        var maxCount = 0
        
        for session in completed {
            let hour = calendar.component(.hour, from: session.startDate)
            let weekday = calendar.component(.weekday, from: session.startDate)
            let key = "\(weekday)-\(hour)"
            counts[key, default: 0] += 1
            maxCount = max(maxCount, counts[key, default: 0])
        }
        
        var cells: [HeatmapCell] = []
        for weekday in 1...7 {
            let date = calendar.date(bySetting: .weekday, value: weekday, of: Date.now) ?? Date.now
            let dayName = date.formatted(.dateTime.weekday(.abbreviated))
            // Show 4 time blocks: morning (6-11), afternoon (12-17), evening (18-23), night (0-5)
            let blocks: [(String, ClosedRange<Int>)] = [
                ("Night", 0...5),
                ("Morning", 6...11),
                ("Afternoon", 12...17),
                ("Evening", 18...23)
            ]
            
            for (blockName, range) in blocks {
                let count = range.reduce(0) { $0 + (counts["\(weekday)-\($1)"] ?? 0) }
                cells.append(HeatmapCell(
                    weekday: weekday,
                    dayName: dayName,
                    timeBlock: blockName,
                    count: count,
                    maxCount: max(maxCount, 1)
                ))
            }
        }
        
        return cells
    }
    
    // MARK: - Body
    
    var body: some View {
        let accent = themeManager.selectedTheme.accent
        
        VStack(spacing: 16) {
            // Peak times summary
            peakTimesRow(accent: accent)
            
            // Best time recommendation
            if let rec = bestTimeRecommendation {
                bestTimeCard(recommendation: rec, accent: accent)
            }
            
            // Day-of-week analysis
            if !dayOfWeekData.isEmpty && completed.count >= 3 {
                dayOfWeekSection(accent: accent)
            }
            
            // Heatmap
            if completed.count >= 5 {
                heatmapSection(accent: accent)
            }
            
            // Hour distribution chart
            if !hourData.isEmpty {
                hourChart
            }
        }
    }
    
    // MARK: - Peak Times Row
    
    private func peakTimesRow(accent: Color) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.indigo)
                Text(peakStartHour.map { formatHour($0) } ?? "--")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("Usual start")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .shadow(color: .indigo.opacity(0.1), radius: 4, y: 2)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Usual fasting start time")
            .accessibilityValue(peakStartHour.map { formatHour($0) } ?? "No data")
            
            Spacer()
                .frame(width: 12)
            
            VStack(spacing: 4) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.orange)
                Text(peakEndHour.map { formatHour($0) } ?? "--")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("Usual end")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .shadow(color: .orange.opacity(0.1), radius: 4, y: 2)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Usual fasting end time")
            .accessibilityValue(peakEndHour.map { formatHour($0) } ?? "No data")
        }
    }
    
    // MARK: - Best Time Card
    
    private func bestTimeCard(recommendation: (hour: Int, reason: String), accent: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 18))
                .foregroundStyle(accent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Best time to start: \(formatHour(recommendation.hour))")
                    .font(.system(.headline, design: .rounded))
                Text(recommendation.reason)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accent.opacity(0.06))
                )
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(accent.gradient)
                .frame(width: 3)
                .padding(.vertical, 6)
        }
        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Best time to start fasting: \(formatHour(recommendation.hour)). \(recommendation.reason)")
    }
    
    // MARK: - Day of Week Section
    
    private func dayOfWeekSection(accent: Color) -> some View {
        DayOfWeekBarChart(data: dayOfWeekData, accent: accent)
    }
    
    // MARK: - Heatmap Section
    
    private func heatmapSection(accent: Color) -> some View {
        let timeBlocks = ["Night", "Morning", "Afternoon", "Evening"]
        let dayNames = dayOfWeekData
        let cells = heatmapData
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Activity Heatmap")
                .font(.system(.headline, design: .rounded))
            
            HeatmapGrid(
                timeBlocks: timeBlocks,
                dayNames: dayNames.map { String($0.name.prefix(2)) },
                cells: cells,
                accent: accent
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Activity heatmap showing fasting frequency by day and time of day")
    }
    
    // MARK: - Hour Distribution Chart
    
    private var hourChart: some View {
        Chart(hourData) { bucket in
            BarMark(
                x: .value("Hour", bucket.label),
                y: .value("Count", bucket.count)
            )
            .foregroundStyle(by: .value("Type", bucket.type.rawValue))
            .cornerRadius(3)
        }
        .chartForegroundStyleScale([
            "Start": Color.indigo,
            "End": Color.orange
        ])
        .chartLegend(position: .bottom, spacing: 8) {
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(.indigo).frame(width: 8, height: 8)
                    Text("Start").font(.system(size: 11)).foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    Circle().fill(.orange).frame(width: 8, height: 8)
                    Text("End").font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    .foregroundStyle(Color(.systemGray4))
                AxisValueLabel()
                    .font(.system(size: 10))
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.system(size: 9))
            }
        }
        .frame(height: 140)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Time of day distribution chart")
        .accessibilityValue("Shows when you typically start and end fasts. Most common start: \(peakStartHour.map { formatHour($0) } ?? "unknown"), most common end: \(peakEndHour.map { formatHour($0) } ?? "unknown")")
    }
    
    // MARK: - Helpers
    
    private func formatHour(_ hour: Int) -> String {
        let h = hour % 24
        if h == 0 { return "12AM" }
        if h < 12 { return "\(h)AM" }
        if h == 12 { return "12PM" }
        return "\(h - 12)PM"
    }
}

// MARK: - Day of Week Bar Chart (Extracted for type-checker)

private struct DayOfWeekBarChart: View {
    let data: [DayOfWeekData]
    let accent: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("By Day of Week")
                .font(.system(.headline, design: .rounded))
            
            HStack(spacing: 4) {
                ForEach(data) { day in
                    DayOfWeekBar(day: day, accent: accent)
                }
            }
            .frame(height: 70)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Fasts by day of week: " + data.map { "\($0.name) \($0.count)" }.joined(separator: ", "))
    }
}

private struct DayOfWeekBar: View {
    let day: DayOfWeekData
    let accent: Color
    
    var body: some View {
        let barFill: Color = day.count > 0 ? accent.opacity(0.15 + day.intensityFraction * 0.65) : Color(.systemGray5)
        let barHeight: CGFloat = max(6, CGFloat(day.intensityFraction) * 40 + 6)
        
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(barFill)
                .frame(height: barHeight)
            
            Text(String(day.name.prefix(2)))
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(day.count > 0 ? .primary : .tertiary)
            
            Text("\(day.count)")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(day.count > 0 ? accent : Color(.tertiaryLabel))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Data Models

private struct HourBucket: Identifiable {
    let hour: Int
    let label: String
    let count: Int
    let type: BucketType
    
    var id: String { "\(hour)-\(type.rawValue)" }
    
    enum BucketType: String {
        case start = "Start"
        case end = "End"
    }
}

private struct DayOfWeekData: Identifiable {
    let weekday: Int
    let name: String
    let count: Int
    let avgDuration: TimeInterval
    let maxCount: Int
    
    var id: Int { weekday }
    
    var intensityFraction: Double {
        guard maxCount > 0, count > 0 else { return 0 }
        return Double(count) / Double(maxCount)
    }
}

private struct HeatmapCell: Identifiable {
    let weekday: Int
    let dayName: String
    let timeBlock: String
    let count: Int
    let maxCount: Int
    
    var id: String { "\(weekday)-\(timeBlock)" }
    
    var intensityFraction: Double {
        guard maxCount > 0, count > 0 else { return 0 }
        return Double(count) / Double(maxCount)
    }
}

// MARK: - Heatmap Grid (Extracted for type-checker)

private struct HeatmapGrid: View {
    let timeBlocks: [String]
    let dayNames: [String]
    let cells: [HeatmapCell]
    let accent: Color
    
    private let heatColumns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)
    
    var body: some View {
        VStack(spacing: 3) {
            LazyVGrid(columns: heatColumns, spacing: 3) {
                ForEach(dayNames, id: \.self) { name in
                    Text(name)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
            
            ForEach(timeBlocks, id: \.self) { block in
                HeatmapRow(block: block, cells: cells, accent: accent)
            }
        }
    }
}

private struct HeatmapRow: View {
    let block: String
    let cells: [HeatmapCell]
    let accent: Color
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...7, id: \.self) { weekday in
                HeatmapCellView(
                    cell: cells.first { $0.weekday == weekday && $0.timeBlock == block },
                    accent: accent
                )
            }
            
            Text(String(block.prefix(3)))
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)
                .frame(width: 26, alignment: .leading)
        }
    }
}

private struct HeatmapCellView: View {
    let cell: HeatmapCell?
    let accent: Color
    
    var body: some View {
        let count = cell?.count ?? 0
        let intensity = cell?.intensityFraction ?? 0
        
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(count > 0 ? accent.opacity(0.12 + intensity * 0.68) : Color(.systemGray6))
            .frame(height: 18)
            .overlay {
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundStyle(intensity > 0.5 ? .white : .secondary)
                }
            }
    }
}
