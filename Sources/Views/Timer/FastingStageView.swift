import SwiftUI

/// Fasting stage badge — şu anki aşamayı gösterir.
struct FastingStageView: View {
    let stage: FastingStage
    let elapsed: TimeInterval
    
    var body: some View {
        VStack(spacing: 8) {
            // Stage badge
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
            
            // Stage description
            Text(stage.subtitle)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            
            // Next stage hint
            if let next = stage.next {
                let hoursUntilNext = max(0, (next.startHour * 3600 - elapsed) / 3600)
                if hoursUntilNext > 0 {
                    Text("\(next.rawValue) in \(formatHours(hoursUntilNext))")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
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
        FastingStageView(stage: .fed, elapsed: 2 * 3600)
        FastingStageView(stage: .fatBurning, elapsed: 14 * 3600)
        FastingStageView(stage: .autophagy, elapsed: 26 * 3600)
    }
    .padding()
}
