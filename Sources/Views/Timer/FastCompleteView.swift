import SwiftUI

/// Oruç tamamlama raporu — doğal premium conversion moment.
/// Free: tebrik + basit özet. Premium: detaylı breakdown.
struct FastCompleteView: View {
    let session: FastingSession
    let isPremium: Bool
    let onUpgrade: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Celebration header
                    celebrationHeader
                    
                    // Basic stats — always visible
                    basicStats
                    
                    // Premium breakdown
                    if isPremium {
                        premiumBreakdown
                    } else {
                        premiumTeaser
                    }
                    
                    // Done button
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.accentColor)
                            )
                    }
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Celebration
    
    private var celebrationHeader: some View {
        VStack(spacing: 12) {
            Text("🎉")
                .font(.system(size: 56))
            
            Text("Fast Complete!")
                .font(.system(size: 26, weight: .bold))
            
            Text("Great discipline — you did it.")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Basic Stats (Free)
    
    private var basicStats: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                StatItem(title: "Duration", value: formatDuration(session.actualDuration), icon: "clock.fill", color: .blue)
                StatItem(title: "Plan", value: session.plan.rawValue, icon: "calendar", color: .orange)
                StatItem(title: "Stage", value: session.stage.rawValue, icon: session.stage.icon, color: session.stage.color)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Premium Breakdown
    
    private var premiumBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Stage Breakdown")
                .font(.system(size: 17, weight: .bold))
            
            ForEach(FastingStage.allCases) { stage in
                let timeInStage = stageTime(for: stage)
                if timeInStage > 0 {
                    HStack(spacing: 12) {
                        Image(systemName: stage.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(stage.color)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stage.rawValue)
                                .font(.system(size: 14, weight: .medium))
                            Text(stage.subtitle)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(formatDurationShort(timeInStage))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Premium Teaser (Free users)
    
    private var premiumTeaser: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("See Your Full Report")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Stage breakdown, time in each phase, and trends over time")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            
            Button {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onUpgrade()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                    Text("Try Premium Free")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            .linearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Helpers
    
    private func stageTime(for stage: FastingStage) -> TimeInterval {
        let total = session.actualDuration
        let stageStart = stage.startHour * 3600
        let nextStart = stage.next?.startHour ?? 999
        let stageEnd = nextStart * 3600
        
        guard total > stageStart else { return 0 }
        return min(total, stageEnd) - stageStart
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
    
    private func formatDurationShort(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Free") {
    let session = FastingSession(
        startDate: Date.now.addingTimeInterval(-16 * 3600),
        targetEndDate: Date.now,
        planType: .sixteenEight
    )
    session.complete()
    return FastCompleteView(session: session, isPremium: false, onUpgrade: {})
}

#Preview("Premium") {
    let session = FastingSession(
        startDate: Date.now.addingTimeInterval(-20 * 3600),
        targetEndDate: Date.now,
        planType: .twentyFour
    )
    session.complete()
    return FastCompleteView(session: session, isPremium: true, onUpgrade: {})
}
