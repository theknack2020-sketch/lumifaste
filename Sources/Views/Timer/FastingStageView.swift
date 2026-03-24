import SwiftUI

/// Fasting stage badge — şu anki aşamayı gösterir.
/// Standalone version for use outside the main timer (e.g. fast detail, history).
/// Free: stage ismi + icon. Premium: subtitle + next stage hint + metabolic info.
/// Fully accessible with VoiceOver support.
/// Redesigned: glassmorphism cards, layered shadows for depth, monospacedDigit on times.
struct FastingStageView: View {
    let stage: FastingStage
    let elapsed: TimeInterval
    var isPremium: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Stage badge — always visible, animated on stage change
            HStack(spacing: 6) {
                Image(systemName: stage.icon)
                    .font(.system(.subheadline, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))
                Text(stage.rawValue)
                    .font(.system(.subheadline, weight: .semibold))
                    .contentTransition(.numericText())
            }
            .foregroundStyle(stage.color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: stage.color.opacity(0.3), radius: 8, x: 0, y: 2)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 1)
            )
            .animation(.smoothSpring, value: stage)
            
            if isPremium {
                // Premium: stage description — fade transition
                Text(stage.subtitle)
                    .font(.system(.footnote))
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: stage)
                
                // Premium: metabolic info teaser
                if let detail = FastingEducation.detail(for: stage) {
                    Text(detail.metabolicInfo.prefix(80) + "…")
                        .font(.system(.caption))
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .contentTransition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: stage)
                }
                
                // Premium: next stage hint
                if let next = stage.next {
                    let hoursUntilNext = max(0, (next.startHour * 3600 - elapsed) / 3600)
                    if hoursUntilNext > 0 {
                        Text("\(next.rawValue) in \(formatHours(hoursUntilNext))")
                            .font(.system(.caption))
                            .monospacedDigit()
                            .foregroundStyle(.tertiary)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.3), value: next)
                    }
                }
            } else {
                // Free: teaser
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(.caption2))
                    Text("Upgrade for stage details")
                        .font(.system(.caption))
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .shadow(color: stage.color.opacity(0.1), radius: 12, x: 0, y: 2)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }
    
    private var accessibilityDescription: String {
        var desc = "Current stage: \(stage.rawValue). \(stage.subtitle)."
        if isPremium, let next = stage.next {
            let hoursUntilNext = max(0, (next.startHour * 3600 - elapsed) / 3600)
            if hoursUntilNext > 0 {
                desc += " Next stage: \(next.rawValue) in \(formatHours(hoursUntilNext))."
            }
        }
        return desc
    }
    
    private func formatHours(_ hours: Double) -> String {
        if hours < 1 {
            return "\(Int(hours * 60)) minutes"
        }
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return m > 0 ? "\(h) hours \(m) minutes" : "\(h) hours"
    }
}

#Preview {
    VStack(spacing: 20) {
        FastingStageView(stage: .fatBurning, elapsed: 14 * 3600, isPremium: true)
        FastingStageView(stage: .fatBurning, elapsed: 14 * 3600, isPremium: false)
    }
    .padding()
    .preferredColorScheme(.dark)
}
