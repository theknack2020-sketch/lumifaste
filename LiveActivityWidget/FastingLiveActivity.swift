import ActivityKit
import SwiftUI
import WidgetKit

/// Live Activity UI for the fasting timer — Lock Screen, Dynamic Island compact & expanded.
///
/// Elapsed time, remaining time, and progress **self-tick** from the immutable
/// `attributes.startDate` via `Text(timerInterval:)` / `ProgressView(timerInterval:)`.
/// The card stays live with no push updates and never freezes after an app kill —
/// the previous design rendered a static `elapsedSeconds` number that only moved
/// when the app pushed an update (TheKnackKit SessionClock self-tick pattern).
/// `ContentState` still carries the stage label/emoji/plan, which legitimately
/// change and are refreshed by the app.
struct FastingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FastingActivityAttributes.self) { context in
            // MARK: - Lock Screen / StandBy Banner

            lockScreenView(context: context)
        } dynamicIsland: { context in
            let start = context.attributes.startDate
            let end = endDate(context: context)
            return DynamicIsland {
                // MARK: - Expanded Regions

                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: stageIcon(context.state.currentStage))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(stageColor(context.state.currentStage))
                        Text(context.state.stageEmoji)
                            .font(.system(size: 16))
                    }
                    .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(timerInterval: start ... .distantFuture, countsDown: false)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 70, alignment: .trailing)
                            .foregroundStyle(.primary)
                        if context.state.targetSeconds > 0 {
                            Text("of \(formatHHMM(context.state.targetSeconds))")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(context.state.currentStage)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(stageColor(context.state.currentStage))

                        if let end {
                            ProgressView(timerInterval: start ... end, countsDown: false)
                                .tint(stageColor(context.state.currentStage))
                                .labelsHidden()
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.planName)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "flame.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(stageColor(context.state.currentStage))
            } compactTrailing: {
                Text(timerInterval: context.attributes.startDate ... .distantFuture, countsDown: false)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .frame(maxWidth: 44)
                    .foregroundStyle(stageColor(context.state.currentStage))
            } minimal: {
                Image(systemName: "flame.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(stageColor(context.state.currentStage))
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<FastingActivityAttributes>) -> some View {
        let start = context.attributes.startDate
        let end = endDate(context: context)
        let color = stageColor(context.state.currentStage)

        HStack(spacing: 14) {
            // Stage glyph
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                Text(context.state.stageEmoji)
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(context.state.currentStage)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                    Spacer()
                    Text(context.state.planName)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                // Elapsed time — primary, self-ticking
                Text(timerInterval: start ... .distantFuture, countsDown: false)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                if let end {
                    // Self-ticking progress + remaining countdown
                    ProgressView(timerInterval: start ... end, countsDown: false)
                        .tint(color)
                        .labelsHidden()
                    HStack(spacing: 4) {
                        Text(timerInterval: start ... end, countsDown: true)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        Text("remaining")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.01)) // Ensure tap target
    }

    // MARK: - Helpers

    /// The fast's target end, or `nil` for an open-ended fast (no target).
    private func endDate(context: ActivityViewContext<FastingActivityAttributes>) -> Date? {
        guard context.state.targetSeconds > 0 else { return nil }
        return context.attributes.startDate.addingTimeInterval(Double(context.state.targetSeconds))
    }

    private func stageColor(_ stage: String) -> Color {
        switch stage {
        case "Fed": .gray
        case "Early Fasting": .yellow
        case "Fat Burning": .orange
        case "Ketosis": .blue
        case "Autophagy": .purple
        default: .green
        }
    }

    private func stageIcon(_ stage: String) -> String {
        switch stage {
        case "Fed": "fork.knife"
        case "Early Fasting": "hourglass.bottomhalf.filled"
        case "Fat Burning": "flame.fill"
        case "Ketosis": "bolt.fill"
        case "Autophagy": "sparkles"
        default: "flame.fill"
        }
    }

    private func formatHHMM(_ totalSeconds: Int) -> String {
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        return String(format: "%d:%02d", h, m)
    }
}
