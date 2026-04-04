import Foundation
import OSLog

private let logger = Logger(subsystem: "com.theknack.lumifaste", category: "ClockGuard")

/// Detects and handles device clock manipulation and timezone changes.
/// Protects fasting timer integrity when user travels or changes device time.
///
/// Strategy:
/// - Stores a monotonic reference (`ProcessInfo.processInfo.systemUptime`) alongside wall-clock time.
/// - On each check, compares wall-clock delta to uptime delta.
/// - Large discrepancies indicate clock manipulation.
/// - Timezone changes are handled by storing all dates as UTC (Date uses absolute time).
enum ClockGuard {
    private static let lastCheckUptimeKey = "lf_clock_guard_uptime"
    private static let lastCheckWallKey = "lf_clock_guard_wall"

    /// Maximum allowed drift between wall clock and uptime (seconds).
    /// 60 seconds allows for normal NTP corrections.
    private static let maxDriftSeconds: TimeInterval = 60

    // MARK: - Clock Integrity Check

    /// Result of a clock integrity check.
    enum CheckResult {
        /// Clock is consistent — no manipulation detected
        case ok
        /// Clock was moved forward by the given amount
        case movedForward(seconds: TimeInterval)
        /// Clock was moved backward by the given amount
        case movedBackward(seconds: TimeInterval)
        /// First check — no baseline to compare against
        case firstCheck
    }

    /// Check clock integrity. Call on app foreground and timer tick.
    /// Returns the nature of any clock discrepancy detected.
    static func checkClockIntegrity() -> CheckResult {
        let currentUptime = ProcessInfo.processInfo.systemUptime
        let currentWall = Date.now.timeIntervalSince1970

        let ud = UserDefaults.standard
        let previousUptime = ud.double(forKey: lastCheckUptimeKey)
        let previousWall = ud.double(forKey: lastCheckWallKey)

        // Save current checkpoint
        ud.set(currentUptime, forKey: lastCheckUptimeKey)
        ud.set(currentWall, forKey: lastCheckWallKey)

        // First run — no baseline
        guard previousUptime > 0, previousWall > 0 else {
            return .firstCheck
        }

        let uptimeDelta = currentUptime - previousUptime
        let wallDelta = currentWall - previousWall

        // After device reboot, uptime resets. In that case uptime < previousUptime.
        // This is not manipulation — treat as OK.
        guard uptimeDelta > 0 else {
            return .ok
        }

        let drift = wallDelta - uptimeDelta

        if drift > maxDriftSeconds {
            logger.warning("Clock moved forward by \(drift, privacy: .public)s")
            return .movedForward(seconds: drift)
        } else if drift < -maxDriftSeconds {
            logger.warning("Clock moved backward by \(-drift, privacy: .public)s")
            return .movedBackward(seconds: -drift)
        }

        return .ok
    }

    // MARK: - Validate Fast Dates

    /// Validate that a fasting session's dates are reasonable.
    /// Returns nil if valid, or a reason string if invalid.
    static func validateFastDates(start: Date, targetEnd: Date) -> String? {
        let now = Date.now

        // Start date should not be in the future
        if start > now.addingTimeInterval(60) { // 60s tolerance for clock sync
            return "Start time is in the future"
        }

        // Start should not be more than 7 days ago (reasonable max)
        if now.timeIntervalSince(start) > 7 * 24 * 3600 {
            return "Start time is more than 7 days ago"
        }

        // Target end must be after start
        if targetEnd <= start {
            return "Target end is before start"
        }

        // Max fast duration: 7 days
        if targetEnd.timeIntervalSince(start) > 7 * 24 * 3600 {
            return "Fast duration exceeds 7 days"
        }

        return nil
    }

    // MARK: - Elapsed Time with Safety

    /// Calculate elapsed time with safety bounds.
    /// Returns elapsed time clamped to reasonable values.
    static func safeElapsedTime(since start: Date, pausedDuration: TimeInterval = 0) -> TimeInterval {
        let raw = Date.now.timeIntervalSince(start)

        // Negative elapsed = clock moved backward. Clamp to 0.
        guard raw >= 0 else { return 0 }

        // Max 7 days of fasting (168 hours)
        let maxElapsed: TimeInterval = 7 * 24 * 3600
        let clamped = min(raw, maxElapsed)

        // Subtract paused time, ensuring non-negative
        return max(0, clamped - pausedDuration)
    }

    // MARK: - Timezone Change Detection

    private static let lastTimezoneKey = "lf_clock_guard_timezone"

    /// Check if timezone has changed since last check.
    /// Returns the old timezone identifier if changed, nil if unchanged.
    static func checkTimezoneChange() -> String? {
        let current = TimeZone.current.identifier
        let previous = UserDefaults.standard.string(forKey: lastTimezoneKey)

        UserDefaults.standard.set(current, forKey: lastTimezoneKey)

        if let previous, previous != current {
            logger.info("Timezone changed: \(previous) → \(current)")
            return previous
        }
        return nil
    }
}
