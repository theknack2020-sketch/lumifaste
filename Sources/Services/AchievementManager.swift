import Foundation
import SwiftData

/// Tracks and evaluates achievements — stored in UserDefaults with earned dates.
/// Data stays on device (K004).
@MainActor
@Observable
final class AchievementManager {
    private static let prefix = "lf_achievement_"

    /// Achievements earned (with dates), cached in memory
    private(set) var earned: [Achievement: Date] = [:]

    /// Recently unlocked achievements (for animation display)
    var recentlyUnlocked: [Achievement] = []

    init() {
        loadEarned()
    }

    // MARK: - Queries

    var earnedCount: Int {
        earned.count
    }

    var totalCount: Int {
        Achievement.allCases.count
    }

    var completionPercent: Double {
        guard totalCount > 0 else { return 0 }
        return Double(earnedCount) / Double(totalCount) * 100
    }

    func isEarned(_ achievement: Achievement) -> Bool {
        earned[achievement] != nil
    }

    func dateEarned(_ achievement: Achievement) -> Date? {
        earned[achievement]
    }

    // MARK: - Evaluation

    /// Evaluate all achievements against current sessions data.
    /// Returns newly unlocked achievements (for animation).
    @discardableResult
    func evaluate(sessions: [FastingSession]) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []
        let completed = sessions.filter(\.isCompleted)

        // First Fast
        if !isEarned(.firstFast), !completed.isEmpty {
            unlock(.firstFast)
            newlyUnlocked.append(.firstFast)
        }

        // Count-based
        let count = completed.count
        if !isEarned(.tenFasts), count >= 10 {
            unlock(.tenFasts)
            newlyUnlocked.append(.tenFasts)
        }
        if !isEarned(.twentyFiveFasts), count >= 25 {
            unlock(.twentyFiveFasts)
            newlyUnlocked.append(.twentyFiveFasts)
        }
        if !isEarned(.fiftyFasts), count >= 50 {
            unlock(.fiftyFasts)
            newlyUnlocked.append(.fiftyFasts)
        }

        // Duration-based
        let totalHours = completed.reduce(0.0) { $0 + $1.actualDuration } / 3600
        if !isEarned(.centurion100h), totalHours >= 100 {
            unlock(.centurion100h)
            newlyUnlocked.append(.centurion100h)
        }

        // 24h warrior
        if !isEarned(.warrior24h), completed.contains(where: { $0.actualDuration >= 24 * 3600 }) {
            unlock(.warrior24h)
            newlyUnlocked.append(.warrior24h)
        }

        // Stage-based
        let fatBurningCount = completed.count(where: { FastingStage(rawValue: $0.stageReached)?.index ?? 0 >= FastingStage.fatBurning.index })
        if !isEarned(.fatBurner), fatBurningCount >= 5 {
            unlock(.fatBurner)
            newlyUnlocked.append(.fatBurner)
        }

        let ketosisCount = completed.count(where: { FastingStage(rawValue: $0.stageReached)?.index ?? 0 >= FastingStage.ketosis.index })
        if !isEarned(.ketosisKing), ketosisCount >= 3 {
            unlock(.ketosisKing)
            newlyUnlocked.append(.ketosisKing)
        }

        if !isEarned(.autophagyMaster), completed.contains(where: { $0.stageReached == FastingStage.autophagy.rawValue }) {
            unlock(.autophagyMaster)
            newlyUnlocked.append(.autophagyMaster)
        }

        // Hydration
        let totalWater = completed.reduce(0) { $0 + $1.waterCount }
        if !isEarned(.hydrationHero), totalWater >= 50 {
            unlock(.hydrationHero)
            newlyUnlocked.append(.hydrationHero)
        }

        // Streaks
        let streak = Self.computeCurrentStreak(sessions: completed)
        if !isEarned(.threeDayStreak), streak >= 3 {
            unlock(.threeDayStreak)
            newlyUnlocked.append(.threeDayStreak)
        }
        if !isEarned(.sevenDayStreak), streak >= 7 {
            unlock(.sevenDayStreak)
            newlyUnlocked.append(.sevenDayStreak)
        }
        if !isEarned(.thirtyDayStreak), streak >= 30 {
            unlock(.thirtyDayStreak)
            newlyUnlocked.append(.thirtyDayStreak)
        }

        if !newlyUnlocked.isEmpty {
            recentlyUnlocked = newlyUnlocked
        }

        return newlyUnlocked
    }

    // MARK: - Private

    private func unlock(_ achievement: Achievement) {
        let date = Date.now
        earned[achievement] = date
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Self.prefix + achievement.rawValue)
        HapticManager.shared.milestoneReached()
    }

    private func loadEarned() {
        for achievement in Achievement.allCases {
            let ts = UserDefaults.standard.double(forKey: Self.prefix + achievement.rawValue)
            if ts > 0 {
                earned[achievement] = Date(timeIntervalSince1970: ts)
            }
        }
    }

    // MARK: - Streak Computation

    static func computeCurrentStreak(sessions: [FastingSession]) -> Int {
        let calendar = Calendar.current
        let completedDays = Set(
            sessions.map { calendar.startOfDay(for: $0.startDate) }
        ).sorted(by: >)

        guard !completedDays.isEmpty else { return 0 }

        var streak = 0
        var checkDate = calendar.startOfDay(for: .now)

        for day in completedDays {
            if day == checkDate {
                streak += 1
                guard let prevDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDate
            } else {
                guard let prevDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                if day == prevDate {
                    streak += 1
                    guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: day) else { break }
                    checkDate = dayBefore
                } else {
                    break
                }
            }
        }
        return streak
    }
}
