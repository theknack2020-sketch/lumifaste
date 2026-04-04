import AudioToolbox
import SwiftData
import SwiftUI

/// Solo fasting challenges — progress bars + completion badges.
/// Organized by Daily / Weekly / Monthly / Lifetime sections.
/// XP system displayed in header. Free: 1 active per category. Pro: unlimited.
struct ChallengesView: View {
    let challengeManager: ChallengeManager
    @Environment(ThemeManager.self) private var themeManager
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    @Query(sort: \FastingSession.startDate, order: .reverse)
    private var sessions: [FastingSession]
    @State private var animatingChallenge: FastingChallenge?
    @State private var showPaywall = false
    @State private var showConfetti = false
    @State private var isLoading = true

    /// Free users can have only 1 active challenge per category
    private let freeChallengeLimit = 1

    /// Categories to display in order
    private let displayCategories: [ChallengeCategory] = [.daily, .weekly, .monthly, .lifetime]

    var body: some View {
        ScrollView {
            if isLoading {
                VStack(spacing: 16) {
                    Spacer().frame(height: 60)
                    ProgressView()
                        .controlSize(.large)
                    Text("Loading challenges…")
                        .font(.adaptiveSubheadline(isRegular: isRegular).weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
                .accessibilityLabel("Loading challenges")
            } else {
                VStack(spacing: 20) {
                    // XP + progress header
                    xpHeader
                        .entranceAnimation(delay: 0.1)

                    // Category sections
                    ForEach(Array(displayCategories.enumerated()), id: \.element.id) { index, category in
                        let active = challengeManager.activeChallenges(for: category)
                        let completed = challengeManager.completedChallenges(for: category)

                        if !active.isEmpty || !completed.isEmpty {
                            categorySection(
                                category: category,
                                activeChallenges: active,
                                completedChallenges: completed,
                                sectionIndex: index
                            )
                        }
                    }

                    // Empty state when nothing yet
                    if challengeManager.completedCount == 0, sessions.filter(\.isCompleted).isEmpty {
                        emptyState
                            .padding(.horizontal, 16)
                            .entranceAnimation(delay: 0.2)
                    }

                    // Footer
                    Text("Challenges update automatically after each fast.\nDaily challenges reset at midnight, weekly on Monday.")
                        .font(.adaptiveCaption(isRegular: isRegular))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                        .entranceAnimation(delay: 0.4)
                }
                .padding(.vertical, 16)
            } // end else
        }
        .navigationTitle("Challenges")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if showConfetti {
                ConfettiView(isActive: showConfetti)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
        .onAppear {
            HapticManager.shared.lightTap()
            // Brief loading state for smooth entrance
            if isLoading {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                        isLoading = false
                    }
                }
            }
            let newlyCompleted = challengeManager.evaluate(sessions: sessions)
            if let first = newlyCompleted.first {
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    HapticManager.shared.achievementUnlocked()
                    withAnimation(.smoothSpring) {
                        animatingChallenge = first
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.smoothSpring) {
                            animatingChallenge = nil
                        }
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    showConfetti = false
                }
            }
        }
    }

    // MARK: - XP & Progress Header

    private var xpHeader: some View {
        let accent = themeManager.selectedTheme.accent
        let lifetimeCompleted = challengeManager.completedChallenges(for: .lifetime).count
        let lifetimeTotal = FastingChallenge.challenges(for: .lifetime).count
        let percent = lifetimeTotal > 0
            ? Double(lifetimeCompleted) / Double(lifetimeTotal) * 100
            : 0

        return VStack(spacing: 14) {
            // XP badge
            HStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                    .font(.adaptiveTitle3(isRegular: isRegular))
                    .foregroundStyle(.yellow)
                    .shadow(color: .yellow.opacity(0.3), radius: 4)

                Text(challengeManager.xpDisplayString)
                    .font(.adaptiveTitle2(isRegular: isRegular).weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .accessibilityLabel("Total experience points: \(challengeManager.totalXP)")
            .accessibilityIdentifier("xpBadge")

            // Lifetime completion ring
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [accent.opacity(0.3), accent.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 86, height: 86)

                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 7)
                    .frame(width: 72, height: 72)

                Circle()
                    .trim(from: 0, to: percent / 100)
                    .stroke(
                        LinearGradient(
                            colors: [accent, accent.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))
                    .animation(.progressSpring, value: percent)

                VStack(spacing: 0) {
                    Text("\(lifetimeCompleted)")
                        .font(.adaptiveTitle3(isRegular: isRegular).weight(.bold))
                        .monospacedDigit()
                    Text("of \(lifetimeTotal)")
                        .font(.adaptiveCaption(isRegular: isRegular))
                        .foregroundStyle(.secondary)
                }
            }
            .shadow(color: accent.opacity(0.2), radius: 12, y: 2)

            Text("Lifetime Challenges")
                .font(.adaptiveDetail(isRegular: isRegular).weight(.medium))
                .foregroundStyle(.secondary)

            // Today's active count
            let todayActive = challengeManager.activeChallenges(for: .daily).count
            if todayActive > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "sun.max.fill")
                        .font(.adaptiveBadge(isRegular: isRegular))
                        .foregroundStyle(.orange)
                    Text("\(todayActive) daily challenge\(todayActive == 1 ? "" : "s") remaining")
                        .font(.adaptiveCaption(isRegular: isRegular).weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("challengesHeader")
    }

    // MARK: - Category Section

    private func categorySection(
        category: ChallengeCategory,
        activeChallenges: [FastingChallenge],
        completedChallenges: [FastingChallenge],
        sectionIndex: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header with category info
            categorySectionHeader(category)

            // Active challenges
            ForEach(Array(activeChallenges.enumerated()), id: \.element.id) { index, challenge in
                let isLocked = !subscriptionManager.isSubscribed && index >= freeChallengeLimit

                if isLocked {
                    lockedChallengeCard(challenge: challenge, index: index)
                } else {
                    EnhancedChallengeCard(
                        challenge: challenge,
                        progress: challengeManager.currentProgress(challenge),
                        isCompleted: false,
                        fraction: challengeManager.progressFraction(challenge),
                        accentColor: themeManager.selectedTheme.accent,
                        isAnimating: animatingChallenge == challenge
                    )
                    .staggeredAppear(index: sectionIndex * 3 + index)
                }
            }

            // Completed challenges in this category (compact grid)
            if !completedChallenges.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                ], spacing: 12) {
                    ForEach(Array(completedChallenges.enumerated()), id: \.element.id) { index, challenge in
                        CompletedBadge(
                            challenge: challenge,
                            date: challengeManager.completedDates[challenge],
                            isAnimating: animatingChallenge == challenge
                        )
                        .staggeredAppear(index: index)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Category Section Header

    private func categorySectionHeader(_ category: ChallengeCategory) -> some View {
        HStack(spacing: 6) {
            Image(systemName: category.icon)
                .font(.adaptiveDetail(isRegular: isRegular).weight(.semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeManager.selectedTheme.accent, themeManager.selectedTheme.accent.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(category.displayName)
                .font(.system(.headline, design: .rounded))

            Spacer()

            // Show refresh info for time-bound categories
            switch category {
            case .daily:
                Text("Resets at midnight")
                    .font(.adaptiveCaption(isRegular: isRegular))
                    .foregroundStyle(.tertiary)
            case .weekly:
                Text("Resets Monday")
                    .font(.adaptiveCaption(isRegular: isRegular))
                    .foregroundStyle(.tertiary)
            case .monthly:
                Text("Resets monthly")
                    .font(.adaptiveCaption(isRegular: isRegular))
                    .foregroundStyle(.tertiary)
            case .lifetime:
                EmptyView()
            }
        }
        .accessibilityLabel("\(category.displayName) challenges")
    }

    // MARK: - Locked Challenge Card

    private func lockedChallengeCard(challenge: FastingChallenge, index: Int) -> some View {
        EnhancedChallengeCard(
            challenge: challenge,
            progress: challengeManager.currentProgress(challenge),
            isCompleted: false,
            fraction: challengeManager.progressFraction(challenge),
            accentColor: themeManager.selectedTheme.accent,
            isAnimating: false
        )
        .blur(radius: 4)
        .allowsHitTesting(false)
        .overlay {
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.adaptiveTitle3(isRegular: isRegular))
                    .foregroundStyle(.secondary)
                Text("Pro Feature")
                    .font(.adaptiveDetail(isRegular: isRegular).weight(.semibold))
                Button {
                    HapticManager.shared.lightTap()
                    showPaywall = true
                } label: {
                    Text("Upgrade")
                        .font(.adaptiveCaption(isRegular: isRegular).weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("upgradeButton")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.8))
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Locked challenge. Upgrade to Pro for unlimited challenges.")
            .accessibilityAddTraits(.isButton)
        }
        .staggeredAppear(index: index)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [themeManager.selectedTheme.accent.opacity(0.12), themeManager.selectedTheme.accent.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                    .shadow(color: themeManager.selectedTheme.accent.opacity(0.15), radius: 12, y: 4)

                Image(systemName: "flag.checkered")
                    .font(.adaptiveDisplay(size: 48, weight: .light, design: .rounded, isRegular: isRegular))
                    .foregroundStyle(themeManager.selectedTheme.accent.opacity(0.7))
                    .symbolEffect(.pulse, options: .repeating.speed(0.5))
            }
            .accessibilityHidden(true)

            Text("Ready to Challenge Yourself?")
                .font(.system(.title3, design: .rounded, weight: .bold))

            Text("Complete fasts to make progress on challenges.\nEach fast brings you closer to earning badges and XP.")
                .font(.adaptiveDetail(isRegular: isRegular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.adaptiveCaption(isRegular: isRegular))
                    .foregroundStyle(.orange)
                Text("Start a fast to begin your first challenge")
                    .font(.adaptiveDetail(isRegular: isRegular).weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ready to challenge yourself. Complete fasts to earn badges and XP.")
        .accessibilityIdentifier("challengesEmptyState")
    }
}

// MARK: - Enhanced Challenge Card (Active)

struct EnhancedChallengeCard: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    let challenge: FastingChallenge
    let progress: Int
    let isCompleted: Bool
    let fraction: Double
    let accentColor: Color
    var isAnimating: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(challenge.color.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: challenge.icon)
                        .font(.adaptiveTitle3(isRegular: isRegular).weight(.semibold))
                        .foregroundStyle(challenge.color)
                }
                .shadow(color: challenge.color.opacity(0.2), radius: 4, y: 2)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(.spring(duration: 0.5, bounce: 0.5), value: isAnimating)

                // Title + subtitle + difficulty + XP
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(challenge.title)
                            .font(.system(.headline, design: .rounded))

                        // Difficulty badge
                        Text(challenge.difficulty.displayName)
                            .font(.adaptiveSmallLabel(isRegular: isRegular).weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(challenge.difficulty.color)
                            )
                            .accessibilityLabel("Difficulty: \(challenge.difficulty.displayName)")
                    }

                    Text(challenge.subtitle)
                        .font(.adaptiveCaption(isRegular: isRegular))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Progress count + XP reward
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(progress)/\(challenge.targetCount)")
                        .font(.adaptiveDetail(isRegular: isRegular).weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(challenge.color)

                    Text("+\(challenge.xpReward) XP")
                        .font(.adaptiveCaption(isRegular: isRegular).weight(.semibold))
                        .foregroundStyle(.yellow.opacity(0.8))
                }
            }

            // Progress bar with percentage
            HStack(spacing: 8) {
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
                            .shadow(color: challenge.color.opacity(0.3), radius: 4, y: 1)
                            .animation(.progressSpring, value: fraction)
                    }
                }
                .frame(height: 8)

                Text("\(Int(fraction * 100))%")
                    .font(.adaptiveBadge(isRegular: isRegular).weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
                    .frame(width: 36, alignment: .trailing)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(challenge.color.gradient)
                .frame(width: 3)
                .padding(.vertical, 10)
        }
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .shadow(color: challenge.color.opacity(0.1), radius: 6, y: 2)
        .scaleEffect(isAnimating ? 1.03 : 1.0)
        .opacity(isAnimating ? 0.9 : 1.0)
        .animation(.spring(duration: 0.4, bounce: 0.4), value: isAnimating)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(challenge.title), \(challenge.difficulty.displayName) difficulty, \(progress) of \(challenge.targetCount). \(challenge.subtitle). Worth \(challenge.xpReward) XP.")
        .accessibilityIdentifier("challengeCard_\(challenge.rawValue)")
    }
}

// MARK: - Completed Badge

struct CompletedBadge: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

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

                Image(systemName: challenge.badgeIcon)
                    .font(.adaptiveTitle2(isRegular: isRegular).weight(.semibold))
                    .foregroundStyle(challenge.color)
            }
            .shadow(color: challenge.color.opacity(0.35), radius: 8, y: 3)
            .scaleEffect(isAnimating ? 1.3 : 1.0)
            .goldGlow(when: isAnimating)
            .animation(.spring(duration: 0.5, bounce: 0.5), value: isAnimating)

            Text(challenge.title)
                .font(.adaptiveCaption(isRegular: isRegular).weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .minimumScaleFactor(0.8)

            // XP earned
            Text("+\(challenge.xpReward) XP")
                .font(.adaptiveCaption(isRegular: isRegular).weight(.bold))
                .foregroundStyle(.yellow.opacity(0.7))

            if let date = formattedDate {
                Text(date)
                    .font(.adaptiveCaption(isRegular: isRegular))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(challenge.color.opacity(0.04))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(challenge.color.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: challenge.color.opacity(0.2), radius: 6, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(challenge.title), completed\(formattedDate.map { " on \($0)" } ?? ""), earned \(challenge.xpReward) XP")
        .accessibilityIdentifier("completedBadge_\(challenge.rawValue)")
    }
}

#Preview {
    NavigationStack {
        ChallengesView(challengeManager: ChallengeManager())
            .modelContainer(for: FastingSession.self, inMemory: true)
            .environment(ThemeManager())
            .environment(SubscriptionManager())
    }
}
