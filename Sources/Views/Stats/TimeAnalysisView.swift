import SwiftUI
import Charts

/// Time-of-day analysis — when users typically start and end fasts.
/// Shows distribution of start/end hours as a bar chart.
struct TimeAnalysisView: View {
    let sessions: [FastingSession]
    
    private var hourData: [HourBucket] {
        let completed = sessions.filter(\.isCompleted)
        guard !completed.isEmpty else { return [] }
        
        let calendar = Calendar.current
        
        // Count start hours
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
    
    private var peakStartHour: String {
        let completed = sessions.filter(\.isCompleted)
        guard !completed.isEmpty else { return "--" }
        let calendar = Calendar.current
        var counts = [Int: Int]()
        for s in completed {
            let h = calendar.component(.hour, from: s.startDate)
            counts[h, default: 0] += 1
        }
        let peak = counts.max(by: { $0.value < $1.value })?.key ?? 0
        return formatHour(peak)
    }
    
    private var peakEndHour: String {
        let completed = sessions.filter { $0.isCompleted && $0.endDate != nil }
        guard !completed.isEmpty else { return "--" }
        let calendar = Calendar.current
        var counts = [Int: Int]()
        for s in completed {
            if let end = s.endDate {
                let h = calendar.component(.hour, from: end)
                counts[h, default: 0] += 1
            }
        }
        let peak = counts.max(by: { $0.value < $1.value })?.key ?? 0
        return formatHour(peak)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Peak times summary
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.indigo)
                    Text(peakStartHour)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("Usual start")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                
                VStack(spacing: 4) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.orange)
                    Text(peakEndHour)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("Usual end")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Chart
            if !hourData.isEmpty {
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
            }
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let h = hour % 24
        if h == 0 { return "12AM" }
        if h < 12 { return "\(h)AM" }
        if h == 12 { return "12PM" }
        return "\(h - 12)PM"
    }
}

// MARK: - Data Model

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
