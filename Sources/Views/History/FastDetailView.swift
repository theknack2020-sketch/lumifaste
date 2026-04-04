import SwiftUI

/// Full breakdown of a completed fast — tapped from history row.
/// Shows timeline, stages reached, duration breakdown, mood, notes, water intake.
/// Visual polish: glassmorphism cards, layered shadows, accent bars, monospacedDigit — matches Timer.
struct FastDetailView: View {
    let session: FastingSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    @State private var showShareSheet = false

    private var stages: [FastingStage] {
        FastingStage.allCases.filter { $0.startHour * 3600 < session.actualDuration }
    }

    private var completionPercent: Double {
        guard session.plan.fastingDuration > 0 else { return 0 }
        return min(session.actualDuration / session.plan.fastingDuration, 1.0)
    }

    private var statusColor: Color {
        session.isCompleted ? .green : .orange
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
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
                    HapticManager.shared.lightTap()
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.pressable)
                .accessibilityIdentifier("shareButton")
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
                    .shadow(color: statusColor.opacity(0.25), radius: 10, x: 0, y: 4)

                Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.adaptiveDisplay(size: 32, weight: .regular, design: .default, isRegular: isRegular))
                    .foregroundStyle(statusColor)
            }

            Text(session.isCompleted ? "Completed" : "Ended Early")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(statusColor)

            Text(session.plan.rawValue)
                .font(.system(.title2, design: .rounded, weight: .bold))

            // Duration
            Text(formatDuration(session.actualDuration))
                .font(.system(.largeTitle, design: .rounded, weight: .light))
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .shadow(color: statusColor.opacity(0.1), radius: 12, x: 0, y: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.isCompleted ? "Completed" : "Ended early") \(session.plan.rawValue) fast, duration \(formatDuration(session.actualDuration))")
    }

    // MARK: - Duration Card

    private var durationCard: some View {
        HStack(spacing: 0) {
            // Accent left bar
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(session.stage.color)
                .frame(width: 3)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 12) {
                Label("Duration", systemImage: "clock.fill")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
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
                            .shadow(color: session.stage.color.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
                .frame(height: 12)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Start")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(session.startDate.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                            .font(.system(.footnote))
                            .monospacedDigit()
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("End")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text((session.endDate ?? session.startDate.addingTimeInterval(session.actualDuration)).formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                            .font(.system(.footnote))
                            .monospacedDigit()
                    }
                }

                if session.totalPausedDuration > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(.caption))
                            .foregroundStyle(.orange)
                        Text("Paused: \(formatDuration(session.totalPausedDuration))")
                            .font(.system(.caption))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Stages Card

    private var stagesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Stages Reached", systemImage: "flame.fill")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)

            ForEach(FastingStage.allCases) { stage in
                let reached = stage.startHour * 3600 < session.actualDuration

                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(reached ? stage.color.opacity(0.15) : Color(.tertiarySystemFill))
                            .frame(width: 36, height: 36)
                            .shadow(color: reached ? stage.color.opacity(0.2) : .clear, radius: 4, x: 0, y: 2)

                        Image(systemName: stage.icon)
                            .font(.system(.caption, weight: .medium))
                            .foregroundStyle(reached ? stage.color : Color(.tertiaryLabel))
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(stage.rawValue)
                            .font(.system(.subheadline, design: .rounded, weight: reached ? .semibold : .regular))
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
                            .monospacedDigit()
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
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
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(.body))
                    .foregroundStyle(color)
            }

            Text(value)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                .shadow(color: color.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Note Card

    private func noteCard(_ note: String) -> some View {
        HStack(spacing: 0) {
            // Accent left bar
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.yellow)
                .frame(width: 3)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 8) {
                Label("Note", systemImage: "note.text")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(note)
                    .font(.system(.body))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Note")
        .accessibilityValue(note)
    }

    // MARK: - Helpers

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

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
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
