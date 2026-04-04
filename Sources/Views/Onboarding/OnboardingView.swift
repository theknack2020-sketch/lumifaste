import AudioToolbox
import SwiftUI

// MARK: - OnboardingView

/// Premium 6-page onboarding — personalized quiz → plan recommendation → notifications → launch.
/// Dark-themed with distinct green-progression gradients per page, capsule page dots,
/// haptic feedback on every interaction, and polished entrance animations.
struct OnboardingView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    @Binding var hasCompletedOnboarding: Bool

    // MARK: - State

    @State private var currentPage = 0
    @State private var selectedGoal: FastingGoal = .weightLoss
    @State private var selectedExperience: ExperienceLevel = .beginner
    @State private var notificationDenied = false
    @State private var showTrialPaywall = false

    // Animation triggers
    @State private var heroGlowPulse = false
    @State private var bellBounce = 0
    @State private var checkmarkScale: CGFloat = 0.2
    @State private var readyContentOpacity: Double = 0

    private let totalPages = 6

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                goalPage.tag(1)
                experiencePage.tag(2)
                planPreviewPage.tag(3)
                notificationPage.tag(4)
                getStartedPage.tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .interactiveDismissDisabled()
            .onChange(of: currentPage) { _, newPage in
                HapticManager.shared.selectionChanged()
                if newPage == 4 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        bellBounce += 1
                    }
                }
                if newPage == 5 {
                    triggerReadyAnimations()
                }
            }

            // Skip button — top-right, visible on pages 0–4
            if currentPage < totalPages - 1 {
                HStack {
                    Spacer()
                    Button {
                        HapticManager.shared.lightTap()
                        saveAllSelections()
                        withAnimation(.smoothSpring) { currentPage = totalPages - 1 }
                    } label: {
                        Text("Skip")
                            .font(.adaptiveSubheadline(isRegular: isRegular).weight(.medium))
                            .foregroundStyle(.white.opacity(0.55))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(.white.opacity(0.07)))
                    }
                    .buttonStyle(.pressable)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .transition(.opacity)
                .animation(.smooth(duration: 0.2), value: currentPage)
            }
        }
        .preferredColorScheme(.dark)
    }

    // =========================================================================
    // MARK: - Page 1: Welcome Hero

    // =========================================================================

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()

            // Leaf icon with pulsing radial glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                themeManager.selectedTheme.accent.opacity(0.4),
                                themeManager.selectedTheme.accent.opacity(0.12),
                                .clear,
                            ],
                            center: .center,
                            startRadius: 12,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(heroGlowPulse ? 1.2 : 0.85)
                    .opacity(heroGlowPulse ? 0.9 : 0.35)

                Image(systemName: "leaf.fill")
                    .font(.adaptiveDisplay(size: 72, weight: .regular, design: .default, isRegular: isRegular))
                    .scaleEffect(x: -1, y: 1)
                    .foregroundStyle(themeManager.selectedTheme.accentGradient)
                    .shadow(color: themeManager.selectedTheme.accent.opacity(0.5), radius: 24)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    heroGlowPulse = true
                }
            }
            .slideIn(from: .bottom, delay: 0.1)

            Spacer().frame(height: 28)

            Text("Lumifaste")
                .font(.adaptiveDisplay(size: 42, weight: .bold, design: .rounded, isRegular: isRegular))
                .foregroundStyle(.white)
                .slideIn(from: .bottom, delay: 0.25)

            Text("Your honest fasting companion")
                .font(.adaptiveBody(isRegular: isRegular))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, 4)
                .slideIn(from: .bottom, delay: 0.35)

            Spacer().frame(height: 36)

            // 3 benefit bullets
            VStack(alignment: .leading, spacing: 16) {
                OnboardingBenefitRow(icon: "timer", color: .cyan, text: "Smart timer for every stage")
                OnboardingBenefitRow(icon: "hand.raised.fill", color: .green, text: "Zero ads — your focus")
                OnboardingBenefitRow(icon: "lock.shield.fill", color: .purple, text: "All data stays private")
            }
            .padding(20)
            .background(onboardingGlassCard)
            .entranceAnimation(delay: 0.5)

            Spacer()

            onboardingPrimaryButton("Get Started") { advancePage() }

            capsulePageIndicator
                .padding(.top, 20)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
        .background(pageGradient(for: 0))
    }

    // =========================================================================
    // MARK: - Page 2: Goal Quiz

    // =========================================================================

    private var goalPage: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 64)

            Text("What's your fasting goal?")
                .font(.adaptiveDisplay(size: 28, weight: .bold, design: .rounded, isRegular: isRegular))
                .multilineTextAlignment(.center)
                .slideIn(from: .trailing, delay: 0.1)

            Text("This helps us personalize your experience")
                .font(.adaptiveSubheadline(isRegular: isRegular))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 6)
                .slideIn(from: .trailing, delay: 0.2)

            Spacer().frame(height: 32)

            VStack(spacing: 12) {
                ForEach(Array(FastingGoal.allCases.enumerated()), id: \.element.id) { index, goal in
                    OnboardingGoalCard(
                        goal: goal,
                        isSelected: selectedGoal == goal,
                        accent: themeManager.selectedTheme.accent
                    ) {
                        HapticManager.shared.selectionChanged()
                        withAnimation(.tapSpring) { selectedGoal = goal }
                    }
                    .staggeredAppear(index: index)
                }
            }

            Spacer()

            onboardingPrimaryButton("Continue") {
                UserDefaults.standard.set(selectedGoal.rawValue, forKey: "lf_fasting_goal")
                advancePage()
            }

            capsulePageIndicator
                .padding(.top, 20)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
        .background(pageGradient(for: 1))
    }

    // =========================================================================
    // MARK: - Page 3: Experience Level

    // =========================================================================

    private var experiencePage: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 64)

            Text("Your fasting experience?")
                .font(.adaptiveDisplay(size: 28, weight: .bold, design: .rounded, isRegular: isRegular))
                .multilineTextAlignment(.center)
                .slideIn(from: .trailing, delay: 0.1)

            Text("We'll recommend the right plan for you")
                .font(.adaptiveSubheadline(isRegular: isRegular))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 6)
                .slideIn(from: .trailing, delay: 0.2)

            Spacer().frame(height: 32)

            VStack(spacing: 12) {
                ForEach(Array(ExperienceLevel.allCases.enumerated()), id: \.element.id) { index, level in
                    OnboardingExperienceCard(
                        level: level,
                        isSelected: selectedExperience == level,
                        accent: themeManager.selectedTheme.accent,
                        recommendedPlan: level.recommendedPlan
                    ) {
                        HapticManager.shared.selectionChanged()
                        withAnimation(.tapSpring) { selectedExperience = level }
                    }
                    .staggeredAppear(index: index)
                }
            }

            Spacer()

            onboardingPrimaryButton("Continue") {
                UserDefaults.standard.set(selectedExperience.rawValue, forKey: "lf_experience_level")
                advancePage()
            }

            capsulePageIndicator
                .padding(.top, 20)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
        .background(pageGradient(for: 2))
    }

    // =========================================================================
    // MARK: - Page 4: Plan Preview

    // =========================================================================

    private var planPreviewPage: some View {
        let plan = recommendedPlan

        return VStack(spacing: 0) {
            Spacer().frame(height: 64)

            Text("Your recommended plan")
                .font(.adaptiveDisplay(size: 28, weight: .bold, design: .rounded, isRegular: isRegular))
                .slideIn(from: .trailing, delay: 0.1)

            Text("Based on your goals and experience")
                .font(.adaptiveSubheadline(isRegular: isRegular))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 6)
                .slideIn(from: .trailing, delay: 0.2)

            Spacer().frame(height: 36)

            // Mini timer ring visualization
            planTimerRing(plan: plan)
                .entranceAnimation(delay: 0.3)

            Spacer().frame(height: 28)

            // Plan details card
            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.adaptiveSubheadline(isRegular: isRegular))
                        .foregroundStyle(themeManager.selectedTheme.accent)
                    Text("You'll fast for **\(Int(plan.fastingHours)) hours**")
                        .font(.adaptiveSubheadline(isRegular: isRegular))
                }

                HStack(spacing: 8) {
                    Image(systemName: "fork.knife")
                        .font(.adaptiveSubheadline(isRegular: isRegular))
                        .foregroundStyle(.orange)
                    Text("Eat in an **\(Int(plan.eatingHours))-hour** window")
                        .font(.adaptiveSubheadline(isRegular: isRegular))
                }

                Divider().overlay(Color.white.opacity(0.08))

                Text("You can change your plan anytime in Settings")
                    .font(.adaptiveDetail(isRegular: isRegular))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(onboardingGlassCard)
            .entranceAnimation(delay: 0.45)

            Spacer()

            onboardingPrimaryButton("Looks Good") {
                UserDefaults.standard.set(plan.rawValue, forKey: "lf_fasting_plan")
                advancePage()
            }

            capsulePageIndicator
                .padding(.top, 20)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
        .background(pageGradient(for: 3))
    }

    // =========================================================================
    // MARK: - Page 5: Notifications

    // =========================================================================

    private var notificationPage: some View {
        VStack(spacing: 0) {
            Spacer()

            // Bell with radial glow and bounce
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.blue.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 65
                        )
                    )
                    .frame(width: 130, height: 130)

                Image(systemName: "bell.badge.fill")
                    .font(.adaptiveDisplay(size: 56, weight: .regular, design: .default, isRegular: isRegular))
                    .foregroundStyle(themeManager.selectedTheme.accentGradient)
                    .symbolEffect(.bounce, value: bellBounce)
            }
            .slideIn(from: .bottom, delay: 0.1)

            Spacer().frame(height: 24)

            Text("Never miss a milestone")
                .font(.adaptiveDisplay(size: 28, weight: .bold, design: .rounded, isRegular: isRegular))
                .slideIn(from: .trailing, delay: 0.25)

            Text("Stay motivated with timely updates")
                .font(.adaptiveSubheadline(isRegular: isRegular))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 6)
                .slideIn(from: .trailing, delay: 0.35)

            Spacer().frame(height: 28)

            // Notification benefits
            VStack(alignment: .leading, spacing: 16) {
                OnboardingBenefitRow(icon: "flag.checkered", color: .green, text: "Stage alerts as you progress")
                OnboardingBenefitRow(icon: "bell.fill", color: .cyan, text: "Daily reminders to stay consistent")
                OnboardingBenefitRow(icon: "flame.fill", color: .orange, text: "Streak protection so you never miss")
            }
            .padding(20)
            .background(onboardingGlassCard)
            .entranceAnimation(delay: 0.45)

            // Inline denial message
            if notificationDenied {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.adaptiveDetail(isRegular: isRegular))
                        .foregroundStyle(.orange)
                    Text("No worries — enable anytime in Settings.")
                        .font(.adaptiveDetail(isRegular: isRegular))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.orange.opacity(0.12))
                )
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()

            onboardingPrimaryButton("Enable Notifications") {
                HapticManager.shared.mediumTap()
                Task {
                    let granted = await NotificationManager.shared.requestPermission()
                    if granted {
                        NotificationManager.shared.scheduleDailyReminder()
                        advancePage()
                    } else {
                        withAnimation(.smoothSpring) { notificationDenied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            advancePage()
                        }
                    }
                }
            }

            onboardingSecondaryButton("Maybe Later") { advancePage() }

            capsulePageIndicator
                .padding(.top, 12)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
        .background(pageGradient(for: 4))
    }

    // =========================================================================
    // MARK: - Page 6: Get Started

    // =========================================================================

    private var getStartedPage: some View {
        VStack(spacing: 0) {
            Spacer()

            // Checkmark with spring scale
            Image(systemName: "checkmark.circle.fill")
                .font(.adaptiveDisplay(size: 80, weight: .regular, design: .default, isRegular: isRegular))
                .foregroundStyle(.green)
                .scaleEffect(checkmarkScale)
                .shadow(color: .green.opacity(0.45), radius: 24)

            Spacer().frame(height: 24)

            Text("You're Ready!")
                .font(.adaptiveDisplay(size: 34, weight: .bold, design: .rounded, isRegular: isRegular))
                .opacity(readyContentOpacity)

            Spacer().frame(height: 16)

            // Selection summary
            VStack(spacing: 10) {
                onboardingSummaryRow(icon: "star.fill", color: .yellow, label: "Goal", value: selectedGoal.rawValue)
                onboardingSummaryRow(icon: "chart.bar.fill", color: .cyan, label: "Level", value: selectedExperience.rawValue)
                onboardingSummaryRow(icon: "timer", color: themeManager.selectedTheme.accent, label: "Plan", value: "\(recommendedPlan.rawValue) — \(Int(recommendedPlan.fastingHours))h fast")
            }
            .padding(20)
            .background(onboardingGlassCard)
            .opacity(readyContentOpacity)

            Spacer()

            // Health disclaimer
            HStack(spacing: 8) {
                Image(systemName: "heart.text.square.fill")
                    .font(.adaptiveDetail(isRegular: isRegular))
                    .foregroundStyle(.red.opacity(0.7))
                Text("Consult your doctor before starting any fasting program.")
                    .font(.adaptiveCaption(isRegular: isRegular))
                    .foregroundStyle(.white.opacity(0.4))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.white.opacity(0.04))
            )
            .opacity(readyContentOpacity)
            .accessibilityLabel("Health disclaimer: Consult your doctor before starting any fasting program.")
            .accessibilityIdentifier("onboardingHealthDisclaimer")

            onboardingPrimaryButton("Start Your First Fast") {
                completeOnboarding()
            }

            // Free trial CTA — secondary action below primary
            Button {
                HapticManager.shared.lightTap()
                showTrialPaywall = true
            } label: {
                VStack(spacing: 3) {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.adaptiveCaption(isRegular: isRegular))
                        Text("Start with 7-day free trial")
                            .font(.adaptiveSubheadline(isRegular: isRegular).weight(.medium))
                    }
                    .foregroundStyle(themeManager.selectedTheme.accent)

                    Text("Full access to all Pro features for 7 days, cancel anytime")
                        .font(.adaptiveBadge(isRegular: isRegular))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.vertical, 10)
            }
            .buttonStyle(.pressable)
            .opacity(readyContentOpacity)

            onboardingSecondaryButton("Explore First") {
                completeOnboarding()
            }

            capsulePageIndicator
                .padding(.top, 12)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
        .background(pageGradient(for: 5))
        .fullScreenCover(isPresented: $showTrialPaywall) {
            PaywallView()
        }
    }

    // =========================================================================
    // MARK: - Shared Components

    // =========================================================================

    private var capsulePageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.white : Color.white.opacity(0.25))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(duration: 0.35, bounce: 0.3), value: currentPage)
            }
        }
    }

    private func planTimerRing(plan: FastingPlan) -> some View {
        let ratio = plan.fastingHours / 24.0

        return ZStack {
            // Outer ambient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [themeManager.selectedTheme.accent.opacity(0.12), .clear],
                        center: .center,
                        startRadius: 65,
                        endRadius: 130
                    )
                )
                .frame(width: 260, height: 260)

            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: 18)

            // Fasting arc
            Circle()
                .trim(from: 0, to: ratio)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            themeManager.selectedTheme.accent.opacity(0.4),
                            themeManager.selectedTheme.accent.opacity(0.8),
                            themeManager.selectedTheme.accent,
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * ratio)
                    ),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: themeManager.selectedTheme.accent.opacity(0.5), radius: 14)

            // Bright dot at arc tip
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, themeManager.selectedTheme.accent],
                        center: .center,
                        startRadius: 0,
                        endRadius: 8
                    )
                )
                .frame(width: 10, height: 10)
                .shadow(color: themeManager.selectedTheme.accent.opacity(0.8), radius: 8)
                .offset(y: -90)
                .rotationEffect(.degrees(360 * ratio - 90))

            // Center label
            VStack(spacing: 6) {
                Text(plan.rawValue)
                    .font(.adaptiveDisplay(size: 38, weight: .bold, design: .rounded, isRegular: isRegular))

                Text("\(Int(plan.fastingHours))h fasting · \(Int(plan.eatingHours))h eating")
                    .font(.adaptiveDetail(isRegular: isRegular))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(width: 200, height: 200)
    }

    /// Glass-morphism card background
    private var onboardingGlassCard: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
    }

    private func onboardingPrimaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.adaptiveBody(isRegular: isRegular).weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(themeManager.selectedTheme.accentGradient)
                )
                .shadow(color: themeManager.selectedTheme.accent.opacity(0.4), radius: 14, y: 6)
        }
        .buttonStyle(.pressable)
    }

    private func onboardingSecondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.shared.lightTap()
            action()
        } label: {
            Text(title)
                .font(.adaptiveSubheadline(isRegular: isRegular).weight(.medium))
                .foregroundStyle(.white.opacity(0.45))
                .padding(.vertical, 10)
        }
        .buttonStyle(.pressable)
    }

    private func onboardingSummaryRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.adaptiveSubheadline(isRegular: isRegular))
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(.adaptiveDetail(isRegular: isRegular))
                .foregroundStyle(.white.opacity(0.45))
                .frame(width: 44, alignment: .leading)

            Text(value)
                .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))
                .foregroundStyle(.white)

            Spacer()
        }
    }

    // =========================================================================
    // MARK: - Page Gradients

    // =========================================================================

    /// Distinct dark gradient per page — green progression: dark forest → emerald → teal → mint → blue-green → bright
    private func pageGradient(for page: Int) -> some View {
        let colors: [Color] = switch page {
        case 0: [Color(red: 0.03, green: 0.14, blue: 0.06), .black]
        case 1: [Color(red: 0.04, green: 0.19, blue: 0.10), Color(red: 0.01, green: 0.05, blue: 0.03)]
        case 2: [Color(red: 0.03, green: 0.17, blue: 0.17), Color(red: 0.01, green: 0.04, blue: 0.04)]
        case 3: [Color(red: 0.04, green: 0.21, blue: 0.14), Color(red: 0.01, green: 0.06, blue: 0.04)]
        case 4: [Color(red: 0.03, green: 0.12, blue: 0.21), Color(red: 0.01, green: 0.03, blue: 0.06)]
        default: [Color(red: 0.06, green: 0.24, blue: 0.12), Color(red: 0.02, green: 0.07, blue: 0.04)]
        }

        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }

    // =========================================================================
    // MARK: - Logic

    // =========================================================================

    private var recommendedPlan: FastingPlan {
        selectedExperience.recommendedPlan
    }

    private func advancePage() {
        HapticManager.shared.selectionChanged()
        withAnimation(.smoothSpring) {
            currentPage = min(currentPage + 1, totalPages - 1)
        }
    }

    private func triggerReadyAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.45)) {
            checkmarkScale = 1.0
        }
        withAnimation(.smooth(duration: 0.5).delay(0.3)) {
            readyContentOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            HapticManager.shared.success()
        }
    }

    private func saveAllSelections() {
        UserDefaults.standard.set(selectedGoal.rawValue, forKey: "lf_fasting_goal")
        UserDefaults.standard.set(selectedExperience.rawValue, forKey: "lf_experience_level")
        UserDefaults.standard.set(recommendedPlan.rawValue, forKey: "lf_fasting_plan")
    }

    private func completeOnboarding() {
        HapticManager.shared.fastCompleted()
        saveAllSelections()
        UserDefaults.standard.set(true, forKey: "lf_onboarding_complete")
        withAnimation(.smoothSpring) {
            hasCompletedOnboarding = true
        }
    }
}

// =============================================================================
// MARK: - Fasting Goal

// =============================================================================

enum FastingGoal: String, CaseIterable, Identifiable {
    case weightLoss = "Weight Loss"
    case health = "Health"
    case mentalClarity = "Mental Clarity"
    case longevity = "Longevity"

    var id: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .weightLoss: "scalemass"
        case .health: "heart.fill"
        case .mentalClarity: "brain.head.profile"
        case .longevity: "figure.walk"
        }
    }

    var subtitle: String {
        switch self {
        case .weightLoss: "Burn fat and reach your target weight"
        case .health: "Improve metabolic health and energy"
        case .mentalClarity: "Sharpen focus and mental performance"
        case .longevity: "Activate cellular repair and renewal"
        }
    }
}

// =============================================================================
// MARK: - Experience Level

// =============================================================================

enum ExperienceLevel: String, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case experienced = "Experienced"

    var id: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .beginner: "leaf"
        case .intermediate: "leaf.fill"
        case .experienced: "tree.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .beginner: "New to fasting — start easy"
        case .intermediate: "Some experience with fasting"
        case .experienced: "Regularly fast and want a challenge"
        }
    }

    var recommendedPlan: FastingPlan {
        switch self {
        case .beginner: .twelveTwelve
        case .intermediate: .sixteenEight
        case .experienced: .eighteenSix
        }
    }
}

// =============================================================================
// MARK: - Goal Card

// =============================================================================

private struct OnboardingGoalCard: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    let goal: FastingGoal
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? accent.opacity(0.15) : Color.white.opacity(0.05))
                        .frame(width: 44, height: 44)

                    Image(systemName: goal.icon)
                        .font(.adaptiveTitle3(isRegular: isRegular))
                        .foregroundStyle(isSelected ? accent : .white.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.rawValue)
                        .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))
                        .foregroundStyle(.white)
                    Text(goal.subtitle)
                        .font(.adaptiveDetail(isRegular: isRegular))
                        .foregroundStyle(.white.opacity(0.45))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.adaptiveTitle3(isRegular: isRegular))
                    .foregroundStyle(isSelected ? accent : .white.opacity(0.2))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(isSelected ? 0.07 : 0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? accent : .white.opacity(0.06), lineWidth: isSelected ? 1.5 : 0.5)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.tapSpring, value: isSelected)
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(goal.rawValue). \(goal.subtitle)\(isSelected ? ". Selected" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// =============================================================================
// MARK: - Experience Card

// =============================================================================

private struct OnboardingExperienceCard: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    let level: ExperienceLevel
    let isSelected: Bool
    let accent: Color
    let recommendedPlan: FastingPlan
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? accent.opacity(0.15) : Color.white.opacity(0.05))
                        .frame(width: 44, height: 44)

                    Image(systemName: level.icon)
                        .font(.adaptiveTitle3(isRegular: isRegular))
                        .foregroundStyle(isSelected ? accent : .white.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(level.rawValue)
                        .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))
                        .foregroundStyle(.white)
                    Text(level.subtitle)
                        .font(.adaptiveDetail(isRegular: isRegular))
                        .foregroundStyle(.white.opacity(0.45))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(recommendedPlan.rawValue)
                        .font(.adaptiveCaption(isRegular: isRegular).weight(.bold))
                        .foregroundStyle(isSelected ? accent : .white.opacity(0.35))
                    Text("plan")
                        .font(.adaptiveCaption(isRegular: isRegular))
                        .foregroundStyle(.white.opacity(0.25))
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.adaptiveTitle3(isRegular: isRegular))
                    .foregroundStyle(isSelected ? accent : .white.opacity(0.2))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(isSelected ? 0.07 : 0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? accent : .white.opacity(0.06), lineWidth: isSelected ? 1.5 : 0.5)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.tapSpring, value: isSelected)
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(level.rawValue). \(level.subtitle). Recommended plan: \(recommendedPlan.rawValue)\(isSelected ? ". Selected" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// =============================================================================
// MARK: - Benefit Row

// =============================================================================

private struct OnboardingBenefitRow: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.adaptiveSubheadline(isRegular: isRegular))
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(.adaptiveSubheadline(isRegular: isRegular))
                .foregroundStyle(.white.opacity(0.85))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

// =============================================================================
// MARK: - Preview

// =============================================================================

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environment(ThemeManager())
}
