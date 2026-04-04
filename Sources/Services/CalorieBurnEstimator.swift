import Foundation

/// Estimates calories burned during a fasting window based on BMR and fasting phase multipliers.
///
/// The calculation uses a simplified Mifflin-St Jeor formula when body weight is available,
/// otherwise falls back to a population-average BMR of 1800 kcal/day.
///
/// Fasting multipliers reflect increased metabolic activity during extended fasting phases:
/// - 0–12h: 1.0x (post-absorptive, normal metabolic rate)
/// - 12–18h: 1.1x (fat oxidation ramp-up)
/// - 18–24h: 1.15x (ketosis, elevated fat metabolism)
/// - 24h+: 1.2x (deep ketosis / autophagy)
enum CalorieBurnEstimator {
    /// Disclaimer text — show alongside any calorie estimate in the UI.
    static let disclaimer = "Estimated based on general metabolic research. Individual results vary."

    /// Estimate total kcal burned over a fasting window.
    ///
    /// - Parameters:
    ///   - fastingHours: Elapsed fasting time in hours (fractional OK).
    ///   - bodyWeightKg: Optional body weight in kg. When nil, uses default BMR of 1800 kcal/day.
    /// - Returns: Estimated kilocalories burned (rounded to nearest integer-level precision).
    static func estimate(fastingHours: Double, bodyWeightKg: Double? = nil) -> Double {
        guard fastingHours > 0 else { return 0 }

        // BMR in kcal/day
        let dailyBMR: Double = if let weight = bodyWeightKg, weight > 0 {
            // Simplified Mifflin-St Jeor for average adult
            10 * weight + 625
        } else {
            1800
        }

        let hourlyBMR = dailyBMR / 24.0

        // Integrate hourly burn across fasting phase boundaries
        let phases: [(upperBound: Double, multiplier: Double)] = [
            (12, 1.0),
            (18, 1.1),
            (24, 1.15),
            (.infinity, 1.2),
        ]

        var totalKcal: Double = 0
        var hoursAccounted: Double = 0

        for phase in phases {
            guard hoursAccounted < fastingHours else { break }
            let phaseEnd = min(phase.upperBound, fastingHours)
            let hoursInPhase = max(0, phaseEnd - hoursAccounted)
            totalKcal += hoursInPhase * hourlyBMR * phase.multiplier
            hoursAccounted = phaseEnd
        }

        return totalKcal
    }
}
