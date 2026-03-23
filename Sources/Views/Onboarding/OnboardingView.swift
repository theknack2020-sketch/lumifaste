import SwiftUI

/// İlk açılış onboarding akışı — plan seçimi, hedef belirleme, izin istekleri.
/// Entrance animations on each page, bounce button style, spring transitions.
struct OnboardingView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var currentPage = 0
    @State private var selectedPlan: FastingPlan = .sixteenEight
    @State private var selectedGoal: FastingGoal = .weightLoss
    @Binding var hasCompletedOnboarding: Bool
    
    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1: Welcome
            welcomePage
                .tag(0)
            
            // Page 2: Goal
            goalPage
                .tag(1)
            
            // Page 3: Plan
            planPage
                .tag(2)
            
            // Page 4: Notifications
            notificationPage
                .tag(3)
            
            // Page 5: Ready
            readyPage
                .tag(4)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .interactiveDismissDisabled()
    }
    
    // MARK: - Welcome
    
    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "leaf.fill")
                .font(.system(size: 64))
                .scaleEffect(x: -1, y: 1)
                .foregroundStyle(themeManager.selectedTheme.accentGradient)
                .entranceAnimation(delay: 0.2)
            
            Text("Welcome to Lumifaste")
                .font(.system(size: 28, weight: .bold))
                .entranceAnimation(delay: 0.35)
            
            Text("Your honest fasting companion.\nNo ads. No tricks. Just results.")
                .font(.system(size: 17))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .entranceAnimation(delay: 0.45)
            
            Spacer()
            
            nextButton("Get Started") {
                withAnimation(.smoothSpring) { currentPage = 1 }
            }
        }
        .padding(24)
    }
    
    // MARK: - Goal Selection
    
    private var goalPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("What's your goal?")
                .font(.system(size: 26, weight: .bold))
            
            Text("This helps us recommend the right plan")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                ForEach(Array(FastingGoal.allCases.enumerated()), id: \.element.id) { index, goal in
                    GoalCard(
                        goal: goal,
                        isSelected: selectedGoal == goal
                    ) {
                        HapticManager.shared.selectionChanged()
                        withAnimation(.tapSpring) {
                            selectedGoal = goal
                        }
                    }
                    .staggeredAppear(index: index)
                }
            }
            .padding(.top, 8)
            
            Spacer()
            
            nextButton("Continue") {
                withAnimation(.smoothSpring) { currentPage = 2 }
            }
        }
        .padding(24)
    }
    
    // MARK: - Plan Selection
    
    private var planPage: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 20)
            
            Text("Choose your plan")
                .font(.system(size: 26, weight: .bold))
            
            Text("You can change this anytime")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(FastingPlan.allCases.filter { $0 != .custom && $0 != .fiveTwo }.enumerated()), id: \.element.id) { index, plan in
                        PlanCard(
                            plan: plan,
                            isSelected: selectedPlan == plan,
                            isRecommended: recommendedPlan == plan
                        ) {
                            HapticManager.shared.selectionChanged()
                            withAnimation(.tapSpring) {
                                selectedPlan = plan
                            }
                        }
                        .staggeredAppear(index: index)
                    }
                }
            }
            
            nextButton("Continue") {
                withAnimation(.smoothSpring) { currentPage = 3 }
            }
        }
        .padding(24)
    }
    
    // MARK: - Notifications
    
    private var notificationPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(themeManager.selectedTheme.accentGradient)
            }
            .entranceAnimation(delay: 0.2)
            
            Text("Stay on Track")
                .font(.system(size: 26, weight: .bold))
                .entranceAnimation(delay: 0.35)
            
            Text("Get notified when you hit milestones,\nenter new fasting stages, and reach your goal")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .entranceAnimation(delay: 0.45)
            
            VStack(alignment: .leading, spacing: 12) {
                notifBenefit(icon: "flag.checkered", color: .green, text: "Milestone alerts at 25%, 50%, 75%")
                notifBenefit(icon: "flame.fill", color: .orange, text: "Fat Burning & Ketosis stage alerts")
                notifBenefit(icon: "trophy.fill", color: .yellow, text: "Celebration when you reach your goal")
                notifBenefit(icon: "bolt.fill", color: .purple, text: "Streak reminders to stay consistent")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            
            Spacer()
            
            nextButton("Enable Notifications") {
                Task {
                    _ = await NotificationManager.shared.requestPermission()
                    NotificationManager.shared.scheduleDailyReminder()
                    withAnimation(.smoothSpring) { currentPage = 4 }
                }
            }
            
            Button("Skip for Now") {
                withAnimation(.smoothSpring) { currentPage = 4 }
            }
            .font(.system(size: 15))
            .foregroundStyle(.secondary)
        }
        .padding(24)
    }
    
    private func notifBenefit(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 14))
        }
    }
    
    // MARK: - Ready
    
    private var readyPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
                .entranceAnimation(delay: 0.2)
            
            Text("You're all set!")
                .font(.system(size: 28, weight: .bold))
                .entranceAnimation(delay: 0.35)
            
            VStack(spacing: 8) {
                Text("Your plan: **\(selectedPlan.rawValue)**")
                Text("\(Int(selectedPlan.fastingHours))h fasting · \(Int(selectedPlan.eatingHours))h eating")
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 17))
            .entranceAnimation(delay: 0.45)
            
            Spacer()
            
            nextButton("Start Fasting") {
                HapticManager.shared.fastStarted()
                // Save selections
                UserDefaults.standard.set(selectedPlan.rawValue, forKey: "lf_fasting_plan")
                UserDefaults.standard.set(selectedGoal.rawValue, forKey: "lf_fasting_goal")
                withAnimation(.smoothSpring) {
                    hasCompletedOnboarding = true
                }
            }
        }
        .padding(24)
    }
    
    // MARK: - Helpers
    
    private var recommendedPlan: FastingPlan {
        switch selectedGoal {
        case .weightLoss: .sixteenEight
        case .metabolicHealth: .sixteenEight
        case .mentalClarity: .eighteenSix
        case .longevity: .twentyFour
        case .general: .fourteenTen
        }
    }
    
    private func nextButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.accentColor)
                )
        }
        .buttonStyle(.bounce)
    }
}

// MARK: - Fasting Goal

enum FastingGoal: String, CaseIterable, Identifiable {
    case weightLoss = "Weight Loss"
    case metabolicHealth = "Metabolic Health"
    case mentalClarity = "Mental Clarity"
    case longevity = "Longevity"
    case general = "General Wellness"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .weightLoss: "scalemass"
        case .metabolicHealth: "heart.fill"
        case .mentalClarity: "brain.head.profile"
        case .longevity: "leaf.fill"
        case .general: "figure.walk"
        }
    }
    
    var subtitle: String {
        switch self {
        case .weightLoss: "Burn fat and lose weight"
        case .metabolicHealth: "Improve insulin sensitivity"
        case .mentalClarity: "Sharpen focus and energy"
        case .longevity: "Cellular repair and renewal"
        case .general: "Feel better every day"
        }
    }
}

// MARK: - Goal Card

private struct GoalCard: View {
    let goal: FastingGoal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: goal.icon)
                    .font(.system(size: 20))
                    .scaleEffect(x: goal.icon == "leaf.fill" ? -1 : 1)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                    Text(goal.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .animation(.tapSpring, value: isSelected)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
            )
            .animation(.tapSpring, value: isSelected)
        }
        .buttonStyle(.bounce)
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let plan: FastingPlan
    let isSelected: Bool
    let isRecommended: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.rawValue)
                            .font(.system(size: 17, weight: .bold))
                        
                        if isRecommended {
                            Text("RECOMMENDED")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.accentColor))
                        }
                    }
                    
                    Text(plan.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    
                    // Difficulty dots
                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { level in
                            Circle()
                                .fill(level <= plan.difficulty ? Color.accentColor : Color(.systemGray4))
                                .frame(width: 6, height: 6)
                        }
                        Text("Difficulty")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .animation(.tapSpring, value: isSelected)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
            )
            .animation(.tapSpring, value: isSelected)
        }
        .buttonStyle(.bounce)
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environment(ThemeManager())
}
