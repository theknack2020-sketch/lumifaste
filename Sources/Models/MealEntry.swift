import Foundation
import SwiftData

@Model
final class MealEntry {
    var date: Date = Date.now
    var mealType: String = "meal"
    var title: String = ""
    var emoji: String = "🍽️"
    var note: String?
    var isFastingFriendly: Bool = true

    init(
        date: Date = .now,
        mealType: String = "meal",
        title: String = "",
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
