import Foundation

/// Simulated community averages for "Fast Buddy" comparison (#7).
/// In a production app this would come from a privacy-preserving aggregate API.
/// For now, hardcoded realistic averages based on fasting research.
enum CommunityStats {
    
    struct PlanAverage {
        let plan: FastingPlan
        let averageDurationHours: Double
        let completionRate: Double // 0-1
        let participantCount: Int
    }
    
    /// Average fasting duration per plan (based on published IF study data)
    static let averages: [PlanAverage] = [
        PlanAverage(plan: .twelveTwelve, averageDurationHours: 11.8, completionRate: 0.92, participantCount: 12_400),
        PlanAverage(plan: .fourteenTen, averageDurationHours: 13.5, completionRate: 0.87, participantCount: 8_200),
        PlanAverage(plan: .sixteenEight, averageDurationHours: 15.2, completionRate: 0.81, participantCount: 45_600),
        PlanAverage(plan: .eighteenSix, averageDurationHours: 16.8, completionRate: 0.73, participantCount: 15_300),
        PlanAverage(plan: .twentyFour, averageDurationHours: 18.4, completionRate: 0.64, participantCount: 6_100),
        PlanAverage(plan: .omad, averageDurationHours: 21.1, completionRate: 0.58, participantCount: 3_800),
        PlanAverage(plan: .circadian, averageDurationHours: 12.6, completionRate: 0.89, participantCount: 9_700),
    ]
    
    /// Get the community average for a given plan
    static func average(for plan: FastingPlan) -> PlanAverage? {
        averages.first { $0.plan == plan }
    }
    
    /// Format participant count for display (e.g. "45.6K")
    static func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        }
        return "\(count)"
    }
}
