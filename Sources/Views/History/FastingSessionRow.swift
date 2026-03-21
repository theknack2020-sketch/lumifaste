import SwiftUI

/// Tek bir oruç oturumunun satır görünümü.
struct FastingSessionRow: View {
    let session: FastingSession
    
    var body: some View {
        HStack(spacing: 14) {
            // Stage icon
            ZStack {
                Circle()
                    .fill(session.stage.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: session.stage.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(session.stage.color)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.plan.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                    
                    Text(session.stage.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(session.stage.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(session.stage.color.opacity(0.12))
                        .clipShape(Capsule())
                }
                
                Text(session.startDate.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Duration
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDuration(session.actualDuration))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                
                if session.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
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
            return s
        }())
        
        FastingSessionRow(session: {
            let s = FastingSession(
                startDate: Date.now.addingTimeInterval(-20 * 3600),
                targetEndDate: Date.now.addingTimeInterval(-2 * 3600),
                planType: .eighteenSix
            )
            s.complete()
            return s
        }())
    }
}
