import Foundation
import SwiftData

// MARK: - Mood Enum

/// Post-fast mood self-report — emoji-based for quick selection.
/// Stored as raw string in SwiftData for forward compatibility.
enum FastingMood: String, CaseIterable, Identifiable, Codable {
    case tired = "tired"
    case neutral = "neutral"
    case good = "good"
    case great = "great"
    
    var id: String { rawValue }
    
    var emoji: String {
        switch self {
        case .tired: "😴"
        case .neutral: "😐"
        case .good: "😊"
        case .great: "🔥"
        }
    }
    
    var label: String {
        switch self {
        case .tired: "Tired"
        case .neutral: "Okay"
        case .good: "Good"
        case .great: "Energized"
        }
    }
}

// MARK: - Journal Entry Model

/// Post-fast journal entry — mood, energy, and optional notes.
/// Linked to a FastingSession by sessionID (loose coupling — no @Relationship
/// to avoid migration complexity on existing SwiftData schema).
/// Data stays on device (K004).
@Model
final class FastingJournal {
    var id: UUID = UUID()
    var date: Date = Date()
    var sessionID: UUID = UUID()
    var moodRaw: String = "neutral"
    var energy: Int = 3
    var notes: String = ""
    
    init(
        sessionID: UUID,
        mood: FastingMood,
        energy: Int,
        notes: String = ""
    ) {
        self.id = UUID()
        self.date = Date.now
        self.sessionID = sessionID
        self.moodRaw = mood.rawValue
        self.energy = min(max(energy, 1), 5)
        self.notes = String(notes.prefix(500))
    }
    
    /// Typed mood accessor
    var mood: FastingMood {
        get { FastingMood(rawValue: moodRaw) ?? .neutral }
        set { moodRaw = newValue.rawValue }
    }
}
