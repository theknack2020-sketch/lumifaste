import SwiftUI
import SwiftData
import AudioToolbox

/// Achievement badges grid — shown in Settings or as a standalone view.
/// Shows earned badges with dates, locked badges with requirements.
/// Unlock animation: scale + opacity spring.
struct AchievementsView: View {
    let achievementManager: AchievementManager
    @Environment(ThemeManager.self) private var themeManager
    @Query(sort: \FastingSession.startDate, order: .reverse)
    private var sessions: [FastingSession]
    @State private var animatingBadge: Achievement?
    @State private var showShareSheet = false
    @State private var shareableImage: ShareableImage?
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Progress header
                progressHeader
                    .entranceAnimation(delay: 0.1)
                
                // Motivational empty state when nothing earned yet
                if achievementManager.earnedCount == 0 {
                    VStack(spacing: 14) {
                        Image(systemName: "star.circle")
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(themeManager.selectedTheme.accent.opacity(0.6))
                        
                        Text("Your First Badge Awaits")
                            .font(.system(.headline, design: .rounded))
                        
                        Text("Complete fasts to unlock achievements.\nEvery journey starts with a single step.")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(themeManager.selectedTheme.accent.opacity(0.06))
                            )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    .padding(.horizontal, 16)
                    .entranceAnimation(delay: 0.15)
                }
                
                // Badge grid
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Array(Achievement.allCases.enumerated()), id: \.element.id) { index, achievement in
                        AchievementBadge(
                            achievement: achievement,
                            isEarned: achievementManager.isEarned(achievement),
                            dateEarned: achievementManager.dateEarned(achievement),
                            isAnimating: animatingBadge == achievement
                        )
                        .staggeredAppear(index: index)
                    }
                }
                .padding(.horizontal, 16)
                
                // Referral
                referralSection
                    .padding(.horizontal, 16)
                    .entranceAnimation(delay: 0.3)
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            HapticManager.shared.lightTap()
            // Evaluate on appear
            let newlyUnlocked = achievementManager.evaluate(sessions: sessions)
            if let first = newlyUnlocked.first {
                // Sound 1025: celebration chime on achievement unlock
                AudioServicesPlaySystemSound(1025)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    HapticManager.shared.success()
                    withAnimation(.smoothSpring) {
                        animatingBadge = first
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.smoothSpring) {
                            animatingBadge = nil
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let item = shareableImage {
                ActivityShareSheet(image: item.image, caption: item.caption)
            }
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        let accent = themeManager.selectedTheme.accent
        return VStack(spacing: 12) {
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [accent.opacity(0.3), accent.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 96, height: 96)
                
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: achievementManager.completionPercent / 100)
                    .stroke(
                        LinearGradient(
                            colors: [accent, accent.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.progressSpring, value: achievementManager.completionPercent)
                
                VStack(spacing: 0) {
                    Text("\(achievementManager.earnedCount)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("of \(achievementManager.totalCount)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .shadow(color: accent.opacity(0.2), radius: 12, y: 2)
            
            Text(String(format: "%.0f%% Complete", achievementManager.completionPercent))
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(achievementManager.earnedCount) of \(achievementManager.totalCount) achievements earned, \(String(format: "%.0f", achievementManager.completionPercent)) percent complete")
    }
    
    // MARK: - Referral Section
    
    private var referralSection: some View {
        let accent = themeManager.selectedTheme.accent
        return VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(accent)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tell a friend about Lumifaste")
                        .font(.system(.headline, design: .rounded))
                    Text("Share the app with friends who want a clean, ad-free fasting tracker")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            ShareLink(
                item: URL(string: "https://apps.apple.com/app/lumifaste/id6740062938")!,
                subject: Text("Check out Lumifaste"),
                message: Text("I've been using Lumifaste for intermittent fasting — no ads, just a clean timer. Give it a try!")
            ) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                    Text("Share Lumifaste")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [accent, accent.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: accent.opacity(0.35), radius: 10, y: 4)
                .shadow(color: accent.opacity(0.15), radius: 4, y: 2)
            }
            .buttonStyle(.bounce)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}

// MARK: - Achievement Badge

struct AchievementBadge: View {
    let achievement: Achievement
    let isEarned: Bool
    let dateEarned: Date?
    var isAnimating: Bool = false
    
    private var formattedDate: String? {
        guard let date = dateEarned else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isEarned ? achievement.color.opacity(0.15) : Color(.systemGray5))
                    .frame(width: 56, height: 56)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(isEarned ? achievement.color : Color(.systemGray3))
            }
            .shadow(color: isEarned ? achievement.color.opacity(0.3) : .black.opacity(0.08), radius: isEarned ? 8 : 4, y: isEarned ? 3 : 2)
            .scaleEffect(isAnimating ? 1.3 : 1.0)
            .opacity(isAnimating ? 0.7 : 1.0)
            .goldGlow(when: isAnimating)
            .animation(.spring(duration: 0.5, bounce: 0.5), value: isAnimating)
            
            Text(achievement.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isEarned ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            if let date = formattedDate {
                Text(date)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            } else {
                Text(achievement.subtitle)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: isEarned ? achievement.color.opacity(0.15) : .black.opacity(0.08), radius: isEarned ? 6 : 3, y: 2)
        .opacity(isEarned ? 1.0 : 0.5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(achievement.title), \(isEarned ? "earned" : "locked"). \(achievement.subtitle)")
    }
}

// MARK: - Achievement Unlock Overlay

struct AchievementUnlockOverlay: View {
    let achievement: Achievement
    let onDismiss: () -> Void
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.4 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismissWithAnimation() }
            
            VStack(spacing: 16) {
                Text("🏆")
                    .font(.system(size: 48))
                
                Text("Achievement Unlocked!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                
                ZStack {
                    Circle()
                        .fill(achievement.color.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(achievement.color)
                }
                .shadow(color: achievement.color.opacity(0.4), radius: 12, y: 4)
                
                Text(achievement.title)
                    .font(.system(.headline, design: .rounded))
                
                Text(achievement.subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Button {
                    dismissWithAnimation()
                } label: {
                    Text("Awesome!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 160, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [achievement.color, achievement.color.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .shadow(color: achievement.color.opacity(0.4), radius: 10, y: 4)
                }
                .buttonStyle(.bounce)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .shadow(color: .black.opacity(0.2), radius: 20, y: 8)
            .scaleEffect(appeared ? 1 : 0.6)
            .opacity(appeared ? 1 : 0)
            .padding(.horizontal, 40)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.4)) {
                appeared = true
            }
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(.easeInOut(duration: 0.2)) {
            appeared = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}

// MARK: - UIKit Activity Share Sheet (for image sharing)

struct ActivityShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    let caption: String
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let items: [Any] = [image, caption]
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        AchievementsView(achievementManager: AchievementManager())
            .modelContainer(for: FastingSession.self, inMemory: true)
            .environment(ThemeManager())
    }
}
