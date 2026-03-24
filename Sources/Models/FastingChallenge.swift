import Foundation
import SwiftUI

// MARK: - Challenge Definition

/// Solo fasting challenges — tracked locally via UserDefaults.
/// No server, no multiplayer. Simple goal + progress tracking.
/// Data stays on device (K004).
enum FastingChallenge: String, CaseIterable, Identifiable, Codable {
    case sevenDayStreak = "seven_day_streak"
    case sixteenHourPlus = "sixteen_hour_plus"
    case threeDayConsecutive = "three_day_consecutive"
    case fiveCompletedFasts = "five_completed_fasts"
    case earlyBird = "early_bird"
    case hydrationChamp = "hydration_champ"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .sevenDayStreak: "7-Day Warrior"
        case .sixteenHourPlus: "16+ Hour Club"
        case .threeDayConsecutive: "Hat Trick"
        case .fiveCompletedFasts: "High Five"
        case .earlyBird: "Early Bird"
        case .hydrationChamp: "Hydration Champ"
        }
    }
    
    var subtitle: String {
        switch self {
        case .sevenDayStreak: "Complete a fast every day for 7 days"
        case .sixteenHourPlus: "Complete five 16+ hour fasts"
        case .threeDayConsecutive: "Fast 3 days in a row"
        case .fiveCompletedFasts: "Complete 5 fasts total"
        case .earlyBird: "Complete 3 fasts before noon"
        case .hydrationChamp: "Log 30 glasses of water across fasts"
        }
    }
    
    var icon: String {
        switch self {
        case .sevenDayStreak: "flame.fill"
        case .sixteenHourPlus: "trophy.fill"
        case .threeDayConsecutive: "repeat"
        case .fiveCompletedFasts: "hand.thumbsup.fill"
        case .earlyBird: "sunrise.fill"
        case .hydrationChamp: "drop.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .sevenDayStreak: .orange
        case .sixteenHourPlus: .purple
        case .threeDayConsecutive: .blue
        case .fiveCompletedFasts: .green
        case .earlyBird: .yellow
        case .hydrationChamp: .cyan
        }
    }
    
    /// Total target count to complete the challenge
    var targetCount: Int {
        switch self {
        case .sevenDayStreak: 7
        case .sixteenHourPlus: 5
        case .threeDayConsecutive: 3
        case .fiveCompletedFasts: 5
        case .earlyBird: 3
        case .hydrationChamp: 30
        }
    }
    
    /// Badge icon shown on completion
    var badgeIcon: String {
        switch self {
        case .sevenDayStreak: "flame.circle.fill"
        case .sixteenHourPlus: "crown.fill"
        case .threeDayConsecutive: "medal.fill"
        case .fiveCompletedFasts: "star.fill"
        case .earlyBird: "sun.max.fill"
        case .hydrationChamp: "drop.circle.fill"
        }
    }
}

// MARK: - Challenge Manager

/// Evaluates and persists challenge progress via UserDefaults.
/// Each challenge stores current progress and completion date.
/// Re-evaluates against session history on every call.
@MainActor
@Observable
final class ChallengeManager {
    
    private static let progressPrefix = "lf_challenge_progress_"
    private static let completedPrefix = "lf_challenge_completed_"
    
    /// Current progress per challenge (cached in memory)
    private(set) var progress: [FastingChallenge: Int] = [:]
    
    /// Completion dates for completed challenges
    private(set) var completedDates: [FastingChallenge: Date] = [:]
    
    init() {
        loadState()
    }
    
    // MARK: - Queries
    
    func isCompleted(_ challenge: FastingChallenge) -> Bool {
        completedDates[challenge] != nil
    }
    
    func currentProgress(_ challenge: FastingChallenge) -> Int {
        progress[challenge] ?? 0
    }
    
    func progressFraction(_ challenge: FastingChallenge) -> Double {
        let current = Double(currentProgress(challenge))
        let target = Double(challenge.targetCount)
        guard target > 0 else { return 0 }
        return min(1.0, current / target)
    }
    
    var completedCount: Int {
        completedDates.count
    }
    
    var totalCount: Int {
        FastingChallenge.allCases.count
    }
    
    var activeChallenges: [FastingChallenge] {
        FastingChallenge.allCases.filter { !isCompleted($0) }
    }
    
    var completedChallenges: [FastingChallenge] {
        FastingChallenge.allCases.filter { isCompleted($0) }
    }
    
    // MARK: - Evaluation
    
    /// Evaluate all challenges against current completed sessions.
    /// Returns newly completed challenges (for animation/notification).
    @discardableResult
    func evaluate(sessions: [FastingSession]) -> [FastingChallenge] {
        let completed = sessions.filter(\.isCompleted).sorted { $0.startDate < $1.startDate }
        var newlyCompleted: [FastingChallenge] = []
        
        // 7-Day Streak
        let streak = AchievementManager.computeCurrentStreak(sessions: completed)
        updateProgress(.sevenDayStreak, value: min(streak, 7))
        if !isCompleted(.sevenDayStreak) && streak >= 7 {
            markCompleted(.sevenDayStreak)
            newlyCompleted.append(.sevenDayStreak)
        }
        
        // 16+ Hour Club (five 16h+ fasts)
        let longFasts = completed.filter { $0.actualDuration >= 16 * 3600 }.count
        updateProgress(.sixteenHourPlus, value: min(longFasts, 5))
        if !isCompleted(.sixteenHourPlus) && longFasts >= 5 {
            markCompleted(.sixteenHourPlus)
            newlyCompleted.append(.sixteenHourPlus)
        }
        
        // 3-Day Consecutive
        let consec = computeConsecutiveDays(sessions: completed)
        updateProgress(.threeDayConsecutive, value: min(consec, 3))
        if !isCompleted(.threeDayConsecutive) && consec >= 3 {
            markCompleted(.threeDayConsecutive)
            newlyCompleted.append(.threeDayConsecutive)
        }
        
        // 5 Completed Fasts
        let totalFasts = completed.count
        updateProgress(.fiveCompletedFasts, value: min(totalFasts, 5))
        if !isCompleted(.fiveCompletedFasts) && totalFasts >= 5 {
            markCompleted(.fiveCompletedFasts)
            newlyCompleted.append(.fiveCompletedFasts)
        }
        
        // Early Bird (3 fasts ended before noon)
        let earlyFasts = completed.filter { session in
            guard let endDate = session.endDate else { return false }
            let hour = Calendar.current.component(.hour, from: endDate)
            return hour < 12
        }.count
        updateProgress(.earlyBird, value: min(earlyFasts, 3))
        if !isCompleted(.earlyBird) && earlyFasts >= 3 {
            markCompleted(.earlyBird)
            newlyCompleted.append(.earlyBird)
        }
        
        // Hydration Champ (30 total water glasses)
        let totalWater = completed.reduce(0) { $0 + $1.waterCount }
        updateProgress(.hydrationChamp, value: min(totalWater, 30))
        if !isCompleted(.hydrationChamp) && totalWater >= 30 {
            markCompleted(.hydrationChamp)
            newlyCompleted.append(.hydrationChamp)
        }
        
        return newlyCompleted
    }
    
    // MARK: - Consecutive Days Helper
    
    /// Compute the current consecutive fasting days (same logic as AchievementManager streak).
    private func computeConsecutiveDays(sessions: [FastingSession]) -> Int {
        AchievementManager.computeCurrentStreak(sessions: sessions)
    }
    
    // MARK: - Persistence
    
    private func updateProgress(_ challenge: FastingChallenge, value: Int) {
        progress[challenge] = value
        UserDefaults.standard.set(value, forKey: Self.progressPrefix + challenge.rawValue)
    }
    
    private func markCompleted(_ challenge: FastingChallenge) {
        let date = Date.now
        completedDates[challenge] = date
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Self.completedPrefix + challenge.rawValue)
        HapticManager.shared.achievementUnlocked()
    }
    
    private func loadState() {
        for challenge in FastingChallenge.allCases {
            let prog = UserDefaults.standard.integer(forKey: Self.progressPrefix + challenge.rawValue)
            if prog > 0 {
                progress[challenge] = prog
            }
            
            let ts = UserDefaults.standard.double(forKey: Self.completedPrefix + challenge.rawValue)
            if ts > 0 {
                completedDates[challenge] = Date(timeIntervalSince1970: ts)
            }
        }
    }
}
