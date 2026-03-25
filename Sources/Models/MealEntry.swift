import Foundation
import SwiftData

@Model
final class MealEntry {
    var date: Date
    var mealType: String  // breakfast, lunch, dinner, snack
    var title: String     // "Grilled chicken salad"
    var emoji: String     // 🥗
    var note: String?     // optional note
    var isFastingFriendly: Bool

    init(
        date: Date = .now,
        mealType: String,
        title: String,
        emoji: String = "🍽️",
        note: String? = nil,
        isFastingFriendly: Bool = true
    ) {
        self.date = date
        self.mealType = mealType
        self.title = title
        self.emoji = emoji
        self.note = note
        self.isFastingFriendly = isFastingFriendly
    }
}
