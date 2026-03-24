import SwiftUI
import Charts

/// Weekly bar chart — shows fasting hours per day for the current week.
/// Uses Swift Charts framework with smooth styling.
struct WeeklyFastingChart: View {
    let sessions: [FastingSession]
    @State private var animateChart = false
    
    private var weekData: [DayData] {
        let calendar = Calendar.current
        let now = Date.now
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        let completed = sessions.filter(\.isCompleted)
        
        return (0..<7).compactMap { dayOffset -> DayData? in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else { return nil }
            let dayStart = calendar.startOfDay(for: date)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return nil }
            
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
                y: .value("Hours", animateChart ? item.hours : 0)
            )
            .foregroundStyle(
                item.isToday
                    ? Color.accentColor.gradient
                    : Color.blue.opacity(0.6).gradient
            )
            .cornerRadius(6)
            .annotation(position: .top) {
                if item.hours > 0 && animateChart {
                    Text(String(format: "%.1f", item.hours))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weekly fasting chart")
        .accessibilityValue(weeklyAccessibilitySummary)
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.15).delay(0.2)) {
                animateChart = true
            }
        }
    }
    
    /// Accessibility summary for VoiceOver — reads total hours and active days
    private var weeklyAccessibilitySummary: String {
        let totalHours = weekData.reduce(0.0) { $0 + $1.hours }
        let activeDays = weekData.filter { $0.hours > 0 }.count
        if totalHours == 0 {
            return "No fasting this week"
        }
        return String(format: "%.1f total hours fasted across %d day%@", totalHours, activeDays, activeDays == 1 ? "" : "s")
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
