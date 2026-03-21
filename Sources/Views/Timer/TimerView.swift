import SwiftUI
import SwiftData
import UIKit

/// Ana timer ekranı — oruç başlat/bitir, circular progress, stage tracking.
/// TimelineView ile her saniye güncellenir (sadece foreground'da).
struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var manager = FastingManager()
    @State private var showPlanPicker = false
    @State private var showEndConfirm = false
    @State private var showPaywall = false
    @State private var completedSession: FastingSession?
    
    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Circular timer
                    timerRing
                        .padding(.horizontal, 40)
                    
                    Spacer()
                        .frame(height: 24)
                    
                    // Stage indicator
                    if manager.isActive {
                        FastingStageView(
                            stage: manager.currentStage,
                            elapsed: manager.elapsedTime,
                            isPremium: subscriptionManager.isSubscribed
                        )
                        .transition(.opacity.combined(with: .scale))
                    }
                    
                    Spacer()
                        .frame(height: 32)
                    
                    // Action button
                    actionButton
                    
                    // Plan selector (inactive state)
                    if !manager.isActive {
                        planSelector
                            .padding(.top, 16)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Lumifaste")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("End Fast?", isPresented: $showEndConfirm) {
                Button("End & Save", role: .destructive) {
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.success)
                    withAnimation(.spring(duration: 0.4)) {
                        completedSession = manager.endFast(context: modelContext)
                    }
                }
                Button("Cancel Fast", role: .destructive) {
                    withAnimation(.spring(duration: 0.4)) {
                        manager.cancelFast()
                    }
                }
                Button("Continue", role: .cancel) {}
            } message: {
                Text("Save this fasting session to your history?")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(item: $completedSession) { session in
                FastCompleteView(
                    session: session,
                    isPremium: subscriptionManager.isSubscribed,
                    onUpgrade: { showPaywall = true }
                )
            }
        }
    }
    
    // MARK: - Timer Ring
    
    private var timerRing: some View {
        ZStack {
            CircularProgressView(
                progress: manager.isActive ? manager.progress : 0,
                stage: manager.isActive ? manager.currentStage : .fed
            )
            
            VStack(spacing: 6) {
                if manager.isActive {
                    Text(formatDuration(manager.elapsedTime))
                        .font(.system(size: 44, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    
                    Text("of \(formatDuration(manager.currentPlan.fastingDuration))")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    
                    if manager.isOvertime {
                        Text("🎉 Goal reached!")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.green)
                    }
                } else {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 36))
                        .scaleEffect(x: -1)
                        .foregroundStyle(Color.accentColor)
                    
                    Text("Ready to fast")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button {
            if manager.isActive {
                showEndConfirm = true
            } else {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                withAnimation(.spring(duration: 0.5)) {
                    manager.startFast(plan: manager.currentPlan)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: manager.isActive ? "stop.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text(manager.isActive ? "End Fast" : "Start Fast")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(manager.isActive ? Color.red : Color.accentColor)
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Plan Selector (16:8 free, rest premium)
    
    private var planSelector: some View {
        VStack(spacing: 8) {
            Text("Fasting Plan")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FastingPlan.allCases.filter { $0 != .custom && $0 != .fiveTwo }) { plan in
                        let isFree = plan == .sixteenEight
                        let isLocked = !isFree && !subscriptionManager.isSubscribed
                        
                        PlanChip(
                            plan: plan,
                            isSelected: manager.currentPlan == plan,
                            isLocked: isLocked
                        ) {
                            if isLocked {
                                showPaywall = true
                            } else {
                                withAnimation(.spring(duration: 0.3)) {
                                    manager.setPlan(plan)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Plan Chip

private struct PlanChip: View {
    let plan: FastingPlan
    let isSelected: Bool
    var isLocked: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                HStack(spacing: 3) {
                    Text(plan.rawValue)
                        .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
                Text("\(Int(plan.fastingHours))h")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
            )
            .opacity(isLocked ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TimerView()
        .modelContainer(for: FastingSession.self, inMemory: true)
        .environment(SubscriptionManager())
}
