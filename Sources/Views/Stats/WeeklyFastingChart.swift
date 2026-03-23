import SwiftUI
import Charts

/// Weekly bar chart — shows fasting hours per day for the current week.
/// Uses Swift Charts framework with smooth styling.
struct WeeklyFastingChart: View {
    let sessions: [FastingSession]
    
    private var weekData: [DayData] {
        let calendar = Calendar.current
        let now = Date.now
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        let completed = sessions.filter(\.isCompleted)
        
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let hoursForDay = completed
                .filter { $0.startDate >= dayStart && $0.startDate < dayEnd }
                .reduce(0.0) { $0 + $1.actualDuration / 3600 }
            
            let dayName = date.formatted(.dateTime.weekday(.abbreviated))
            let isToday = calendar.isDateInToday(date)
            
            return DayData(day: dayName, hours: hoursForDay, isToday: isToday, date: date)
        }
    }
    
    var body: some View {
        Chart(weekData) { item in
            BarMark(
                x: .value("Day", item.day),
                y: .value("Hours", item.hours)
            )
            .foregroundStyle(
                item.isToday
                    ? Color.accentColor.gradient
                    : Color.blue.opacity(0.6).gradient
            )
            .cornerRadius(6)
            .annotation(position: .top) {
                if item.hours > 0 {
                    Text(String(format: "%.1f", item.hours))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .chartYAxisLabel("hours")
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    .foregroundStyle(Color(.systemGray4))
                AxisValueLabel()
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .font(.system(size: 11, weight: .medium))
            }
        }
    }
}

// MARK: - Data Model

private struct DayData: Identifiable {
    let day: String
    let hours: Double
    let isToday: Bool
    let date: Date
    var id: String { day }
}
