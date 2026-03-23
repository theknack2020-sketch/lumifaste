import Foundation

/// Rotating fasting tips shown during an active fast.
/// 30+ tips organized by category with scientific context.
enum FastingTips {
    
    enum Category: String, CaseIterable, Identifiable {
        case science = "Science"
        case hydration = "Hydration"
        case sleep = "Sleep"
        case exercise = "Exercise"
        case mentalClarity = "Mental Clarity"
        case nutrition = "Nutrition"
        case motivation = "Motivation"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .science: "atom"
            case .hydration: "drop.fill"
            case .sleep: "moon.fill"
            case .exercise: "figure.run"
            case .mentalClarity: "brain.head.profile"
            case .nutrition: "leaf.fill"
            case .motivation: "star.fill"
            }
        }
        
        var color: String {
            switch self {
            case .science: "purple"
            case .hydration: "cyan"
            case .sleep: "indigo"
            case .exercise: "green"
            case .mentalClarity: "orange"
            case .nutrition: "mint"
            case .motivation: "yellow"
            }
        }
    }
    
    struct Tip: Identifiable {
        let id: Int
        let emoji: String
        let text: String
        let category: Category
    }
    
    static let tips: [Tip] = [
        // MARK: - Science (8 tips)
        Tip(id: 0, emoji: "🔥", text: "After 12 hours, your body shifts to burning stored fat for energy — a metabolic state called lipolysis.", category: .science),
        Tip(id: 1, emoji: "🧬", text: "Autophagy — cellular cleanup — ramps up significantly after 18–24 hours of fasting. Damaged cells are recycled.", category: .science),
        Tip(id: 2, emoji: "📊", text: "Insulin levels drop significantly after 12 hours, unlocking fat stores for energy.", category: .science),
        Tip(id: 3, emoji: "🫀", text: "Research suggests fasting can improve heart health markers like blood pressure and cholesterol levels.", category: .science),
        Tip(id: 4, emoji: "⚡", text: "Your body produces ketone bodies after 18+ hours, an alternative fuel source preferred by the brain.", category: .science),
        Tip(id: 5, emoji: "🧪", text: "Fasting triggers norepinephrine release, which increases metabolic rate by 3.6–14% in studies.", category: .science),
        Tip(id: 6, emoji: "🔬", text: "Human Growth Hormone can increase up to 5x during fasting, supporting fat loss and muscle preservation.", category: .science),
        Tip(id: 7, emoji: "🧫", text: "Fasting reduces oxidative stress and inflammation — two key drivers of aging and chronic disease.", category: .science),
        
        // MARK: - Hydration (5 tips)
        Tip(id: 8, emoji: "💧", text: "Stay hydrated — water, black coffee, and plain tea are fine during a fast. Aim for 8+ glasses daily.", category: .hydration),
        Tip(id: 9, emoji: "🧂", text: "A pinch of salt in water can help maintain electrolyte balance during longer fasts.", category: .hydration),
        Tip(id: 10, emoji: "🥤", text: "Sparkling water can help with hunger — the carbonation creates a feeling of fullness.", category: .hydration),
        Tip(id: 11, emoji: "☕", text: "Black coffee boosts fat oxidation and mildly suppresses appetite. Keep it under 3 cups to avoid jitters.", category: .hydration),
        Tip(id: 12, emoji: "🍵", text: "Green tea contains catechins that may enhance fat burning during a fast. It also counts toward hydration.", category: .hydration),
        
        // MARK: - Sleep (4 tips)
        Tip(id: 13, emoji: "😴", text: "Quality sleep before a fast makes the next day much easier. Aim for 7–9 hours.", category: .sleep),
        Tip(id: 14, emoji: "🌙", text: "Starting your fast after dinner means you sleep through the hardest hours.", category: .sleep),
        Tip(id: 15, emoji: "🛏️", text: "Avoid eating within 3 hours of bedtime. It improves sleep quality and lets fasting begin sooner.", category: .sleep),
        Tip(id: 16, emoji: "⏰", text: "Your body has a circadian rhythm. Earlier eating windows may have metabolic benefits and improve sleep.", category: .sleep),
        
        // MARK: - Exercise (4 tips)
        Tip(id: 17, emoji: "🚶", text: "Light movement like walking can suppress appetite and boost fat burning during a fast.", category: .exercise),
        Tip(id: 18, emoji: "🏋️", text: "Moderate exercise during a fast is safe for most people. Listen to your body and reduce intensity if needed.", category: .exercise),
        Tip(id: 19, emoji: "🧘", text: "Yoga and stretching are excellent during fasts — they reduce cortisol and improve your fasting experience.", category: .exercise),
        Tip(id: 20, emoji: "💪", text: "Resistance training while fasted can enhance growth hormone response. Just stay well hydrated.", category: .exercise),
        
        // MARK: - Mental Clarity (5 tips)
        Tip(id: 21, emoji: "💡", text: "Many people report sharper mental clarity after 14+ hours of fasting as ketones fuel the brain.", category: .mentalClarity),
        Tip(id: 22, emoji: "🧠", text: "Hunger comes in waves, peaking around 20 minutes then fading. It's ghrelin — a hormone, not true starvation.", category: .mentalClarity),
        Tip(id: 23, emoji: "🧘", text: "Mindfulness during fasting helps distinguish true hunger from boredom or habit-based eating.", category: .mentalClarity),
        Tip(id: 24, emoji: "🫁", text: "Deep breathing exercises can help manage hunger pangs and reduce stress during fasting.", category: .mentalClarity),
        Tip(id: 25, emoji: "📱", text: "Distraction works. Stay busy with work, hobbies, or socializing — hours fly by during a fast.", category: .mentalClarity),
        
        // MARK: - Nutrition (4 tips)
        Tip(id: 26, emoji: "🍽️", text: "Break your fast gently — start with something light like soup, nuts, or fruit. Avoid heavy meals.", category: .nutrition),
        Tip(id: 27, emoji: "🥗", text: "Focus on nutrient-dense foods in your eating window: proteins, healthy fats, vegetables, and whole grains.", category: .nutrition),
        Tip(id: 28, emoji: "🥚", text: "Include protein in your first meal after fasting — it helps preserve muscle mass and keeps you full longer.", category: .nutrition),
        Tip(id: 29, emoji: "🫐", text: "Antioxidant-rich foods like berries and leafy greens complement the cellular repair benefits of fasting.", category: .nutrition),
        
        // MARK: - Motivation (5 tips)
        Tip(id: 30, emoji: "🎯", text: "Set your intention before each fast. Knowing your 'why' makes it easier to push through.", category: .motivation),
        Tip(id: 31, emoji: "💪", text: "Consistency matters more than duration. A shorter fast you complete beats one you abandon.", category: .motivation),
        Tip(id: 32, emoji: "📈", text: "Track your progress. Research shows that self-monitoring is the #1 predictor of health behavior change.", category: .motivation),
        Tip(id: 33, emoji: "🏆", text: "Every fast gets easier. Your body adapts to fasting within 2–4 weeks as metabolic flexibility improves.", category: .motivation),
        Tip(id: 34, emoji: "🌟", text: "You're doing something extraordinary — only 10% of adults practice regular intermittent fasting.", category: .motivation),
    ]
    
    /// All tips for a given category
    static func tips(for category: Category) -> [Tip] {
        tips.filter { $0.category == category }
    }
    
    /// Returns a tip that rotates every 60 seconds based on elapsed seconds (for 'Did you know?' card).
    static func didYouKnow(forElapsed elapsed: TimeInterval) -> Tip {
        let index = Int(elapsed / 60) % tips.count
        return tips[index]
    }
    
    /// Returns a tip that rotates every 10 minutes based on elapsed seconds (for tip bar).
    static func tip(forElapsed elapsed: TimeInterval) -> Tip {
        let index = Int(elapsed / 600) % tips.count
        return tips[index]
    }
    
    /// Returns a random tip for the day
    static func dailyTip() -> Tip {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        return tips[day % tips.count]
    }
    
    /// Returns tips relevant to the current fasting stage
    static func stageTips(for stage: FastingStage) -> [Tip] {
        switch stage {
        case .fed:
            return tips.filter { $0.category == .nutrition || $0.category == .motivation }
        case .earlyFasting:
            return tips.filter { $0.category == .hydration || $0.category == .mentalClarity }
        case .fatBurning:
            return tips.filter { $0.category == .exercise || $0.category == .science }
        case .ketosis:
            return tips.filter { $0.category == .science || $0.category == .mentalClarity }
        case .autophagy:
            return tips.filter { $0.category == .science || $0.category == .motivation }
        }
    }
}
