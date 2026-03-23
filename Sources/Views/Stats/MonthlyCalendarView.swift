import SwiftUI

/// Monthly calendar grid — each day colored by fasting completion.
/// Green = completed fast that day, gray = no fast, empty = future.
struct MonthlyCalendarView: View {
    let sessions: [FastingSession]
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols
    
    private var calendarData: [CalendarDay] {
        let calendar = Calendar.current
        let now = Date.now
        let components = calendar.dateComponents([.year, .month], from: now)
        let startOfMonth = calendar.date(from: components)!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        
        // Which weekday does the month start on (1 = Sunday in en)
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        // Adjust for Calendar.firstWeekday
        let offset = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        // Completed fast days this month
        let completedDays = Set(
            sessions
                .filter { $0.isCompleted && calendar.isDate($0.startDate, equalTo: now, toGranularity: .month) }
                .map { calendar.component(.day, from: $0.startDate) }
        )
        
        let today = calendar.component(.day, from: now)
        
        var days: [CalendarDay] = []
        
        // Empty padding at start
        for i in 0..<offset {
            days.append(CalendarDay(id: -i - 1, dayNumber: 0, state: .empty))
        }
        
        // Actual days
        for day in range {
            let state: CalendarDayState
            if day > today {
                state = .future
            } else if completedDays.contains(day) {
                state = .completed
            } else {
                state = .missed
            }
            days.append(CalendarDay(id: day, dayNumber: day, state: state))
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Month header
            Text(Date.now.formatted(.dateTime.month(.wide).year()))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            
            // Weekday headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(String(symbol.prefix(2)))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .frame(height: 20)
                }
            }
            
            // Day grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(calendarData) { day in
                    calendarCell(day: day)
                }
            }
            
            // Legend
            HStack(spacing: 16) {
                legendItem(color: .green, label: "Fasted")
                legendItem(color: Color(.systemGray5), label: "No fast")
            }
            .padding(.top, 6)
        }
    }
    
    @ViewBuilder
    private func calendarCell(day: CalendarDay) -> some View {
        if day.state == .empty {
            Color.clear
                .frame(height: 30)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(cellColor(for: day.state))
                    .frame(height: 30)
                
                if day.dayNumber > 0 {
                    Text("\(day.dayNumber)")
                        .font(.system(size: 11, weight: day.state == .completed ? .semibold : .regular))
                        .foregroundStyle(dayTextColor(for: day.state))
                }
            }
        }
    }
    
    private func cellColor(for state: CalendarDayState) -> Color {
        switch state {
        case .completed: .green
        case .missed: Color(.systemGray5)
        case .future: Color(.systemGray6).opacity(0.5)
        case .empty: .clear
        }
    }
    
    private func dayTextColor(for state: CalendarDayState) -> Color {
        switch state {
        case .completed: .white
        case .future: Color(.tertiaryLabel)
        case .missed: Color(.secondaryLabel)
        case .empty: .clear
        }
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Data Models

private struct CalendarDay: Identifiable {
    let id: Int
    let dayNumber: Int
    let state: CalendarDayState
}

private enum CalendarDayState {
    case completed, missed, future, empty
}
