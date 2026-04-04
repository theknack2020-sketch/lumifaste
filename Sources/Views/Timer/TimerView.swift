import SwiftData
import SwiftUI
import UIKit

/// Main timer screen — start/end fast, circular progress, stage tracking.
/// TimelineView ile her saniye güncellenir (sadece foreground'da).
/// Soft paywall trigger: shows after 3rd completed fast (non-blocking).
///
/// REDESIGNED: gradient backgrounds, prominent stage display, time remaining,
/// next stage progress, motivational quotes, quick-action buttons, streak counter,
/// improved plan selector, date display, breathing animation on ring.
struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    @Query private var allSessions: [FastingSession]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @State private var manager = FastingManager()
    @State private var showPlanPicker = false
    @State private var showEndConfirm = false
    @State private var showPaywall = false
    @State private var showSoftPaywall = false
    @State private var completedSession: FastingSession?
    @State private var lastStage: FastingStage = .fed
    @State private var showEditStartTime = false
    @State private var showExtendSheet = false
    @State private var showCustomPlanSheet = false
    @State private var showNudge = false
    @State private var showClockWarning = false
    @State private var showMoodLogger = false
    @State private var selectedQuickMood: String?

    /// Task handle for product loading — enables cancellation
    @State private var productLoadTask: Task<Void, Never>?
    @State private var achievementManager = AchievementManager()
    @State private var unlockedAchievement: Achievement?
    @State private var showStreakShareSheet = false
    @State private var streakShareImage: UIImage?

    /// Tracks last Live Activity update to throttle to ~60s intervals
    @State private var lastLiveActivityUpdate: Date = .distantPast

    @State private var showError = false
    @State private var errorMessage: String?
    @State private var journeyManager = OnboardingJourneyManager()

    // MARK: - Dynamic Type Support

    @ScaledMetric(relativeTo: .body) private var cardPadding: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var sectionSpacing: CGFloat = 24
    @ScaledMetric(relativeTo: .body) private var horizontalPadding: CGFloat = 20

    /// Tracks whether we've shown the soft paywall this session to avoid repeat
    @AppStorage("lf_soft_paywall_shown") private var softPaywallShown = false

    /// Number of completed fasts needed before showing soft paywall
    private let softPaywallThreshold = 3

    private var completedFastCount: Int {
        allSessions.filter(\.isCompleted).count
    }

    /// Current streak — used for streak reminder notifications.
    /// If there's a gap of exactly 1 day and a streak freeze is available (Pro only),
    /// auto-uses it to maintain the streak.
    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: .now)
        var usedFreeze = false

        let completedDays = Set(
            allSessions
                .filter(\.isCompleted)
                .map { calendar.startOfDay(for: $0.startDate) }
        )
        .sorted(by: >)

        // Build a quick-lookup set
        let daySet = Set(completedDays)

        // Walk backward from today
        while true {
            if daySet.contains(checkDate) {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else {
                // Gap day — try streak freeze if Pro and haven't used one in this calculation
                if !usedFreeze,
                   subscriptionManager.isSubscribed,
                   FastingManager.streakFreezeCount > 0,
                   streak > 0
                {
                    // Check if the previous day has a fast (gap is exactly 1 day)
                    if let prev = calendar.date(byAdding: .day, value: -1, to: checkDate),
                       daySet.contains(prev)
                    {
                        // Use the freeze to bridge this gap
                        if FastingManager.useStreakFreeze() {
                            usedFreeze = true
                            // Skip this gap day, continue counting
                            checkDate = prev
                            continue
                        }
                    }
                }
                break
            }
        }
        return streak
    }

    // MARK: - Motivational Quotes

    private static let motivationalQuotes: [(text: String, author: String)] = [
        ("The body achieves what the mind believes.", "Napoleon Hill"),
        ("Discipline is the bridge between goals and accomplishment.", "Jim Rohn"),
        ("Every hour of fasting is an investment in your health.", ""),
        ("Your body is healing right now. Trust the process.", ""),
        ("Small daily improvements lead to extraordinary results.", "Robin Sharma"),
        ("The secret of getting ahead is getting started.", "Mark Twain"),
        ("You are stronger than your cravings.", ""),
        ("This discomfort is temporary. The benefits last.", ""),
        ("Fasting is the greatest remedy — the physician within.", "Paracelsus"),
        ("Take care of your body. It's the only place you have to live.", "Jim Rohn"),
        ("Strength does not come from what you can do. It comes from overcoming what you once thought you couldn't.", ""),
        ("The best time to plant a tree was 20 years ago. The second best time is now.", "Chinese Proverb"),
    ]

    private var currentQuote: (text: String, author: String) {
        let interval = manager.isActive ? manager.elapsedTime : 0
        // Rotate every 5 minutes
        let index = Int(interval / 300) % Self.motivationalQuotes.count
        return Self.motivationalQuotes[index]
    }

    /// Streak-based motivational micro-copy
    private var streakMicroCopy: String? {
        switch currentStreak {
        case 1: "Great start! 🌱"
        case 2 ... 6: "Building momentum! 💪"
        case 7 ... 13: "On fire! 🔥"
        case 14 ... 29: "Incredible discipline! ⚡"
        case 30...: "Unstoppable! 🏆"
        default: nil
        }
    }

    // MARK: - Stage Background Gradient

    private var stageGradient: LinearGradient {
        let stage = manager.isActive ? manager.currentStage : .fed
        let colors: [Color] = switch stage {
        case .fed:
            [Color(red: 0.02, green: 0.06, blue: 0.04), themeManager.selectedTheme.accent.opacity(0.08), Color(.systemBackground)]
        case .earlyFasting:
            [Color(red: 0.04, green: 0.06, blue: 0.05), Color(red: 0.0, green: 0.12, blue: 0.10), Color(.systemBackground)]
        case .fatBurning:
            [Color(red: 0.08, green: 0.04, blue: 0.0), Color.orange.opacity(0.18), Color(.systemBackground)]
        case .ketosis:
            [Color(red: 0.04, green: 0.02, blue: 0.10), Color.purple.opacity(0.16), Color(.systemBackground)]
        case .autophagy:
            [Color(red: 0.08, green: 0.02, blue: 0.08), Color(red: 0.20, green: 0.0, blue: 0.15).opacity(0.20), Color(.systemBackground)]
        }
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1.0)) { _ in
                let _ = detectStageChange()
                let _ = periodicClockCheck()
                let _ = updateLiveActivityIfNeeded()
                ScrollView {
                    VStack(spacing: 0) {
                        // Date & streak header
                        dateAndStreakHeader
                            .padding(.horizontal, horizontalPadding)
                            .padding(.top, 8)

                        // Onboarding journey banner (#19-22)
                        if let banner = journeyManager.currentDayBanner() {
                            onboardingBanner(banner: banner)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Nudge banner (#13)
                        if showNudge, !manager.isActive {
                            nudgeBanner
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        Spacer()
                            .frame(height: 16)

                        // Circular timer with glow and breathing
                        timerRing
                            .padding(.horizontal, 32)
                            .entranceAnimation(delay: 0.1)

                        Spacer()
                            .frame(height: 16)

                        // Current fasting stage — prominent display
                        if manager.isActive {
                            currentStageDisplay
                                .padding(.horizontal, 20)
                                .id(manager.currentStage)
                                .transition(
                                    .asymmetric(
                                        insertion: .opacity
                                            .combined(with: .scale(scale: 0.9))
                                            .animation(.smoothSpring),
                                        removal: .opacity
                                            .combined(with: .scale(scale: 1.05))
                                            .animation(.easeInOut(duration: 0.2))
                                    )
                                )

                            // Estimated calorie burn counter
                            calorieBurnDisplay
                                .padding(.horizontal, 20)
                                .padding(.top, 6)

                            // Daily step count from HealthKit
                            stepCountBadge
                                .padding(.horizontal, 20)
                                .padding(.top, 4)
                        }

                        // Next stage progress
                        if manager.isActive, let next = manager.currentStage.next {
                            nextStageIndicator(next: next)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                        }

                        Spacer()
                            .frame(height: 12)

                        // Water tracking card (active fast only)
                        if manager.isActive {
                            waterTrackingSection
                        }

                        Spacer()
                            .frame(height: 12)

                        // Motivational quote card
                        if manager.isActive, !manager.isPaused {
                            motivationalQuoteCard
                                .padding(.horizontal, 20)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        Spacer()
                            .frame(height: 12)

                        // Stage-specific tip — contextual to current stage
                        if manager.isActive {
                            stageTipView
                                .padding(.horizontal, 20)
                                .padding(.top, 2)
                                .id("stagetip-\(manager.currentStage)")
                                .transition(.opacity)
                        }

                        // Quick action buttons (water, mood, end fast)
                        if manager.isActive {
                            quickActionBar
                                .padding(.top, 16)
                                .padding(.horizontal, 20)
                        }

                        // Community comparison (#7)
                        if manager.isActive, let avg = CommunityStats.average(for: manager.currentPlan) {
                            communityComparison(avg: avg)
                                .padding(.top, 12)
                                .padding(.horizontal, 20)
                        }

                        Spacer()
                            .frame(height: 24)

                        // Action buttons — redesigned
                        actionButtons
                            .entranceAnimation(delay: 0.25)

                        // Plan selector (inactive state) — redesigned
                        if !manager.isActive {
                            // First-time motivational card (no fasts yet)
                            if completedFastCount == 0 {
                                firstFastTeaseCard
                                    .padding(.horizontal, 20)
                                    .padding(.top, 8)
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }

                            planSelector
                                .padding(.top, 16)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        Spacer()
                            .frame(height: 32)
                    }
                    .animation(.smoothSpring, value: manager.isActive)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: manager.isPaused)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: manager.currentStage)
                }
                .background(stageGradient.ignoresSafeArea())
            }
            .navigationTitle("Lumifaste")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Fasting status indicator in nav bar (#13)
                if manager.isActive {
                    ToolbarItem(placement: .topBarTrailing) {
                        fastingStatusBadge
                    }
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .confirmationDialog("End Fast?", isPresented: $showEndConfirm) {
                Button("End & Save", role: .destructive) {
                    endAndSaveFast()
                }
                Button("Cancel Fast", role: .destructive) {
                    HapticManager.shared.heavyTap()
                    withAnimation(.smoothSpring) {
                        manager.cancelFast()
                    }
                }
                Button("Continue", role: .cancel) {}
            } message: {
                Text("Save this fasting session to your history?")
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
            .fullScreenCover(isPresented: $showSoftPaywall) {
                SoftPaywallView(reason: .completedFasts(count: completedFastCount))
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showEditStartTime) {
                EditStartTimeSheet(manager: manager)
                    .presentationDetents([.height(280)])
            }
            .sheet(isPresented: $showExtendSheet) {
                ExtendFastSheet(manager: manager)
                    .presentationDetents([.height(300)])
            }
            .sheet(isPresented: $showCustomPlanSheet) {
                CustomPlanSheet {
                    manager.setPlan(.custom)
                }
                .presentationDetents([.height(300)])
            }
            .sheet(item: $completedSession) { session in
                FastCompleteView(
                    session: session,
                    isPremium: subscriptionManager.isSubscribed,
                    onUpgrade: { showPaywall = true },
                    streak: currentStreak
                )
                .onDisappear {
                    checkSoftPaywallTrigger()
                    let newlyUnlocked = achievementManager.evaluate(sessions: allSessions)
                    if let first = newlyUnlocked.first {
                        HapticManager.shared.achievementUnlocked()
                        if Achievement.streakMilestones.contains(first) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                streakShareImage = ShareImageRenderer.renderStreakCard(
                                    streakDays: currentStreak,
                                    achievement: first
                                )
                                showStreakShareSheet = true
                            }
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                unlockedAchievement = first
                            }
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .notificationActionReceived)) { notification in
                guard let actionID = notification.userInfo?["actionID"] as? String else { return }
                handleNotificationAction(actionID)
            }
            .overlay {
                if let achievement = unlockedAchievement {
                    AchievementUnlockOverlay(achievement: achievement) {
                        unlockedAchievement = nil
                    }
                }
            }
            .sheet(isPresented: $showStreakShareSheet) {
                if let image = streakShareImage {
                    ActivityShareSheet(
                        image: image,
                        caption: "🔥 \(currentStreak)-day fasting streak with Lumifaste! #Lumifaste #IntermittentFasting"
                    )
                }
            }
            .onAppear {
                if !manager.isActive, completedFastCount > 0 {
                    showNudge = FastingManager.shouldShowNudge(sessions: allSessions)
                }
                // Auto-refill streak freeze on Mondays for Pro users
                FastingManager.refillStreakFreezeIfNeeded(isPremium: subscriptionManager.isSubscribed)
                // Fetch today's step count from Apple Health
                Task {
                    await HealthKitManager.shared.fetchTodaySteps()
                }
                // Schedule retention notifications (#14-18)
                Task { @MainActor in
                    let status = await NotificationManager.shared.authorizationStatus()
                    guard status == .authorized else { return }
                    NotificationManager.shared.scheduleRetentionNotifications(
                        sessions: allSessions,
                        currentStreak: currentStreak,
                        isCurrentlyFasting: manager.isActive
                    )
                    // Schedule Day 1-3 journey push notifications (idempotent)
                    journeyManager.scheduleJourneyPushNotifications()
                }
            }
            .onDisappear {
                productLoadTask?.cancel()
            }
            .alert("Clock Change Detected", isPresented: $showClockWarning) {
                Button("OK") {
                    showClockWarning = false
                }
            } message: {
                Text("Your device clock may have changed significantly. The fasting timer uses absolute timestamps and should remain accurate, but please verify your elapsed time looks correct.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "Something went wrong. Please try again.")
            }
        }
    }

    // MARK: - Notification Action Handling

    private func handleNotificationAction(_ actionID: String) {
        switch actionID {
        case NotificationActionID.endFast.rawValue:
            if manager.isActive {
                endAndSaveFast()
            }
        case NotificationActionID.extendFast.rawValue:
            if manager.isActive {
                showExtendSheet = true
            }
        case NotificationActionID.startFast.rawValue:
            if !manager.isActive {
                withAnimation(.smoothSpring) {
                    manager.startFast(plan: manager.currentPlan)
                }
            }
        default:
            break
        }
    }

    private func endAndSaveFast() {
        HapticManager.shared.fastCompleted()
        withAnimation(.smoothSpring) {
            let session = manager.endFast(context: modelContext)
            if session != nil {
                completedSession = session
            } else {
                errorMessage = "Couldn't save your fasting session. Please try again."
                showError = true
            }
        }
        Task { @MainActor in
            NotificationManager.shared.scheduleStreakReminder(currentStreak: currentStreak)
            NotificationManager.shared.scheduleDailyStreakNotification(currentStreak: currentStreak)
        }
    }

    // MARK: - Soft Paywall Trigger

    private func checkSoftPaywallTrigger() {
        guard !subscriptionManager.isSubscribed,
              !softPaywallShown,
              completedFastCount >= softPaywallThreshold else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showSoftPaywall = true
            softPaywallShown = true
        }
    }

    // MARK: - Date & Streak Header (#10, #11)

    private var dateAndStreakHeader: some View {
        HStack {
            // Today's date and day-of-week
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now, format: .dateTime.weekday(.wide))
                    .font(.adaptiveDetail(isRegular: isRegular).weight(.semibold))
                    .foregroundStyle(.primary)
                Text(Date.now, format: .dateTime.month(.wide).day())
                    .font(.adaptiveCaption(isRegular: isRegular))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Mini streak counter — visible to ALL users (retention hook)
            // Pro extras: streak freeze, streak protection notification, share card
            if currentStreak > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.adaptiveDetail(isRegular: isRegular))
                            .foregroundStyle(.orange)
                        Text("\(currentStreak)")
                            .font(.adaptiveSubheadline(isRegular: isRegular).weight(.bold))
                            .foregroundStyle(.orange)
                            .contentTransition(.numericText())
                        Text(currentStreak == 1 ? "day" : "days")
                            .font(.adaptiveBadge(isRegular: isRegular))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.1))
                    )

                    if let microCopy = streakMicroCopy {
                        Text(microCopy)
                            .font(.adaptiveBadge(isRegular: isRegular).weight(.medium))
                            .foregroundStyle(.orange.opacity(0.8))
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }

                    // Pro upsell hint for free users with active streak
                    if !subscriptionManager.isSubscribed, currentStreak >= 3 {
                        HStack(spacing: 3) {
                            Image(systemName: "shield.fill")
                                .font(.adaptiveSmallLabel(isRegular: isRegular))
                                .foregroundStyle(.purple.opacity(0.6))
                            Text("Protect streak")
                                .font(.adaptiveCaption(isRegular: isRegular).weight(.medium))
                                .foregroundStyle(.purple.opacity(0.6))
                        }
                        .onTapGesture {
                            HapticManager.shared.lightTap()
                            showPaywall = true
                        }
                    }
                }
                .accessibilityLabel("\(currentStreak) day fasting streak\(streakMicroCopy.map { ", \($0)" } ?? "")")
            }
        }
    }

    // MARK: - Fasting Status Badge (nav bar) (#13)

    private var fastingStatusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(manager.isPaused ? Color.orange : Color.green)
                .frame(width: 7, height: 7)
            Text(manager.isPaused ? "Paused" : "Fasting")
                .font(.adaptiveBadge(isRegular: isRegular).weight(.semibold))
                .foregroundStyle(manager.isPaused ? .orange : .green)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill((manager.isPaused ? Color.orange : Color.green).opacity(0.12))
        )
        .accessibilityLabel(manager.isPaused ? "Fast is paused" : "Currently fasting")
        .accessibilityIdentifier("fastingStatusBadge")
    }

    // MARK: - Nudge Banner (#13)

    private var nudgeBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "hand.wave.fill")
                .font(.adaptiveTitle3(isRegular: isRegular))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("We miss you!")
                    .font(.adaptiveDetail(isRegular: isRegular).weight(.semibold))
                Text("It's been a while since your last fast. Ready to get back on track?")
                    .font(.adaptiveCaption(isRegular: isRegular))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button {
                withAnimation(.smoothSpring) {
                    showNudge = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.adaptiveCaption(isRegular: isRegular).weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.1))
        )
    }

    // MARK: - Onboarding Journey Banner (#19-22)

    private func onboardingBanner(banner: OnboardingJourneyManager.Banner) -> some View {
        HStack(spacing: 12) {
            Image(systemName: banner.icon)
                .font(.adaptiveTitle3(isRegular: isRegular))
                .foregroundStyle(themeManager.selectedTheme.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(banner.title)
                    .font(.adaptiveDetail(isRegular: isRegular).weight(.semibold))
                Text(banner.message)
                    .font(.adaptiveCaption(isRegular: isRegular))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer()

            Button {
                withAnimation(.smoothSpring) {
                    journeyManager.dismissBanner()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.adaptiveCaption(isRegular: isRegular).weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(themeManager.selectedTheme.accent.opacity(0.08))
                .shadow(color: themeManager.selectedTheme.accent.opacity(0.1), radius: 6, x: 0, y: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(banner.title) \(banner.message)")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Timer Ring (redesigned)

    private var timerRing: some View {
        let accent = themeManager.selectedTheme.accent
        return ZStack {
            CircularProgressView(
                progress: manager.isActive ? manager.progress : 0,
                stage: manager.isActive ? manager.currentStage : .fed,
                lineWidth: 28,
                themeAccent: accent,
                isBreathing: manager.isActive && !manager.isPaused
            )
            .pulsing(when: manager.isActive && !manager.isPaused)

            VStack(spacing: 4) {
                if manager.isActive {
                    if manager.isPaused {
                        Image(systemName: "pause.circle.fill")
                            .font(.adaptiveDisplay(size: 32, weight: .regular, design: .default, isRegular: isRegular))
                            .foregroundStyle(.orange)

                        Text("PAUSED")
                            .font(.adaptiveDetail(isRegular: isRegular).weight(.bold))
                            .foregroundStyle(.orange)

                        Text(formatDuration(manager.elapsedTime))
                            .font(.adaptiveDisplay(size: 28, weight: .light, design: .rounded, isRegular: isRegular))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    } else {
                        // Compute elapsed and remaining from same integer base
                        // This guarantees elapsed + remaining = total plan duration exactly
                        let elapsedSeconds = Int(manager.elapsedTime)
                        let totalSeconds: Int = {
                            guard let s = manager.startDate, let e = manager.targetEndDate else { return 0 }
                            return Int(e.timeIntervalSince(s))
                        }()
                        let remainingSeconds = max(0, totalSeconds - elapsedSeconds)

                        // Elapsed time — big and prominent
                        Text(String(format: "%02d:%02d:%02d", elapsedSeconds / 3600, (elapsedSeconds % 3600) / 60, elapsedSeconds % 60))
                            .font(.adaptiveDisplay(size: 56, weight: .bold, design: .rounded, isRegular: isRegular))
                            .monospacedDigit()
                            .contentTransition(.numericText(countsDown: false))
                            .animation(.easeInOut(duration: 0.3), value: elapsedSeconds)

                        Text("ELAPSED")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.tertiary)
                            .tracking(2)

                        // Divider line
                        Rectangle()
                            .fill(.quaternary)
                            .frame(width: 40, height: 1)
                            .padding(.vertical, 2)

                        // Time remaining display (#4)
                        if remainingSeconds > 0 {
                            Text(String(format: "%02d:%02d:%02d", remainingSeconds / 3600, (remainingSeconds % 3600) / 60, remainingSeconds % 60))
                                .font(.adaptiveTitle3(isRegular: isRegular).weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .contentTransition(.numericText(countsDown: true))
                                .animation(.easeInOut(duration: 0.3), value: remainingSeconds)

                            Text("REMAINING")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.tertiary)
                                .tracking(2)
                        }

                        if manager.isOvertime {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.adaptiveDetail(isRegular: isRegular))
                                Text("Goal reached!")
                                    .font(.adaptiveDetail(isRegular: isRegular).weight(.semibold))
                            }
                            .foregroundStyle(.green)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                } else {
                    Image(systemName: "leaf.fill")
                        .font(.adaptiveDisplay(size: 36, weight: .regular, design: .default, isRegular: isRegular))
                        .scaleEffect(x: -1)
                        .foregroundStyle(accent)

                    Text("Ready to fast")
                        .font(.adaptiveSubheadline(isRegular: isRegular).weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)

                    Text(manager.currentPlan.rawValue)
                        .font(.adaptiveDetail(isRegular: isRegular).weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: manager.isActive)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: manager.isPaused)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Current Stage Display (#3) — prominent below timer

    private var currentStageDisplay: some View {
        HStack(spacing: 0) {
            // Left accent bar in stage color
            RoundedRectangle(cornerRadius: 2)
                .fill(manager.currentStage.color)
                .frame(width: 3)
                .padding(.vertical, 8)

            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: manager.currentStage.icon)
                        .font(.adaptiveHeadline(isRegular: isRegular).weight(.semibold))
                        .contentTransition(.symbolEffect(.replace))
                        .shadow(color: manager.currentStage.color.opacity(0.4), radius: 8)
                    Text(manager.currentStage.rawValue)
                        .font(.adaptiveTitle3(isRegular: isRegular).weight(.bold))
                        .contentTransition(.numericText())
                }
                .foregroundStyle(manager.currentStage.color)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 1.1).combined(with: .opacity)
                ))

                Text(manager.currentStage.subtitle)
                    .font(.adaptiveDetail(isRegular: isRegular))
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
                    .transition(.opacity.combined(with: .offset(y: 6)))

                // Premium: metabolic info teaser
                if subscriptionManager.isSubscribed, let detail = FastingEducation.detail(for: manager.currentStage) {
                    Text(detail.metabolicInfo.prefix(90) + "…")
                        .font(.adaptiveBadge(isRegular: isRegular))
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .contentTransition(.opacity)
                        .transition(.opacity)
                } else if !subscriptionManager.isSubscribed {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.adaptiveSmallLabel(isRegular: isRegular))
                        Text("Unlock stage science with Pro")
                            .font(.adaptiveBadge(isRegular: isRegular).weight(.semibold))
                    }
                    .foregroundStyle(themeManager.selectedTheme.accent)
                    .padding(.top, 2)
                }
            }
            .padding(.vertical, 12)
            .padding(.leading, 12)
            .padding(.trailing, 16)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: manager.currentStage.color.opacity(0.2), radius: 12, x: 0, y: 4)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .animation(.smoothSpring, value: manager.currentStage)
    }

    // MARK: - Estimated Calorie Burn Display

    private var calorieBurnDisplay: some View {
        let fastingHours = manager.elapsedTime / 3600.0
        let latestWeight = weightEntries.first?.weightKg
        let kcal = Int(CalorieBurnEstimator.estimate(fastingHours: fastingHours, bodyWeightKg: latestWeight))

        return HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.adaptiveDetail(isRegular: isRegular))
                .foregroundStyle(.orange)
                .shadow(color: .orange.opacity(0.4), radius: 6)
            Text("~\(kcal) kcal burned")
                .font(.adaptiveDetail(isRegular: isRegular).weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: kcal)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .accessibilityLabel("Approximately \(kcal) kilocalories burned during this fast")
    }

    // MARK: - Step Count Badge (Apple Health)

    private var stepCountBadge: some View {
        let steps = HealthKitManager.shared.todayStepCount
        return Group {
            if HealthKitManager.shared.isAvailable, steps > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.adaptiveCaption(isRegular: isRegular))
                        .foregroundStyle(.red)
                    Image(systemName: "figure.walk")
                        .font(.adaptiveDetail(isRegular: isRegular))
                        .foregroundStyle(.green)
                    Text(steps.formatted(.number.grouping(.automatic)))
                        .font(.adaptiveDetail(isRegular: isRegular).weight(.medium))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("steps")
                        .font(.adaptiveDetail(isRegular: isRegular).weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.1))
                )
                .accessibilityLabel("\(steps) steps today from Apple Health")
            }
        }
    }

    // MARK: - Next Stage Indicator (#5)

    private func nextStageIndicator(next: FastingStage) -> some View {
        let hoursUntilNext = max(0, next.startHour * 3600 - manager.elapsedTime)
        let stageStart = manager.currentStage.startHour * 3600.0
        let stageEnd = next.startHour * 3600.0
        let stageProgress = min(1.0, max(0, (manager.elapsedTime - stageStart) / (stageEnd - stageStart)))

        return VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: next.icon)
                    .font(.adaptiveDetail(isRegular: isRegular))
                    .foregroundStyle(next.color)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("\(next.rawValue)")
                            .font(.adaptiveCaption(isRegular: isRegular).weight(.semibold))
                            .foregroundStyle(next.color)

                        if hoursUntilNext > 0 {
                            Text("in \(formatDurationCompact(hoursUntilNext))")
                                .font(.adaptiveCaption(isRegular: isRegular).weight(.medium))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(Int(stageProgress * 100))%")
                            .font(.adaptiveCaption(isRegular: isRegular).weight(.bold))
                            .foregroundStyle(next.color.opacity(0.8))
                    }
                }
            }

            // Progress bar with stage icons at start/end
            HStack(spacing: 6) {
                Image(systemName: manager.currentStage.icon)
                    .font(.adaptiveCaption(isRegular: isRegular))
                    .foregroundStyle(manager.currentStage.color.opacity(0.6))

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(next.color.opacity(0.12))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [manager.currentStage.color, next.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * stageProgress, height: 6)
                            .animation(.progressSpring, value: stageProgress)
                    }
                }
                .frame(height: 6)

                Image(systemName: next.icon)
                    .font(.adaptiveCaption(isRegular: isRegular))
                    .foregroundStyle(next.color.opacity(0.6))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                .shadow(color: next.color.opacity(0.1), radius: 10, x: 0, y: 2)
        )
    }

    // MARK: - Motivational Quote Card (#6)

    private var motivationalQuoteCard: some View {
        let quote = currentQuote
        return HStack(spacing: 0) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(themeManager.selectedTheme.accent.opacity(0.6))
                .frame(width: 3)
                .padding(.vertical, 4)

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "quote.opening")
                        .font(.adaptiveCaption(isRegular: isRegular))
                        .foregroundStyle(themeManager.selectedTheme.accent.opacity(0.6))
                    Spacer()
                }

                Text(quote.text)
                    .font(.adaptiveDetail(isRegular: isRegular).weight(.medium))
                    .foregroundStyle(.primary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                if !quote.author.isEmpty {
                    Text("— \(quote.author)")
                        .font(.adaptiveBadge(isRegular: isRegular).weight(.medium))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 14)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                .shadow(color: themeManager.selectedTheme.accent.opacity(0.08), radius: 12, x: 0, y: 2)
        )
        .id("quote-\(currentQuote.text.prefix(20))")
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.5), value: currentQuote.text)
    }

    // MARK: - Stage Tip (shown when entering a new stage)

    private var stageTipView: some View {
        let stageTips = FastingTips.stageTips(for: manager.currentStage)
        let tipIndex = Int(manager.elapsedTime / 300) % max(1, stageTips.count)
        let tip = stageTips.isEmpty ? (FastingTips.tips.first ?? FastingTips.Tip(id: -1, emoji: "💧", text: "Stay hydrated during your fast.", category: .hydration)) : stageTips[tipIndex]

        return HStack(spacing: 0) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.yellow.opacity(0.5))
                .frame(width: 3)
                .padding(.vertical, 4)

            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.adaptiveCaption(isRegular: isRegular))
                    .foregroundStyle(.yellow)
                Text(tip.text)
                    .font(.adaptiveBadge(isRegular: isRegular))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(.leading, 10)
            .padding(.trailing, 10)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        )
    }

    // MARK: - Water Tracking Section

    private var waterTrackingSection: some View {
        WaterTrackingCard(
            waterCount: Binding(
                get: { manager.waterCount },
                set: { _ in }
            ),
            onAddWater: { count in
                for _ in 0 ..< count {
                    manager.logWater()
                }
            }
        )
        .padding(.horizontal, 20)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Quick Action Bar (#7) — water, mood, end fast

    private var quickActionBar: some View {
        HStack(spacing: 0) {
            // Water counter
            Button {
                HapticManager.shared.waterLogged()
                manager.logWater()
            } label: {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color.cyan.opacity(0.1))
                            .frame(width: 44, height: 44)
                        Image(systemName: "drop.fill")
                            .font(.adaptiveHeadline(isRegular: isRegular))
                            .foregroundStyle(.cyan)
                    }
                    HStack(spacing: 2) {
                        Text("\(manager.waterCount)")
                            .font(.adaptiveDetail(isRegular: isRegular).weight(.bold))
                        Text("Water")
                            .font(.adaptiveCaption(isRegular: isRegular))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.bounce)
            .accessibilityLabel("Log water, \(manager.waterCount) glasses logged")
            .frame(maxWidth: .infinity)

            // Pause/Resume
            Button {
                HapticManager.shared.pauseResume()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    if manager.isPaused {
                        manager.resumeFast()
                    } else {
                        manager.pauseFast()
                    }
                }
            } label: {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: 44, height: 44)
                        Image(systemName: manager.isPaused ? "play.fill" : "pause.fill")
                            .font(.adaptiveHeadline(isRegular: isRegular))
                            .foregroundStyle(.orange)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    Text(manager.isPaused ? "Resume" : "Pause")
                        .font(.adaptiveCaption(isRegular: isRegular))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.bounce)
            .accessibilityLabel(manager.isPaused ? "Resume fast" : "Pause fast")
            .frame(maxWidth: .infinity)

            // Edit start time
            Button {
                HapticManager.shared.lightTap()
                showEditStartTime = true
            } label: {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 44, height: 44)
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.adaptiveHeadline(isRegular: isRegular))
                            .foregroundStyle(.blue)
                    }
                    Text("Adjust")
                        .font(.adaptiveCaption(isRegular: isRegular))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.bounce)
            .accessibilityLabel("Adjust start time")
            .frame(maxWidth: .infinity)

            // Extend (when overtime) or log mood
            if manager.isOvertime {
                Button {
                    HapticManager.shared.lightTap()
                    showExtendSheet = true
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 44, height: 44)
                            Image(systemName: "plus.circle.fill")
                                .font(.adaptiveHeadline(isRegular: isRegular))
                                .foregroundStyle(.green)
                        }
                        Text("Extend")
                            .font(.adaptiveCaption(isRegular: isRegular))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.bounce)
                .accessibilityLabel("Extend fast")
                .frame(maxWidth: .infinity)
            } else {
                // End fast quick button
                Button {
                    showEndConfirm = true
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.1))
                                .frame(width: 44, height: 44)
                            Image(systemName: "stop.fill")
                                .font(.adaptiveHeadline(isRegular: isRegular))
                                .foregroundStyle(.red)
                        }
                        Text("End")
                            .font(.adaptiveCaption(isRegular: isRegular))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.bounce)
                .accessibilityLabel("End fast")
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Community Comparison (#7)

    private func communityComparison(avg: CommunityStats.PlanAverage) -> some View {
        let userHours = manager.elapsedTime / 3600
        let ahead = userHours > avg.averageDurationHours

        return HStack(spacing: 10) {
            Image(systemName: "person.2.fill")
                .font(.adaptiveDetail(isRegular: isRegular))
                .foregroundStyle(.purple)

            VStack(alignment: .leading, spacing: 2) {
                Text("Community Avg: \(String(format: "%.1f", avg.averageDurationHours))h")
                    .font(.adaptiveCaption(isRegular: isRegular).weight(.medium))
                    .foregroundStyle(.secondary)

                if manager.elapsedTime > 3600 {
                    Text(ahead ? "You're ahead of average! 💪" : "Keep going — you're getting there!")
                        .font(.adaptiveBadge(isRegular: isRegular))
                        .foregroundStyle(ahead ? .green : .secondary)
                }
            }

            Spacer()

            Text("\(CommunityStats.formatCount(avg.participantCount)) fasters")
                .font(.adaptiveCaption(isRegular: isRegular))
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        )
    }

    // MARK: - Action Buttons (redesigned — gradient + shadow + glow)

    private var actionButtons: some View {
        let accent = themeManager.selectedTheme.accent
        let buttonColor = manager.isActive ? Color.red : accent
        return VStack(spacing: 10) {
            Button {
                if manager.isActive {
                    showEndConfirm = true
                } else {
                    HapticManager.shared.fastStarted()
                    withAnimation(.smoothSpring) {
                        manager.startFast(plan: manager.currentPlan)
                        showNudge = false
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: manager.isActive ? "stop.fill" : "play.fill")
                        .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))
                        .contentTransition(.symbolEffect(.replace))
                    Text(manager.isActive ? "End Fast" : "Start Fast")
                        .font(.adaptiveBody(isRegular: isRegular).weight(.bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            manager.isActive
                                ? AnyShapeStyle(LinearGradient(colors: [.red, .red.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                : AnyShapeStyle(themeManager.selectedTheme.accentGradient)
                        )
                )
                .shadow(color: buttonColor.opacity(0.4), radius: 16, y: 6)
                .shadow(color: buttonColor.opacity(0.2), radius: 6, y: 2)
                .animation(.smoothSpring, value: manager.isActive)
            }
            .buttonStyle(.pressable)
            .breathingScale(when: !manager.isActive, maxScale: 1.05, duration: 2.0)
            .padding(.horizontal, 20)

            // Extend button when overtime
            if manager.isActive, manager.isOvertime {
                Button {
                    HapticManager.shared.lightTap()
                    showExtendSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.adaptiveDetail(isRegular: isRegular).weight(.semibold))
                        Text("Keep Going — Extend Fast")
                            .font(.adaptiveSubheadline(isRegular: isRegular).weight(.medium))
                    }
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.green.opacity(0.12))
                    )
                }
                .buttonStyle(.bounce)
                .padding(.horizontal, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - First Fast Tease Card

    private var firstFastTeaseCard: some View {
        let accent = themeManager.selectedTheme.accent
        return VStack(spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [accent.opacity(0.2), accent.opacity(0.05)],
                                center: .center,
                                startRadius: 2,
                                endRadius: 20
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: "sparkles")
                        .font(.adaptiveHeadline(isRegular: isRegular))
                        .foregroundStyle(accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Ready for your first fast?")
                        .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))
                    Text("Pick a plan below and tap Start Fast")
                        .font(.adaptiveCaption(isRegular: isRegular))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Quick benefit pills
            HStack(spacing: 8) {
                benefitPill(icon: "flame.fill", text: "Burn fat", color: .orange)
                benefitPill(icon: "brain.head.profile", text: "Mental clarity", color: .purple)
                benefitPill(icon: "bolt.fill", text: "More energy", color: .yellow)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.08), accent.opacity(0.02)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .shadow(color: accent.opacity(0.1), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ready for your first fast? Pick a plan below and tap Start Fast")
    }

    private func benefitPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.adaptiveCaption(isRegular: isRegular))
                .foregroundStyle(color)
            Text(text)
                .font(.adaptiveBadge(isRegular: isRegular).weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.08))
        )
    }

    // MARK: - Plan Selector (redesigned — shows plan details #12)

    private var planSelector: some View {
        VStack(spacing: 10) {
            Text("Choose Your Plan")
                .font(.adaptiveDetail(isRegular: isRegular).weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FastingPlan.allCases.filter { $0 != .fiveTwo }) { plan in
                        let isLocked = plan == .custom && !subscriptionManager.isSubscribed

                        PlanCard(
                            plan: plan,
                            isSelected: manager.currentPlan == plan,
                            isLocked: isLocked,
                            themeAccent: themeManager.selectedTheme.accent
                        ) {
                            if isLocked {
                                HapticManager.shared.warning()
                                showPaywall = true
                            } else if plan == .custom {
                                HapticManager.shared.planSelected()
                                showCustomPlanSheet = true
                            } else {
                                HapticManager.shared.planSelected()
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
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

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let total = Int(duration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func formatDurationCompact(_ duration: TimeInterval) -> String {
        let total = Int(duration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0, minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    /// Detect fasting stage transitions and fire haptic + sound
    @discardableResult
    private func detectStageChange() -> Bool {
        guard manager.isActive else {
            lastStage = .fed
            return false
        }
        let current = manager.currentStage
        if current != lastStage {
            let previous = lastStage
            lastStage = current
            if current.index > previous.index {
                HapticManager.shared.stageTransition()
            }
            return true
        }
        return false
    }

    /// Periodic clock integrity check — runs every tick but only acts on anomalies
    @discardableResult
    private func periodicClockCheck() -> Bool {
        guard manager.isActive else { return false }
        manager.checkClockIntegrity()
        if manager.clockAnomalyDetected, !showClockWarning {
            showClockWarning = true
            return true
        }
        return false
    }

    /// Update Live Activity every ~60 seconds (battery-friendly) or on stage change
    @discardableResult
    private func updateLiveActivityIfNeeded() -> Bool {
        guard manager.isActive, !manager.isPaused else { return false }
        let now = Date.now
        let elapsed = now.timeIntervalSince(lastLiveActivityUpdate)
        let stageChanged = manager.currentStage != lastStage
        guard elapsed >= 60 || stageChanged || lastLiveActivityUpdate == .distantPast else { return false }

        let stage = manager.currentStage
        let totalSeconds: Int = {
            guard let s = manager.startDate, let e = manager.targetEndDate else { return 0 }
            return Int(e.timeIntervalSince(s))
        }()

        LiveActivityManager.updateLiveActivity(
            elapsedSeconds: Int(manager.elapsedTime),
            targetSeconds: totalSeconds,
            stage: stage.rawValue,
            stageEmoji: stage.emoji,
            planName: manager.currentPlan.rawValue
        )
        lastLiveActivityUpdate = now
        return true
    }
}

// MARK: - Plan Card (redesigned — shows details, difficulty, subtitle)

private struct PlanCard: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    let plan: FastingPlan
    let isSelected: Bool
    var isLocked: Bool = false
    let themeAccent: Color
    let action: () -> Void

    private var difficultyDots: Int {
        plan.difficulty
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                // Header: plan name + lock
                HStack(spacing: 4) {
                    Text(plan.rawValue)
                        .font(.adaptiveSubheadline(isRegular: isRegular).weight(isSelected ? .bold : .semibold))
                        .foregroundStyle(isSelected ? themeAccent : .primary)
                    if isLocked {
                        Text("PRO")
                            .font(.adaptiveSmallLabel(isRegular: isRegular).weight(.heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
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
                }

                // Subtitle: "16h fast · 8h eat"
                Text(plan.subtitle)
                    .font(.adaptiveBadge(isRegular: isRegular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Difficulty dots
                HStack(spacing: 3) {
                    ForEach(0 ..< 5, id: \.self) { i in
                        Circle()
                            .fill(i < difficultyDots ? themeAccent.opacity(isSelected ? 0.8 : 0.4) : Color(.systemGray5))
                            .frame(width: 5, height: 5)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(width: 136)
            .frame(minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(isSelected ? 0.3 : 0.15), radius: isSelected ? 10 : 6, x: 0, y: isSelected ? 4 : 2)
                    .shadow(color: isSelected ? themeAccent.opacity(0.2) : .clear, radius: 12, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? themeAccent.opacity(0.6) : .white.opacity(0.06), lineWidth: isSelected ? 1.5 : 0.5)
            )
            .opacity(isLocked ? 0.6 : 1.0)
            .animation(.tapSpring, value: isSelected)
        }
        .buttonStyle(.bounce)
    }
}

// MARK: - Edit Start Time Sheet (#1)

struct EditStartTimeSheet: View {
    let manager: FastingManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    @State private var selectedDate: Date = .now

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("When did you actually start fasting?")
                    .font(.adaptiveSubheadline(isRegular: isRegular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                DatePicker(
                    "Start Time",
                    selection: $selectedDate,
                    in: Date.now.addingTimeInterval(-24 * 3600) ... Date.now,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .labelsHidden()

                Button {
                    HapticManager.shared.mediumTap()
                    manager.adjustStartTime(to: selectedDate)
                    dismiss()
                } label: {
                    Text("Update Start Time")
                        .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.accentColor)
                        )
                }
                .buttonStyle(.bounce)
            }
            .padding(24)
            .navigationTitle("Adjust Start Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("cancelButton")
                }
            }
            .onAppear {
                selectedDate = manager.startDate ?? .now
            }
        }
    }
}

// MARK: - Extend Fast Sheet (#3)

struct ExtendFastSheet: View {
    let manager: FastingManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    @State private var extendHours: Double = 2

    private let options: [Double] = [1, 2, 4, 6]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("🔥")
                    .font(.adaptiveDisplay(size: 44, weight: .regular, design: .rounded, isRegular: isRegular))

                Text("Keep Going!")
                    .font(.adaptiveTitle3(isRegular: isRegular).weight(.bold))

                Text("You've reached your goal. Extend your fast to push further.")
                    .font(.adaptiveDetail(isRegular: isRegular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    ForEach(options, id: \.self) { hours in
                        Button {
                            HapticManager.shared.selectionChanged()
                            extendHours = hours
                        } label: {
                            Text("+\(Int(hours))h")
                                .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(extendHours == hours ? Color.green.opacity(0.2) : Color(.systemGray6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(extendHours == hours ? Color.green : .clear, lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.bounce)
                    }
                }

                Button {
                    HapticManager.shared.mediumTap()
                    manager.extendFast(byHours: extendHours)
                    dismiss()
                } label: {
                    Text("Extend by \(Int(extendHours)) hours")
                        .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.green)
                        )
                }
                .buttonStyle(.bounce)
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("cancelButton")
                }
            }
        }
    }
}

// MARK: - Custom Plan Sheet (#2)

struct CustomPlanSheet: View {
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    @State private var hours: Double = FastingPlan.customHours
    @State private var showExtremeWarning = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Custom Fasting Plan")
                    .font(.adaptiveTitle3(isRegular: isRegular).weight(.bold))

                VStack(spacing: 8) {
                    Text("\(Int(hours))h")
                        .font(.adaptiveDisplay(size: 48, weight: .bold, design: .rounded, isRegular: isRegular))
                        .foregroundStyle(InputValidator.isExtremeFast(hours: hours) ? .orange : Color.accentColor)

                    Text("fasting window")
                        .font(.adaptiveDetail(isRegular: isRegular))
                        .foregroundStyle(.secondary)

                    if InputValidator.isExtremeFast(hours: hours) {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.adaptiveBadge(isRegular: isRegular))
                            Text("Extended fasts require medical supervision")
                                .font(.adaptiveCaption(isRegular: isRegular))
                        }
                        .foregroundStyle(.orange)
                        .transition(.opacity)
                    }
                }

                Slider(value: $hours, in: 1 ... 48, step: 1)
                    .tint(InputValidator.isExtremeFast(hours: hours) ? .orange : Color.accentColor)
                    .padding(.horizontal, 20)

                HStack {
                    Text("1h")
                        .font(.adaptiveCaption(isRegular: isRegular))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("48h")
                        .font(.adaptiveCaption(isRegular: isRegular))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 20)

                Button {
                    if InputValidator.isExtremeFast(hours: hours) {
                        showExtremeWarning = true
                    } else {
                        savePlan()
                    }
                } label: {
                    Text("Set Plan")
                        .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.accentColor)
                        )
                }
                .buttonStyle(.bounce)
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("cancelButton")
                }
            }
            .animation(.smoothSpring, value: InputValidator.isExtremeFast(hours: hours))
            .alert("Extended Fast Warning", isPresented: $showExtremeWarning) {
                Button("I Understand", role: .destructive) {
                    savePlan()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Fasts over 72 hours can be dangerous without medical supervision. Are you sure you want to set this plan?")
            }
        }
    }

    private func savePlan() {
        HapticManager.shared.mediumTap()
        FastingPlan.customHours = hours
        onSave()
        dismiss()
    }
}

#Preview {
    TimerView()
        .modelContainer(for: FastingSession.self, inMemory: true)
        .environment(SubscriptionManager())
        .environment(ThemeManager())
}
