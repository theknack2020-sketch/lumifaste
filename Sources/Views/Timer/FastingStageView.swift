import SwiftUI

/// Fasting stage badge — şu anki aşamayı gösterir.
/// Free: stage ismi + icon. Premium: subtitle + next stage hint.
struct FastingStageView: View {
    let stage: FastingStage
    let elapsed: TimeInterval
    var isPremium: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Stage badge — always visible
            HStack(spacing: 6) {
                Image(systemName: stage.icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(stage.rawValue)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(stage.color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(stage.color.opacity(0.12))
            .clipShape(Capsule())
            
            if isPremium {
                // Premium: stage description
                Text(stage.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                
                // Premium: next stage hint
                if let next = stage.next {
                    let hoursUntilNext = max(0, (next.startHour * 3600 - elapsed) / 3600)
                    if hoursUntilNext > 0 {
                        Text("\(next.rawValue) in \(formatHours(hoursUntilNext))")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                }
            } else {
                // Free: teaser
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                    Text("Upgrade for stage details")
                        .font(.system(size: 12))
                }
                .foregroundStyle(.secondary)
            }
        }
    }
    
    private func formatHours(_ hours: Double) -> String {
        if hours < 1 {
            return "\(Int(hours * 60))min"
        }
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return m > 0 ? "\(h)h \(m)min" : "\(h)h"
    }
}

#Preview {
    VStack(spacing: 20) {
        FastingStageView(stage: .fatBurning, elapsed: 14 * 3600, isPremium: true)
        FastingStageView(stage: .fatBurning, elapsed: 14 * 3600, isPremium: false)
    }
    .padding()
}
