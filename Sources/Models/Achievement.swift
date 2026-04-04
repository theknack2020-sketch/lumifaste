import Foundation
import SwiftUI

/// Achievement definitions — unlocked via fasting milestones.
/// Stored in UserDefaults with earned dates (K004: data stays on device).
enum Achievement: String, CaseIterable, Identifiable, Codable {
    case firstFast = "first_fast"
    case threeDayStreak = "three_day_streak"
    case sevenDayStreak = "seven_day_streak"
    case thirtyDayStreak = "thirty_day_streak"
    case warrior24h = "warrior_24h"
    case centurion100h = "centurion_100h"
    case tenFasts = "ten_fasts"
    case twentyFiveFasts = "twenty_five_fasts"
    case fiftyFasts = "fifty_fasts"
    case fatBurner = "fat_burner"
    case ketosisKing = "ketosis_king"
    case autophagyMaster = "autophagy_master"
    case hydrationHero = "hydration_hero"

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .firstFast: "First Fast"
        case .threeDayStreak: "3-Day Streak"
        case .sevenDayStreak: "7-Day Streak"
        case .thirtyDayStreak: "30-Day Streak"
        case .warrior24h: "24hr Warrior"
        case .centurion100h: "100 Hours Total"
        case .tenFasts: "Dedicated"
        case .twentyFiveFasts: "Committed"
        case .fiftyFasts: "Veteran"
        case .fatBurner: "Fat Burner"
        case .ketosisKing: "Ketosis King"
        case .autophagyMaster: "Autophagy Master"
        case .hydrationHero: "Hydration Hero"
        }
    }

    var subtitle: String {
        switch self {
        case .firstFast: "Complete your first fast"
        case .threeDayStreak: "Fast 3 days in a row"
        case .sevenDayStreak: "Fast 7 days in a row"
        case .thirtyDayStreak: "Fast 30 days in a row"
        case .warrior24h: "Complete a 24+ hour fast"
        case .centurion100h: "Accumulate 100 hours of fasting"
        case .tenFasts: "Complete 10 fasts"
        case .twentyFiveFasts: "Complete 25 fasts"
        case .fiftyFasts: "Complete 50 fasts"
        case .fatBurner: "Reach Fat Burning stage 5 times"
        case .ketosisKing: "Reach Ketosis stage 3 times"
        case .autophagyMaster: "Reach Autophagy stage"
        case .hydrationHero: "Log 50 glasses of water total"
        }
    }

    var icon: String {
        switch self {
        case .firstFast: "star.fill"
        case .threeDayStreak: "flame.fill"
        case .sevenDayStreak: "flame.fill"
        case .thirtyDayStreak: "flame.fill"
        case .warrior24h: "shield.fill"
        case .centurion100h: "trophy.fill"
        case .tenFasts: "medal.fill"
        case .twentyFiveFasts: "medal.fill"
        case .fiftyFasts: "crown.fill"
        case .fatBurner: "bolt.fill"
        case .ketosisKing: "bolt.heart.fill"
        case .autophagyMaster: "sparkles"
        case .hydrationHero: "drop.fill"
        }
    }

    var color: Color {
        switch self {
        case .firstFast: .yellow
        case .threeDayStreak: .orange
        case .sevenDayStreak: .orange
        case .thirtyDayStreak: .red
        case .warrior24h: .purple
        case .centurion100h: .yellow
        case .tenFasts: .blue
        case .twentyFiveFasts: .blue
        case .fiftyFasts: .purple
        case .fatBurner: .orange
        case .ketosisKing: .blue
        case .autophagyMaster: .purple
        case .hydrationHero: .cyan
        }
    }

    /// Milestone streaks that trigger a share prompt
    static let streakMilestones: [Achievement] = [.sevenDayStreak, .thirtyDayStreak]

    /// Whether this achievement is available to free users.
    /// Free: firstFast, threeDayStreak, tenFasts, fatBurner, hydrationHero (5 basic).
    /// Pro: sevenDayStreak, thirtyDayStreak, warrior24h, centurion100h, twentyFiveFasts, fiftyFasts, ketosisKing, autophagyMaster (8 advanced).
    var isFree: Bool {
        switch self {
        case .firstFast, .threeDayStreak, .tenFasts, .fatBurner, .hydrationHero: true
        default: false
        }
    }
}
