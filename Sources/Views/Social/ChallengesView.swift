import SwiftUI
import SwiftData
import AudioToolbox

/// Solo fasting challenges — progress bars + completion badges.
/// No server, no multiplayer. Locally tracked via ChallengeManager.
struct ChallengesView: View {
    let challengeManager: ChallengeManager
    @Environment(ThemeManager.self) private var themeManager
    @Query(sort: \FastingSession.startDate, order: .reverse)
    private var sessions: [FastingSession]
    @State private var animatingChallenge: FastingChallenge?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Progress header
                progressHeader
                    .entranceAnimation(delay: 0.1)
                
                // Active challenges
                if !challengeManager.activeChallenges.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Active Challenges", icon: "target", color: themeManager.selectedTheme.accent)
                        
                        ForEach(Array(challengeManager.activeChallenges.enumerated()), id: \.element.id) { index, challenge in
                            ChallengeCard(
                                challenge: challenge,
                                progress: challengeManager.currentProgress(challenge),
                                isCompleted: false,
                                fraction: challengeManager.progressFraction(challenge),
                                accentColor: themeManager.selectedTheme.accent
                            )
                            .staggeredAppear(index: index)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Completed challenges
                if !challengeManager.completedChallenges.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Completed", icon: "checkmark.seal.fill", color: .green)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(Array(challengeManager.completedChallenges.enumerated()), id: \.element.id) { index, challenge in
                                CompletedBadge(
                                    challenge: challenge,
                                    date: challengeManager.completedDates[challenge],
                                    isAnimating: animatingChallenge == challenge
                                )
                                .staggeredAppear(index: index)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Empty state when nothing yet
                if challengeManager.completedCount == 0 && sessions.filter(\.isCompleted).isEmpty {
                    emptyState
                        .padding(.horizontal, 16)
                        .entranceAnimation(delay: 0.2)
                }
                
                // Footer
                Text("Challenges update automatically after each fast.")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .entranceAnimation(delay: 0.4)
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("Challenges")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            HapticManager.shared.lightTap()
            let newlyCompleted = challengeManager.evaluate(sessions: sessions)
            if let first = newlyCompleted.first {
                AudioServicesPlaySystemSound(1025)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    HapticManager.shared.success()
                    withAnimation(.smoothSpring) {
                        animatingChallenge = first
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.smoothSpring) {
                            animatingChallenge = nil
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        let accent = themeManager.selectedTheme.accent
        let percent = challengeManager.totalCount > 0
            ? Double(challengeManager.completedCount) / Double(challengeManager.totalCount) * 100
            : 0
        
        return VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: percent / 100)
                    .stroke(accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.progressSpring, value: percent)
                
                VStack(spacing: 0) {
                    Text("\(challengeManager.completedCount)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("of \(challengeManager.totalCount)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            
            Text(String(format: "%.0f%% Complete", percent))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(challengeManager.completedCount) of \(challengeManager.totalCount) challenges completed, \(String(format: "%.0f", percent)) percent")
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 16, weight: .bold))
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(themeManager.selectedTheme.accent.opacity(0.6))
            
            Text("Ready to Challenge Yourself?")
                .font(.system(size: 17, weight: .semibold))
            
            Text("Complete fasts to make progress on challenges.\nEach fast brings you closer to earning badges.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(themeManager.selectedTheme.accent.opacity(0.06))
        )
    }
}

// MARK: - Challenge Card (Active)

struct ChallengeCard: View {
    let challenge: FastingChallenge
    let progress: Int
    let isCompleted: Bool
    let fraction: Double
    let accentColor: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(challenge.color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: challenge.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(challenge.color)
                }
                
                // Title + subtitle
                VStack(alignment: .leading, spacing: 3) {
                    Text(challenge.title)
                        .font(.system(size: 15, weight: .semibold))
                    Text(challenge.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Progress count
                Text("\(progress)/\(challenge.targetCount)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(challenge.color)
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [challenge.color.opacity(0.7), challenge.color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * fraction, height: 8)
                        .animation(.progressSpring, value: fraction)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(challenge.title), \(progress) of \(challenge.targetCount). \(challenge.subtitle)")
    }
}

// MARK: - Completed Badge

struct CompletedBadge: View {
    let challenge: FastingChallenge
    let date: Date?
    var isAnimating: Bool = false
    
    private var formattedDate: String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(challenge.color.opacity(0.15))
                    .frame(width: 52, height: 52)
                    .shadow(color: challenge.color.opacity(0.25), radius: 6, y: 2)
                
                Image(systemName: challenge.badgeIcon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(challenge.color)
            }
            .scaleEffect(isAnimating ? 1.3 : 1.0)
            .goldGlow(when: isAnimating)
            .animation(.spring(duration: 0.5, bounce: 0.5), value: isAnimating)
            
            Text(challenge.title)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            if let date = formattedDate {
                Text(date)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(challenge.title), completed\(formattedDate.map { " on \($0)" } ?? "")")
    }
}

#Preview {
    NavigationStack {
        ChallengesView(challengeManager: ChallengeManager())
            .modelContainer(for: FastingSession.self, inMemory: true)
            .environment(ThemeManager())
    }
}
