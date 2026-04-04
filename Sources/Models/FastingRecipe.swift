import Foundation

struct FastingRecipe: Identifiable {
    let id: UUID
    let title: String
    let emoji: String
    let category: RecipeCategory
    let prepTime: Int // minutes
    let calories: Int
    let protein: Int // grams
    let description: String
    let ingredients: [String]
    let steps: [String]
    let isPremium: Bool

    init(
        id: UUID = UUID(),
        title: String,
        emoji: String,
        category: RecipeCategory,
        prepTime: Int,
        calories: Int,
        protein: Int,
        description: String,
        ingredients: [String],
        steps: [String],
        isPremium: Bool
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.category = category
        self.prepTime = prepTime
        self.calories = calories
        self.protein = protein
        self.description = description
        self.ingredients = ingredients
        self.steps = steps
        self.isPremium = isPremium
    }

    enum RecipeCategory: String, CaseIterable, Identifiable {
        case breakingFast = "Breaking Fast"
        case meal = "Main Meal"
        case snack = "Snack"
        case drink = "Drink"

        var id: String {
            rawValue
        }

        var icon: String {
            switch self {
            case .breakingFast: "sunrise.fill"
            case .meal: "fork.knife"
            case .snack: "leaf.fill"
            case .drink: "cup.and.saucer.fill"
            }
        }
    }
}
