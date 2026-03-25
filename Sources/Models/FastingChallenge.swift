import Foundation
import SwiftUI

// MARK: - Challenge Category

/// Time-based challenge categories — determines refresh cadence and grouping.
enum ChallengeCategory: String, CaseIterable, Identifiable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case lifetime = "lifetime"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .daily: "Daily"
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .lifetime: "Lifetime"
        }
    }
    
    var icon: String {
        switch self {
        case .daily: "sun.max.fill"
        case .weekly: "calendar"
        case .monthly: "calendar.badge.clock"
        case .lifetime: "star.circle.fill"
        }
    }
}

// MARK: - Challenge Difficulty

enum ChallengeDifficulty: String, CaseIterable, Identifiable, Codable, Comparable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        }
    }
    
    var color: Color {
        switch self {
        case .easy: .green
        case .medium: .orange
        case .hard: .red
        }
    }
    
    /// XP multiplier for this difficulty
    var xpMultiplier: Int {
        switch self {
        case .easy: 1
        case .medium: 2
        case .hard: 3
        }
    }
    
    private var sortOrder: Int {
        switch self {
        case .easy: 0
        case .medium: 1
        case .hard: 2
        }
    }
    
    static func < (lhs: ChallengeDifficulty, rhs: ChallengeDifficulty) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Challenge Definition

/// Solo fasting challenges — tracked locally via UserDefaults.
/// No server, no multiplayer. Simple goal + progress tracking.
/// Data stays on device (K004).
///
/// Original lifetime challenges preserved. New daily/weekly/monthly added.
enum FastingChallenge: String, CaseIterable, Identifiable, Codable {
    // Lifetime challenges (original)
    case sevenDayStreak = "seven_day_streak"
    case sixteenHourPlus = "sixteen_hour_plus"
    case threeDayConsecutive = "three_day_consecutive"
    case fiveCompletedFasts = "five_completed_fasts"
    case earlyBird = "early_bird"
    case hydrationChamp = "hydration_champ"
    
    // Daily challenges
    case dailyCompleteFast = "daily_complete_fast"
    case dailyDrinkWater = "daily_drink_water"
    case dailySixteenHours = "daily_sixteen_hours"
    
    // Weekly challenges
    case weeklyFiveFasts = "weekly_five_fasts"
    case weeklyEightyHours = "weekly_eighty_hours"
    case weeklyMaintainStreak = "weekly_maintain_streak"
    
    // Monthly challenges
    case monthlyThirtyFasts = "monthly_thirty_fasts"
    case monthlyAutophagyFive = "monthly_autophagy_five"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .sevenDayStreak: "7-Day Warrior"
        case .sixteenHourPlus: "16+ Hour Club"
        case .threeDayConsecutive: "Hat Trick"
        case .fiveCompletedFasts: "High Five"
        case .earlyBird: "Early Bird"
        case .hydrationChamp: "Hydration Champ"
        case .dailyCompleteFast: "Daily Fast"
        case .dailyDrinkWater: "Hydrate Today"
        case .dailySixteenHours: "16-Hour Push"
        case .weeklyFiveFasts: "5-a-Week"
        case .weeklyEightyHours: "80-Hour Week"
        case .weeklyMaintainStreak: "Streak Keeper"
        case .monthlyThirtyFasts: "Monthly Master"
        case .monthlyAutophagyFive: "Autophagy Hunter"
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
        case .dailyCompleteFast: "Complete 1 fast today"
        case .dailyDrinkWater: "Drink 8 glasses of water today"
        case .dailySixteenHours: "Complete a 16+ hour fast today"
        case .weeklyFiveFasts: "Complete 5 fasts this week"
        case .weeklyEightyHours: "Fast 80+ total hours this week"
        case .weeklyMaintainStreak: "Maintain your streak all week"
        case .monthlyThirtyFasts: "Complete 30 fasts this month"
        case .monthlyAutophagyFive: "Reach autophagy 5 times this month"
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
        case .dailyCompleteFast: "checkmark.circle.fill"
        case .dailyDrinkWater: "drop.fill"
        case .dailySixteenHours: "clock.fill"
        case .weeklyFiveFasts: "calendar.badge.checkmark"
        case .weeklyEightyHours: "hourglass"
        case .weeklyMaintainStreak: "flame.fill"
        case .monthlyThirtyFasts: "star.fill"
        case .monthlyAutophagyFive: "bolt.fill"
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
        case .dailyCompleteFast: .green
        case .dailyDrinkWater: .cyan
        case .dailySixteenHours: .purple
        case .weeklyFiveFasts: .blue
        case .weeklyEightyHours: .orange
        case .weeklyMaintainStreak: .red
        case .monthlyThirtyFasts: .indigo
        case .monthlyAutophagyFive: .pink
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
        case .dailyCompleteFast: 1
        case .dailyDrinkWater: 8
        case .dailySixteenHours: 1
        case .weeklyFiveFasts: 5
        case .weeklyEightyHours: 80
        case .weeklyMaintainStreak: 7
        case .monthlyThirtyFasts: 30
        case .monthlyAutophagyFive: 5
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
        case .dailyCompleteFast: "checkmark.seal.fill"
        case .dailyDrinkWater: "drop.circle.fill"
        case .dailySixteenHours: "clock.badge.checkmark.fill"
        case .weeklyFiveFasts: "rosette"
        case .weeklyEightyHours: "medal.fill"
        case .weeklyMaintainStreak: "flame.circle.fill"
        case .monthlyThirtyFasts: "crown.fill"
        case .monthlyAutophagyFive: "bolt.circle.fill"
        }
    }
    
    /// Challenge category (determines refresh cadence and UI grouping)
    var category: ChallengeCategory {
        switch self {
        case .sevenDayStreak, .sixteenHourPlus, .threeDayConsecutive,
             .fiveCompletedFasts, .earlyBird, .hydrationChamp:
            return .lifetime
        case .dailyCompleteFast, .dailyDrinkWater, .dailySixteenHours:
            return .daily
        case .weeklyFiveFasts, .weeklyEightyHours, .weeklyMaintainStreak:
            return .weekly
        case .monthlyThirtyFasts, .monthlyAutophagyFive:
            return .monthly
        }
    }
    
    /// Difficulty level — affects XP reward
    var difficulty: ChallengeDifficulty {
        switch self {
        case .dailyCompleteFast, .fiveCompletedFasts, .dailyDrinkWater:
            return .easy
        case .threeDayConsecutive, .earlyBird, .dailySixteenHours,
             .weeklyFiveFasts, .weeklyMaintainStreak:
            return .medium
        case .sevenDayStreak, .sixteenHourPlus, .hydrationChamp,
             .weeklyEightyHours, .monthlyThirtyFasts, .monthlyAutophagyFive:
            return .hard
        }
    }
    
    /// Base XP awarded on completion (multiplied by difficulty)
    var baseXP: Int {
        switch category {
        case .daily: 10
        case .weekly: 25
        case .monthly: 50
        case .lifetime: 100
        }
    }
    
    /// Total XP awarded = baseXP * difficulty multiplier
    var xpReward: Int {
        baseXP * difficulty.xpMultiplier
    }
    
    // MARK: - Filtering Helpers
    
    /// All challenges of a specific category
    static func challenges(for category: ChallengeCategory) -> [FastingChallenge] {
        allCases.filter { $0.category == category }
    }
    
    /// Lifetime (original) challenges only
    static var lifetimeChallenges: [FastingChallenge] {
        challenges(for: .lifetime)
    }
    
    /// Time-bound (daily/weekly/monthly) challenges
    static var timedChallenges: [FastingChallenge] {
        allCases.filter { $0.category != .lifetime }
    }
}

// MARK: - Challenge Manager

/// Evaluates and persists challenge progress via UserDefaults.
/// Each challenge stores current progress and completion date.
/// Re-evaluates against session history on every call.
///
/// Time-bound challenges (daily/weekly/monthly) filter sessions by their
/// relevant time window. They reset automatically when the window passes.
@MainActor
@Observable
final class ChallengeManager {
    
    private static let progressPrefix = "lf_challenge_progress_"
    private static let completedPrefix = "lf_challenge_completed_"
    private static let xpKey = "lf_challenge_total_xp"
    private static let lastDailyResetKey = "lf_challenge_daily_reset"
    private static let lastWeeklyResetKey = "lf_challenge_weekly_reset"
    private static let lastMonthlyResetKey = "lf_challenge_monthly_reset"
    
    /// Current progress per challenge (cached in memory)
    private(set) var progress: [FastingChallenge: Int] = [:]
    
    /// Completion dates for completed challenges
    private(set) var completedDates: [FastingChallenge: Date] = [:]
    
    /// Total accumulated XP
    private(set) var totalXP: Int = 0
    
    init() {
        loadState()
        resetExpiredChallenges()
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
    
    /// Active challenges grouped by category
    func activeChallenges(for category: ChallengeCategory) -> [FastingChallenge] {
        FastingChallenge.challenges(for: category).filter { !isCompleted($0) }
    }
    
    /// Completed challenges for a specific category
    func completedChallenges(for category: ChallengeCategory) -> [FastingChallenge] {
        FastingChallenge.challenges(for: category).filter { isCompleted($0) }
    }
    
    /// XP display string (e.g. "1,250 XP")
    var xpDisplayString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return "\(formatter.string(from: NSNumber(value: totalXP)) ?? "\(totalXP)") XP"
    }
    
    // MARK: - Time Window Helpers
    
    private var todayStart: Date {
        Calendar.current.startOfDay(for: .now)
    }
    
    private var weekStart: Date {
        let cal = Calendar.current
        var components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)
        components.weekday = cal.firstWeekday
        return cal.date(from: components) ?? todayStart
    }
    
    private var monthStart: Date {
        let cal = Calendar.current
        let components = cal.dateComponents([.year, .month], from: .now)
        return cal.date(from: components) ?? todayStart
    }
    
    private func sessionsToday(_ sessions: [FastingSession]) -> [FastingSession] {
        sessions.filter { $0.startDate >= todayStart }
    }
    
    private func sessionsThisWeek(_ sessions: [FastingSession]) -> [FastingSession] {
        sessions.filter { $0.startDate >= weekStart }
    }
    
    private func sessionsThisMonth(_ sessions: [FastingSession]) -> [FastingSession] {
        sessions.filter { $0.startDate >= monthStart }
    }
    
    // MARK: - Evaluation
    
    /// Evaluate all challenges against current completed sessions.
    /// Returns newly completed challenges (for animation/notification).
    @discardableResult
    func evaluate(sessions: [FastingSession]) -> [FastingChallenge] {
        let completed = sessions.filter(\.isCompleted).sorted { $0.startDate < $1.startDate }
        var newlyCompleted: [FastingChallenge] = []
        
        // Reset expired time-bound challenges before evaluating
        resetExpiredChallenges()
        
        // ── Lifetime challenges ──
        
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
        
        // ── Daily challenges ──
        
        let todayCompleted = sessionsToday(completed)
        
        // Daily: Complete 1 fast today
        let todayFasts = todayCompleted.count
        updateProgress(.dailyCompleteFast, value: min(todayFasts, 1))
        if !isCompleted(.dailyCompleteFast) && todayFasts >= 1 {
            markCompleted(.dailyCompleteFast)
            newlyCompleted.append(.dailyCompleteFast)
        }
        
        // Daily: Drink 8 glasses of water today
        let todayWater = todayCompleted.reduce(0) { $0 + $1.waterCount }
        updateProgress(.dailyDrinkWater, value: min(todayWater, 8))
        if !isCompleted(.dailyDrinkWater) && todayWater >= 8 {
            markCompleted(.dailyDrinkWater)
            newlyCompleted.append(.dailyDrinkWater)
        }
        
        // Daily: Complete a 16+ hour fast today
        let todayLong = todayCompleted.filter { $0.actualDuration >= 16 * 3600 }.count
        updateProgress(.dailySixteenHours, value: min(todayLong, 1))
        if !isCompleted(.dailySixteenHours) && todayLong >= 1 {
            markCompleted(.dailySixteenHours)
            newlyCompleted.append(.dailySixteenHours)
        }
        
        // ── Weekly challenges ──
        
        let weekCompleted = sessionsThisWeek(completed)
        
        // Weekly: 5 fasts this week
        let weekFasts = weekCompleted.count
        updateProgress(.weeklyFiveFasts, value: min(weekFasts, 5))
        if !isCompleted(.weeklyFiveFasts) && weekFasts >= 5 {
            markCompleted(.weeklyFiveFasts)
            newlyCompleted.append(.weeklyFiveFasts)
        }
        
        // Weekly: 80+ total hours
        let weekHours = Int(weekCompleted.reduce(0.0) { $0 + $1.actualDuration } / 3600)
        updateProgress(.weeklyEightyHours, value: min(weekHours, 80))
        if !isCompleted(.weeklyEightyHours) && weekHours >= 80 {
            markCompleted(.weeklyEightyHours)
            newlyCompleted.append(.weeklyEightyHours)
        }
        
        // Weekly: Maintain streak all week (7 consecutive days including this week)
        updateProgress(.weeklyMaintainStreak, value: min(streak, 7))
        if !isCompleted(.weeklyMaintainStreak) && streak >= 7 {
            markCompleted(.weeklyMaintainStreak)
            newlyCompleted.append(.weeklyMaintainStreak)
        }
        
        // ── Monthly challenges ──
        
        let monthCompleted = sessionsThisMonth(completed)
        
        // Monthly: 30 fasts this month
        let monthFasts = monthCompleted.count
        updateProgress(.monthlyThirtyFasts, value: min(monthFasts, 30))
        if !isCompleted(.monthlyThirtyFasts) && monthFasts >= 30 {
            markCompleted(.monthlyThirtyFasts)
            newlyCompleted.append(.monthlyThirtyFasts)
        }
        
        // Monthly: Reach autophagy 5 times
        let monthAutophagy = monthCompleted.filter { $0.stageReached == FastingStage.autophagy.rawValue }.count
        updateProgress(.monthlyAutophagyFive, value: min(monthAutophagy, 5))
        if !isCompleted(.monthlyAutophagyFive) && monthAutophagy >= 5 {
            markCompleted(.monthlyAutophagyFive)
            newlyCompleted.append(.monthlyAutophagyFive)
        }
        
        return newlyCompleted
    }
    
    // MARK: - Consecutive Days Helper
    
    /// Compute the current consecutive fasting days (same logic as AchievementManager streak).
    private func computeConsecutiveDays(sessions: [FastingSession]) -> Int {
        AchievementManager.computeCurrentStreak(sessions: sessions)
    }
    
    // MARK: - Time-Bound Reset
    
    /// Reset daily/weekly/monthly challenges when their time window has passed.
    private func resetExpiredChallenges() {
        let cal = Calendar.current
        let now = Date.now
        
        // Daily reset
        let lastDailyReset = UserDefaults.standard.double(forKey: Self.lastDailyResetKey)
        let lastDailyDate = lastDailyReset > 0 ? Date(timeIntervalSince1970: lastDailyReset) : Date.distantPast
        if !cal.isDate(lastDailyDate, inSameDayAs: now) {
            resetChallenges(for: .daily)
            UserDefaults.standard.set(now.timeIntervalSince1970, forKey: Self.lastDailyResetKey)
        }
        
        // Weekly reset (check if we're in a different week)
        let lastWeeklyReset = UserDefaults.standard.double(forKey: Self.lastWeeklyResetKey)
        let lastWeeklyDate = lastWeeklyReset > 0 ? Date(timeIntervalSince1970: lastWeeklyReset) : Date.distantPast
        let lastWeekOfYear = cal.component(.weekOfYear, from: lastWeeklyDate)
        let currentWeekOfYear = cal.component(.weekOfYear, from: now)
        let lastYear = cal.component(.yearForWeekOfYear, from: lastWeeklyDate)
        let currentYear = cal.component(.yearForWeekOfYear, from: now)
        if lastWeekOfYear != currentWeekOfYear || lastYear != currentYear {
            resetChallenges(for: .weekly)
            UserDefaults.standard.set(now.timeIntervalSince1970, forKey: Self.lastWeeklyResetKey)
        }
        
        // Monthly reset
        let lastMonthlyReset = UserDefaults.standard.double(forKey: Self.lastMonthlyResetKey)
        let lastMonthlyDate = lastMonthlyReset > 0 ? Date(timeIntervalSince1970: lastMonthlyReset) : Date.distantPast
        let lastMonth = cal.component(.month, from: lastMonthlyDate)
        let currentMonth = cal.component(.month, from: now)
        let lastMonthYear = cal.component(.year, from: lastMonthlyDate)
        let currentMonthYear = cal.component(.year, from: now)
        if lastMonth != currentMonth || lastMonthYear != currentMonthYear {
            resetChallenges(for: .monthly)
            UserDefaults.standard.set(now.timeIntervalSince1970, forKey: Self.lastMonthlyResetKey)
        }
    }
    
    /// Clear progress and completion for all challenges in a category
    private func resetChallenges(for category: ChallengeCategory) {
        for challenge in FastingChallenge.challenges(for: category) {
            progress[challenge] = 0
            completedDates[challenge] = nil
            UserDefaults.standard.removeObject(forKey: Self.progressPrefix + challenge.rawValue)
            UserDefaults.standard.removeObject(forKey: Self.completedPrefix + challenge.rawValue)
        }
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
        // Award XP
        totalXP += challenge.xpReward
        UserDefaults.standard.set(totalXP, forKey: Self.xpKey)
        HapticManager.shared.achievementUnlocked()
    }
    
    private func loadState() {
        totalXP = UserDefaults.standard.integer(forKey: Self.xpKey)
        
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
