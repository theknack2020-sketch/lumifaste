import SwiftUI

/// Full breakdown of a completed fast — tapped from history row.
/// Shows timeline, stages reached, duration breakdown, mood, notes, water intake.
struct FastDetailView: View {
    let session: FastingSession
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    
    private var stages: [FastingStage] {
        FastingStage.allCases.filter { $0.startHour * 3600 < session.actualDuration }
    }
    
    private var completionPercent: Double {
        guard session.plan.fastingDuration > 0 else { return 0 }
        return min(session.actualDuration / session.plan.fastingDuration, 1.0)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Header
                headerCard
                    .entranceAnimation(delay: 0.05)
                
                // MARK: - Duration breakdown
                durationCard
                    .entranceAnimation(delay: 0.1)
                
                // MARK: - Stages reached
                stagesCard
                    .entranceAnimation(delay: 0.15)
                
                // MARK: - Details grid
                detailsGrid
                    .entranceAnimation(delay: 0.2)
                
                // MARK: - Notes
                if let note = session.note, !note.isEmpty {
                    noteCard(note)
                        .entranceAnimation(delay: 0.25)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Fast Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share fast details")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            let text = FastDetailExporter.singleFastText(session)
            HistoryShareSheet(items: [text])
        }
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        VStack(spacing: 12) {
            // Completion status icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 64, height: 64)
                
                Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(statusColor)
            }
            
            Text(session.isCompleted ? "Completed" : "Ended Early")
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(statusColor)
            
            Text(session.plan.rawValue)
                .font(.system(.title2, design: .rounded, weight: .bold))
            
            // Duration
            Text(formatDuration(session.actualDuration))
                .font(.system(.largeTitle, design: .rounded, weight: .light))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Duration Card
    
    private var durationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Duration", systemImage: "clock.fill")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(.secondary)
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [session.stage.color.opacity(0.7), session.stage.color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * completionPercent, height: 12)
                }
            }
            .frame(height: 12)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Start")
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(session.startDate.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                        .font(.system(.footnote))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("End")
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text((session.endDate ?? session.startDate.addingTimeInterval(session.actualDuration)).formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                        .font(.system(.footnote))
                }
            }
            
            if session.totalPausedDuration > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(.caption))
                        .foregroundStyle(.orange)
                    Text("Paused: \(formatDuration(session.totalPausedDuration))")
                        .font(.system(.caption))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Stages Card
    
    private var stagesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Stages Reached", systemImage: "flame.fill")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(.secondary)
            
            ForEach(FastingStage.allCases) { stage in
                let reached = stage.startHour * 3600 < session.actualDuration
                
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(reached ? stage.color.opacity(0.15) : Color(.tertiarySystemFill))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: stage.icon)
                            .font(.system(.caption, weight: .medium))
                            .foregroundStyle(reached ? stage.color : Color(.tertiaryLabel))
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(stage.rawValue)
                            .font(.system(.subheadline, weight: reached ? .semibold : .regular))
                            .foregroundStyle(reached ? .primary : .tertiary)
                        
                        Text(stage.subtitle)
                            .font(.system(.caption))
                            .foregroundStyle(reached ? .secondary : .quaternary)
                    }
                    
                    Spacer()
                    
                    if reached {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(.caption))
                            .foregroundStyle(.green)
                    } else {
                        Text("\(Int(stage.startHour))h")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Details Grid
    
    private var detailsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            detailCell(
                icon: "target",
                title: "Plan Target",
                value: "\(Int(session.plan.fastingHours))h",
                color: .blue
            )
            
            detailCell(
                icon: "chart.bar.fill",
                title: "Completion",
                value: "\(Int(completionPercent * 100))%",
                color: completionPercent >= 1.0 ? .green : .orange
            )
            
            if session.waterCount > 0 {
                detailCell(
                    icon: "drop.fill",
                    title: "Water",
                    value: "\(session.waterCount) glasses",
                    color: .cyan
                )
            }
            
            if let mood = session.mood {
                detailCell(
                    icon: "face.smiling",
                    title: "Mood",
                    value: mood,
                    color: .yellow
                )
            }
            
            detailCell(
                icon: session.stage.icon,
                title: "Best Stage",
                value: session.stage.rawValue,
                color: session.stage.color
            )
            
            detailCell(
                icon: "calendar",
                title: "Day",
                value: session.startDate.formatted(.dateTime.weekday(.wide)),
                color: .purple
            )
        }
    }
    
    private func detailCell(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(.body))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(title)
                .font(.system(.caption))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
    
    // MARK: - Note Card
    
    private func noteCard(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Note", systemImage: "note.text")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(.secondary)
            
            Text(note)
                .font(.system(.body))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Note")
        .accessibilityValue(note)
    }
    
    // MARK: - Helpers
    
    private var statusColor: Color {
        session.isCompleted ? .green : .orange
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

// MARK: - Share Sheet (UIKit bridge)

struct HistoryShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Single Fast Text Export

enum FastDetailExporter {
    static func singleFastText(_ session: FastingSession) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        let hours = Int(session.actualDuration) / 3600
        let minutes = (Int(session.actualDuration) % 3600) / 60
        let durationStr = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
        let completionPct = session.plan.fastingDuration > 0
            ? Int(min(session.actualDuration / session.plan.fastingDuration, 1.0) * 100)
            : 0
        
        var text = """
        🧬 Lumifaste — Fast Details
        ━━━━━━━━━━━━━━━━━━━━━━
        Plan: \(session.plan.rawValue)
        Status: \(session.isCompleted ? "✅ Completed" : "⚠️ Ended Early")
        Duration: \(durationStr) (\(completionPct)% of target)
        Stage Reached: \(session.stage.rawValue) \(session.stage.icon)
        Start: \(dateFormatter.string(from: session.startDate))
        End: \(session.endDate.map { dateFormatter.string(from: $0) } ?? "—")
        """
        
        if session.waterCount > 0 {
            text += "\nWater: \(session.waterCount) glasses 💧"
        }
        if let mood = session.mood {
            text += "\nMood: \(mood)"
        }
        if let note = session.note, !note.isEmpty {
            text += "\nNote: \(note)"
        }
        
        text += "\n━━━━━━━━━━━━━━━━━━━━━━"
        text += "\nTracked with Lumifaste"
        
        return text
    }
    
    static func fullHistoryText(_ sessions: [FastingSession]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        let completed = sessions.filter(\.isCompleted).count
        let total = sessions.count
        let totalDuration = sessions.reduce(0.0) { $0 + $1.actualDuration }
        let totalHours = Int(totalDuration) / 3600
        
        var text = """
        🧬 Lumifaste — Fasting History
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Total Fasts: \(total)
        Completed: \(completed)
        Total Hours Fasted: \(totalHours)h
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        """
        
        let sorted = sessions.sorted { $0.startDate > $1.startDate }
        for (i, session) in sorted.enumerated() {
            let hours = Int(session.actualDuration) / 3600
            let minutes = (Int(session.actualDuration) % 3600) / 60
            let dur = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
            let status = session.isCompleted ? "✅" : "⚠️"
            text += "\(i + 1). \(status) \(session.plan.rawValue) · \(dur) · \(session.stage.rawValue) · \(dateFormatter.string(from: session.startDate))\n"
        }
        
        text += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━\nTracked with Lumifaste"
        return text
    }
}

#Preview {
    NavigationStack {
        FastDetailView(session: {
            let s = FastingSession(
                startDate: Date.now.addingTimeInterval(-18 * 3600),
                targetEndDate: Date.now.addingTimeInterval(-2 * 3600),
                planType: .sixteenEight
            )
            s.complete()
            s.mood = "🔥"
            s.note = "Felt amazing — clear headed all day. Energy stayed consistent. Will try 18:6 next."
            s.waterCount = 8
            return s
        }())
    }
}
