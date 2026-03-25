import ActivityKit
import SwiftUI
import WidgetKit

/// Live Activity UI for the fasting timer — Lock Screen, Dynamic Island compact & expanded.
struct FastingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FastingActivityAttributes.self) { context in
            // MARK: - Lock Screen / StandBy Banner
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
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
                        Text(formatHHMM(context.state.elapsedSeconds))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                        Text("of \(formatHHMM(context.state.targetSeconds))")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(context.state.currentStage)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(stageColor(context.state.currentStage))

                        // Progress bar
                        GeometryReader { geo in
                            let progress = context.state.targetSeconds > 0
                                ? min(1.0, Double(context.state.elapsedSeconds) / Double(context.state.targetSeconds))
                                : 0.0
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.15))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(stageColor(context.state.currentStage))
                                    .frame(width: geo.size.width * progress, height: 6)
                            }
                        }
                        .frame(height: 6)
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
                Text(formatMMSS(context.state.elapsedSeconds))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
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
        let progress = context.state.targetSeconds > 0
            ? min(1.0, Double(context.state.elapsedSeconds) / Double(context.state.targetSeconds))
            : 0.0
        let color = stageColor(context.state.currentStage)

        HStack(spacing: 14) {
            // Circular progress ring
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 5)
                    .frame(width: 50, height: 50)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                Text(context.state.stageEmoji)
                    .font(.system(size: 18))
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

                // Elapsed time — primary
                Text(formatHHMM(context.state.elapsedSeconds))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                // Remaining
                let remaining = max(0, context.state.targetSeconds - context.state.elapsedSeconds)
                if remaining > 0 {
                    Text("\(formatHHMM(remaining)) remaining")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Goal reached! 🎉")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.01)) // Ensure tap target
    }

    // MARK: - Helpers

    private func stageColor(_ stage: String) -> Color {
        switch stage {
        case "Fed": return .gray
        case "Early Fasting": return .yellow
        case "Fat Burning": return .orange
        case "Ketosis": return .blue
        case "Autophagy": return .purple
        default: return .green
        }
    }

    private func stageIcon(_ stage: String) -> String {
        switch stage {
        case "Fed": return "fork.knife"
        case "Early Fasting": return "hourglass.bottomhalf.filled"
        case "Fat Burning": return "flame.fill"
        case "Ketosis": return "bolt.fill"
        case "Autophagy": return "sparkles"
        default: return "flame.fill"
        }
    }

    private func formatHHMM(_ totalSeconds: Int) -> String {
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        return String(format: "%d:%02d", h, m)
    }

    private func formatMMSS(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
