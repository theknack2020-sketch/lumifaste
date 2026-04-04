import SwiftUI

/// Monthly calendar grid — each day colored by fasting duration intensity.
/// Enhanced: color intensity by duration, tap for details, streak fire emoji indicators.
struct MonthlyCalendarView: View {
    let sessions: [FastingSession]
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selectedDay: CalendarDay?

    private var isRegular: Bool {
        sizeClass == .regular
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    private var calendarData: [CalendarDay] {
        let calendar = Calendar.current
        let now = Date.now
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth)
        else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let offset = (firstWeekday - calendar.firstWeekday + 7) % 7
        let today = calendar.component(.day, from: now)

        // Build per-day duration map and session details
        let monthSessions = sessions.filter {
            $0.isCompleted && calendar.isDate($0.startDate, equalTo: now, toGranularity: .month)
        }

        var dayDurations = [Int: TimeInterval]()
        var daySessionDetails = [Int: [FastingSession]]()
        var maxDuration: TimeInterval = 0

        for session in monthSessions {
            let day = calendar.component(.day, from: session.startDate)
            dayDurations[day, default: 0] += session.actualDuration
            daySessionDetails[day, default: []].append(session)
            maxDuration = max(maxDuration, dayDurations[day] ?? 0)
        }

        // Compute streaks for fire emoji
        let completedDayNumbers = Set(dayDurations.keys).sorted()
        var streakDays = Set<Int>()

        var currentRun: [Int] = []
        for day in completedDayNumbers {
            if currentRun.isEmpty || day == (currentRun.last ?? 0) + 1 {
                currentRun.append(day)
            } else {
                if currentRun.count >= 3 {
                    streakDays.formUnion(currentRun)
                }
                currentRun = [day]
            }
        }
        if currentRun.count >= 3 {
            streakDays.formUnion(currentRun)
        }

        var days: [CalendarDay] = []

        // Empty padding at start
        for i in 0 ..< offset {
            days.append(CalendarDay(id: -i - 1, dayNumber: 0, state: .empty, duration: 0, maxDuration: maxDuration, sessions: [], isStreakDay: false))
        }

        // Actual days
        for day in range {
            let duration = dayDurations[day] ?? 0
            let detail = daySessionDetails[day] ?? []
            let isStreak = streakDays.contains(day)

            let state: CalendarDayState = if day > today {
                .future
            } else if duration > 0 {
                .completed
            } else {
                .missed
            }
            days.append(CalendarDay(id: day, dayNumber: day, state: state, duration: duration, maxDuration: maxDuration, sessions: detail, isStreakDay: isStreak))
        }

        return days
    }

    var body: some View {
        let data = calendarData
        let hasAnyFasts = data.contains { $0.state == .completed }
        let completedCount = data.count(where: { $0.state == .completed })
        let missedCount = data.count(where: { $0.state == .missed })

        VStack(spacing: 6) {
            // Month header
            Text(Date.now.formatted(.dateTime.month(.wide).year()))
                .font(.adaptiveDetail(isRegular: isRegular).weight(.medium))
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)

            // Weekday headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(String(symbol.prefix(2)))
                        .font(.adaptiveCaption(isRegular: isRegular).weight(.medium))
                        .foregroundStyle(.tertiary)
                        .frame(height: 20)
                        .accessibilityHidden(true)
                }
            }

            // Day grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(data) { day in
                    calendarCell(day: day)
                        .onTapGesture {
                            guard day.state == .completed else { return }
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if selectedDay?.id == day.id {
                                    selectedDay = nil
                                } else {
                                    selectedDay = day
                                }
                            }
                            HapticManager.shared.lightTap()
                        }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Monthly fasting calendar")
            .accessibilityValue(calendarAccessibilitySummary(completedCount: completedCount, missedCount: missedCount))

            // Tap detail card
            if let day = selectedDay, !day.sessions.isEmpty {
                dayDetailCard(day: day)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            }

            // Legend & messages
            if !hasAnyFasts {
                VStack(spacing: 6) {
                    Text("No fasts this month yet")
                        .font(.adaptiveCaption(isRegular: isRegular).weight(.medium))
                        .foregroundStyle(.secondary)
                    Text("Start fasting to fill your calendar 💪")
                        .font(.adaptiveBadge(isRegular: isRegular))
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, 8)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("No fasts this month yet. Start fasting to fill your calendar.")
            } else {
                // Intensity legend
                HStack(spacing: 8) {
                    Text("Less")
                        .font(.adaptiveCaption(isRegular: isRegular))
                        .foregroundStyle(.tertiary)

                    HStack(spacing: 3) {
                        ForEach([0.15, 0.35, 0.55, 0.75, 1.0], id: \.self) { intensity in
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(Color.green.opacity(intensity))
                                .frame(width: 12, height: 12)
                        }
                    }

                    Text("More")
                        .font(.adaptiveCaption(isRegular: isRegular))
                        .foregroundStyle(.tertiary)

                    Spacer()

                    HStack(spacing: 2) {
                        Text("🔥")
                            .font(.adaptiveCaption(isRegular: isRegular))
                        Text("3+ day streak")
                            .font(.adaptiveCaption(isRegular: isRegular))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.top, 6)
                .accessibilityHidden(true)
            }
        }
    }

    private func calendarAccessibilitySummary(completedCount: Int, missedCount: Int) -> String {
        if completedCount == 0 {
            return "No fasts completed this month"
        }
        return "\(completedCount) days fasted, \(missedCount) days missed this month"
    }

    @ViewBuilder
    private func calendarCell(day: CalendarDay) -> some View {
        if day.state == .empty {
            Color.clear
                .frame(height: 34)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(cellColor(for: day))
                    .frame(height: 34)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(selectedDay?.id == day.id ? themeManager.selectedTheme.accent : .clear, lineWidth: 2)
                    )

                VStack(spacing: 0) {
                    if day.dayNumber > 0 {
                        Text("\(day.dayNumber)")
                            .font(.adaptiveBadge(isRegular: isRegular).weight(day.state == .completed ? .semibold : .regular))
                            .foregroundStyle(dayTextColor(for: day))
                    }

                    if day.isStreakDay, day.state == .completed {
                        Text("🔥")
                            .font(.adaptiveCaption2(isRegular: isRegular))
                            .offset(y: -1)
                    }
                }
            }
        }
    }

    private func cellColor(for day: CalendarDay) -> Color {
        switch day.state {
        case .completed:
            let intensity = day.intensityFraction
            return Color.green.opacity(0.15 + intensity * 0.65)
        case .missed:
            return Color(.systemGray5)
        case .future:
            return Color(.systemGray6).opacity(0.5)
        case .empty:
            return .clear
        }
    }

    private func dayTextColor(for day: CalendarDay) -> Color {
        switch day.state {
        case .completed:
            let intensity = day.intensityFraction
            return intensity > 0.6 ? .white : .primary
        case .future:
            return Color(.tertiaryLabel)
        case .missed:
            return Color(.secondaryLabel)
        case .empty:
            return .clear
        }
    }

    private func dayDetailCard(day: CalendarDay) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Day \(day.dayNumber)")
                    .font(.adaptiveDetail(isRegular: isRegular).weight(.semibold))

                Spacer()

                Button {
                    withAnimation { selectedDay = nil }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.adaptiveDetail(isRegular: isRegular))
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Dismiss detail")
            }

            ForEach(day.sessions, id: \.id) { session in
                HStack(spacing: 8) {
                    Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.adaptiveCaption(isRegular: isRegular))
                        .foregroundStyle(session.isCompleted ? .green : .orange)

                    Text(session.plan.displayName)
                        .font(.adaptiveCaption(isRegular: isRegular).weight(.medium))

                    Spacer()

                    Text(formatDuration(session.actualDuration))
                        .font(.adaptiveCaption(isRegular: isRegular).weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        if h > 0, m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}

// MARK: - Data Models

private struct CalendarDay: Identifiable {
    let id: Int
    let dayNumber: Int
    let state: CalendarDayState
    let duration: TimeInterval
    let maxDuration: TimeInterval
    let sessions: [FastingSession]
    let isStreakDay: Bool

    /// 0…1 fraction representing how intense this day is relative to the max
    var intensityFraction: Double {
        guard maxDuration > 0, duration > 0 else { return 0 }
        return min(duration / maxDuration, 1.0)
    }
}

private enum CalendarDayState {
    case completed, missed, future, empty
}
