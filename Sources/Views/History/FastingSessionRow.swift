import SwiftUI

/// Enhanced fasting session row — glassmorphism card, accent left bar,
/// layered shadows, monospacedDigit numbers — matches Timer visual polish.
struct FastingSessionRow: View {
    let session: FastingSession
    
    private var completionPercent: Double {
        guard session.plan.fastingDuration > 0 else { return 0 }
        return min(session.actualDuration / session.plan.fastingDuration, 1.0)
    }
    
    /// Accent color: green for completed, orange for ended early
    private var accentColor: Color {
        session.isCompleted ? .green : .orange
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Accent left bar — completion status indicator
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(accentColor)
                .frame(width: 3)
                .padding(.vertical, 6)
            
            HStack(spacing: 14) {
                // Status icon with color coding
                statusIcon
                
                // Info column
                VStack(alignment: .leading, spacing: 5) {
                    // Top row: plan + stage badge + mood
                    HStack(spacing: 6) {
                        Text(session.plan.rawValue)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        
                        Text(session.stage.rawValue)
                            .font(.system(.caption2, weight: .medium))
                            .foregroundStyle(session.stage.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(session.stage.color.opacity(0.12))
                            .clipShape(Capsule())
                        
                        if let mood = session.mood {
                            Text(mood)
                                .font(.system(size: 14))
                        }
                    }
                    
                    // Duration progress bar
                    durationBar
                    
                    // Date row with water
                    HStack(spacing: 8) {
                        Text(formatSessionDate(session.startDate))
                            .font(.system(.footnote))
                            .foregroundStyle(.secondary)
                        
                        if session.waterCount > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.cyan)
                                Text("\(session.waterCount)")
                                    .font(.system(size: 11, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(.cyan)
                            }
                        }
                        
                        if spannedMidnight {
                            Text("overnight")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    // Note preview
                    if let note = session.note, !note.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "note.text")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                            Text(note)
                                .font(.system(.caption))
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                // Duration + completion indicator
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatDuration(session.actualDuration))
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .monospacedDigit()
                    
                    Text("\(Int(completionPercent * 100))%")
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(accentColor)
                }
            }
            .padding(.leading, 10)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }
    
    // MARK: - Status Icon
    
    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(accentColor.opacity(0.15))
                .frame(width: 40, height: 40)
                .shadow(color: accentColor.opacity(0.15), radius: 4, x: 0, y: 2)
            
            Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "xmark.circle")
                .font(.system(.body, weight: .medium))
                .foregroundStyle(accentColor)
        }
        .accessibilityHidden(true)
    }
    
    // MARK: - Duration Bar
    
    private var durationBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: 5)
                
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: stageGradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(4, geo.size.width * completionPercent), height: 5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: completionPercent)
            }
        }
        .frame(height: 5)
    }
    
    /// Gradient colors based on stages reached
    private var stageGradientColors: [Color] {
        let reached = FastingStage.allCases.filter { $0.startHour * 3600 < session.actualDuration }
        if reached.isEmpty { return [.gray] }
        if reached.count == 1 { return [reached[0].color] }
        guard let first = reached.first, let last = reached.last else { return [.gray] }
        return [first.color, last.color]
    }
    
    // MARK: - Helpers
    
    private var spannedMidnight: Bool {
        guard let endDate = session.endDate else { return false }
        let cal = Calendar.current
        return !cal.isDate(session.startDate, inSameDayAs: endDate)
    }
    
    private func formatSessionDate(_ date: Date) -> String {
        if spannedMidnight, let endDate = session.endDate {
            let startStr = date.formatted(.dateTime.month(.abbreviated).day().hour().minute())
            let endDay = endDate.formatted(.dateTime.month(.abbreviated).day())
            return "\(startStr) → \(endDay)"
        }
        return date.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }
    
    private var accessibilityText: String {
        var text = "\(session.plan.rawValue) fast, \(formatDuration(session.actualDuration)), \(session.stage.rawValue) stage, \(session.isCompleted ? "completed" : "ended early"), \(session.startDate.formatted(.dateTime.month(.abbreviated).day()))"
        if let mood = session.mood {
            text += ", mood: \(mood)"
        }
        if session.waterCount > 0 {
            text += ", \(session.waterCount) glasses of water"
        }
        if let note = session.note, !note.isEmpty {
            text += ", note: \(note)"
        }
        return text
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

#Preview {
    List {
        FastingSessionRow(session: {
            let s = FastingSession(
                startDate: Date.now.addingTimeInterval(-16 * 3600),
                targetEndDate: Date.now,
                planType: .sixteenEight
            )
            s.complete()
            s.mood = "🔥"
            s.note = "Felt great, easy morning"
            s.waterCount = 6
            return s
        }())
        .listRowBackground(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .padding(.vertical, 2)
                .padding(.horizontal, 4)
        )
        
        FastingSessionRow(session: {
            let s = FastingSession(
                startDate: Date.now.addingTimeInterval(-10 * 3600),
                targetEndDate: Date.now.addingTimeInterval(-2 * 3600),
                planType: .eighteenSix
            )
            s.endDate = Date.now.addingTimeInterval(-2 * 3600)
            s.actualDuration = 10 * 3600
            s.stageReached = FastingStage.stage(for: 10 * 3600).rawValue
            return s
        }())
        .listRowBackground(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .padding(.vertical, 2)
                .padding(.horizontal, 4)
        )
        
        FastingSessionRow(session: {
            let s = FastingSession(
                startDate: Date.now.addingTimeInterval(-20 * 3600),
                targetEndDate: Date.now.addingTimeInterval(-2 * 3600),
                planType: .eighteenSix
            )
            s.complete()
            return s
        }())
        .listRowBackground(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .padding(.vertical, 2)
                .padding(.horizontal, 4)
        )
    }
}
