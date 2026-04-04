import os
import SwiftUI
import TelemetryDeck

private let logger = Logger(subsystem: "com.theknack.lumifaste", category: "Telemetry")

// MARK: - TelemetryDeck Wrapper

/// Centralized analytics — privacy-first, no personal data.
/// TelemetryDeck is GDPR-compliant by design: no IP tracking, no device fingerprinting.
///
/// Usage:
///   TelemetryService.shared.initialize()  — call once in App.init
///   TelemetryService.shared.trackScreen("Timer")
///   TelemetryService.shared.trackEvent("fast_started", properties: ["plan": "16:8"])
enum TelemetryService {
    // MARK: - Configuration

    /// TelemetryDeck App ID — set via environment or hardcode after dashboard creation.
    /// ⚠️ Replace with your actual App ID from TelemetryDeck dashboard.
    private static let appID: String = {
        if let envID = ProcessInfo.processInfo.environment["LUMIFASTE_TELEMETRY_APP_ID"], !envID.isEmpty {
            return envID
        }
        // Hardcode your App ID here after creating the app on TelemetryDeck dashboard:
        return "REPLACE_WITH_TELEMETRYDECK_APP_ID"
    }()

    // MARK: - Initialization

    /// Call once in App.init — configures TelemetryDeck SDK.
    static func initialize() {
        guard appID != "REPLACE_WITH_TELEMETRYDECK_APP_ID" else {
            logger.warning("TelemetryDeck App ID not configured — analytics disabled")
            return
        }

        let config = TelemetryDeck.Config(appID: appID)
        TelemetryDeck.initialize(config: config)
        logger.info("TelemetryDeck initialized")
    }

    // MARK: - Screen Tracking

    /// Track screen appearance — call in .onAppear or .task
    static func trackScreen(_ name: String) {
        TelemetryDeck.signal("screen_viewed", parameters: ["screen": name])
    }

    // MARK: - Event Tracking

    /// Track custom event with optional properties
    static func trackEvent(_ name: String, properties: [String: String] = [:]) {
        TelemetryDeck.signal(name, parameters: properties)
    }

    // MARK: - Fasting Events

    static func trackFastStarted(plan: String) {
        trackEvent("fast_started", properties: ["plan": plan])
    }

    static func trackFastCompleted(plan: String, durationMinutes: Int, stage: String) {
        trackEvent("fast_completed", properties: [
            "plan": plan,
            "duration_minutes": "\(durationMinutes)",
            "final_stage": stage,
        ])
    }

    static func trackFastCancelled(plan: String, elapsedMinutes: Int) {
        trackEvent("fast_cancelled", properties: [
            "plan": plan,
            "elapsed_minutes": "\(elapsedMinutes)",
        ])
    }

    // MARK: - Paywall Events

    static func trackPaywallShown(source: String) {
        trackEvent("paywall_shown", properties: ["source": source])
    }

    static func trackPurchaseCompleted(productID: String) {
        trackEvent("purchase_completed", properties: ["product": productID])
    }

    static func trackPurchaseFailed(productID: String, error: String) {
        trackEvent("purchase_failed", properties: ["product": productID, "error": error])
    }

    static func trackRestorePurchases(success: Bool) {
        trackEvent("restore_purchases", properties: ["success": "\(success)"])
    }

    // MARK: - Feature Events

    static func trackAchievementUnlocked(_ achievementID: String) {
        trackEvent("achievement_unlocked", properties: ["achievement": achievementID])
    }

    static func trackStreakMilestone(_ days: Int) {
        trackEvent("streak_milestone", properties: ["days": "\(days)"])
    }

    static func trackWaterLogged(amountMl: Int) {
        trackEvent("water_logged", properties: ["amount_ml": "\(amountMl)"])
    }

    static func trackThemeChanged(_ theme: String) {
        trackEvent("theme_changed", properties: ["theme": theme])
    }

    static func trackShareCard() {
        trackEvent("share_card_generated")
    }

    static func trackOnboardingCompleted() {
        trackEvent("onboarding_completed")
    }

    static func trackNotificationPermission(granted: Bool) {
        trackEvent("notification_permission", properties: ["granted": "\(granted)"])
    }
}
