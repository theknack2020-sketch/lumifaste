import SwiftUI

/// İlk açılış onboarding akışı — plan seçimi, hedef belirleme, izin istekleri.
struct OnboardingView: View {
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
            
            // Page 4: Ready
            readyPage
                .tag(3)
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
                .foregroundStyle(
                    .linearGradient(
                        colors: [Color(red: 0.46, green: 0.44, blue: 0.78), .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Welcome to Lumifaste")
                .font(.system(size: 28, weight: .bold))
            
            Text("Your honest fasting companion.\nNo ads. No tricks. Just results.")
                .font(.system(size: 17))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            nextButton("Get Started") {
                withAnimation { currentPage = 1 }
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
                ForEach(FastingGoal.allCases) { goal in
                    GoalCard(
                        goal: goal,
                        isSelected: selectedGoal == goal
                    ) {
                        selectedGoal = goal
                    }
                }
            }
            .padding(.top, 8)
            
            Spacer()
            
            nextButton("Continue") {
                withAnimation { currentPage = 2 }
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
                    ForEach(FastingPlan.allCases.filter { $0 != .custom && $0 != .fiveTwo }) { plan in
                        PlanCard(
                            plan: plan,
                            isSelected: selectedPlan == plan,
                            isRecommended: recommendedPlan == plan
                        ) {
                            selectedPlan = plan
                        }
                    }
                }
            }
            
            nextButton("Continue") {
                withAnimation { currentPage = 3 }
            }
        }
        .padding(24)
    }
    
    // MARK: - Ready
    
    private var readyPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            
            Text("You're all set!")
                .font(.system(size: 28, weight: .bold))
            
            VStack(spacing: 8) {
                Text("Your plan: **\(selectedPlan.rawValue)**")
                Text("\(Int(selectedPlan.fastingHours))h fasting · \(Int(selectedPlan.eatingHours))h eating")
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 17))
            
            Spacer()
            
            nextButton("Start Fasting") {
                // Save selections
                UserDefaults.standard.set(selectedPlan.rawValue, forKey: "lf_fasting_plan")
                UserDefaults.standard.set(selectedGoal.rawValue, forKey: "lf_fasting_goal")
                hasCompletedOnboarding = true
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
        }
        .buttonStyle(.plain)
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
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
