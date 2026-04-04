import Foundation
import SwiftData

/// Manual weight log entry — stored on device only (K004).
@Model
final class WeightEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    /// Weight in kilograms (UI can convert to lbs for display)
    var weightKg: Double = 0
    var note: String = ""

    init(date: Date = .now, weightKg: Double, note: String = "") {
        id = UUID()
        self.date = date
        self.weightKg = weightKg
        self.note = note
    }

    /// Weight in pounds
    var weightLbs: Double {
        weightKg * 2.20462
    }
}
