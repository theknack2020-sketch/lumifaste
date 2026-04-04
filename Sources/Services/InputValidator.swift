import Foundation

/// Centralized input validation for all user inputs.
/// Returns nil on valid input, or a user-friendly error message on invalid.
enum InputValidator {
    // MARK: - Weight Validation

    /// Validate weight input. Returns error message or nil if valid.
    /// - Parameter value: Weight as entered by user
    /// - Parameter isMetric: true for kg, false for lbs
    static func validateWeight(_ value: String, isMetric: Bool) -> String? {
        guard !value.trimmingCharacters(in: .whitespaces).isEmpty else {
            return "Please enter a weight value."
        }

        guard let number = Double(value) else {
            return "Please enter a valid number."
        }

        guard number > 0 else {
            return "Weight must be greater than zero."
        }

        if isMetric {
            // kg: reasonable range 20-500 kg
            guard number >= 20, number <= 500 else {
                return "Please enter a weight between 20 and 500 kg."
            }
        } else {
            // lbs: reasonable range 44-1100 lbs
            guard number >= 44, number <= 1100 else {
                return "Please enter a weight between 44 and 1100 lbs."
            }
        }

        return nil
    }

    // MARK: - Custom Plan Hours Validation

    /// Validate custom fasting plan hours. Returns error message or nil if valid.
    static func validateCustomPlanHours(_ hours: Double) -> String? {
        guard hours >= 1 else {
            return "Fasting plan must be at least 1 hour."
        }

        guard hours <= 168 else {
            return "Fasting plan cannot exceed 168 hours (7 days)."
        }

        // Warn about extreme fasts (above 72h)
        // This isn't a hard error — just a soft validation boundary.
        // The UI can show a warning separately.

        return nil
    }

    /// Whether the given hours should show a safety warning
    static func isExtremeFast(hours: Double) -> Bool {
        hours > 72
    }

    // MARK: - Note Validation

    /// Validate note text length. Returns error message or nil if valid.
    static func validateNote(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count <= 500 else {
            return "Note is too long. Maximum 500 characters."
        }
        return nil
    }

    // MARK: - Extend Fast Hours Validation

    /// Validate extension hours. Returns error message or nil if valid.
    static func validateExtendHours(_ hours: Double, currentElapsed: TimeInterval) -> String? {
        guard hours >= 0.5 else {
            return "Extension must be at least 30 minutes."
        }

        guard hours <= 24 else {
            return "Extension cannot exceed 24 hours."
        }

        let totalHours = (currentElapsed / 3600) + hours
        guard totalHours <= 168 else {
            return "Total fast duration would exceed 7 days."
        }

        return nil
    }

    // MARK: - Start Time Adjustment Validation

    /// Validate an adjusted start time. Returns error message or nil if valid.
    static func validateAdjustedStartTime(_ newStart: Date) -> String? {
        let now = Date.now

        if newStart > now {
            return "Start time cannot be in the future."
        }

        let hoursSince = now.timeIntervalSince(newStart) / 3600
        if hoursSince > 24 {
            return "Start time cannot be more than 24 hours ago."
        }

        return nil
    }
}
