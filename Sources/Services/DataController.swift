import Foundation
import SwiftData
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.theknack.lumifaste", category: "DataController")

// MARK: - SwiftData Error Handling

/// Centralized SwiftData persistence with user-visible error reporting.
/// Wraps ModelContext save operations with structured error handling.
@Observable
final class DataController: @unchecked Sendable {
    
    @MainActor
    static let shared = DataController()
    
    /// Most recent save error — views observe this to show alerts
    @MainActor var lastSaveError: DataSaveError?
    
    /// Whether a save error alert should be shown
    @MainActor var showSaveErrorAlert = false
    
    private init() {}
    
    // MARK: - Save with Error Handling
    
    /// Save the given ModelContext. Returns true on success.
    /// On failure, sets `lastSaveError` and `showSaveErrorAlert` for UI binding.
    @MainActor
    @discardableResult
    func save(_ context: ModelContext, operation: String = "save") -> Bool {
        do {
            try context.save()
            return true
        } catch {
            let saveError = DataSaveError(
                operation: operation,
                underlyingError: error,
                timestamp: .now
            )
            lastSaveError = saveError
            showSaveErrorAlert = true
            logger.error("SwiftData save failed [\(operation)]: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Save with a retry — attempts save, if fails waits briefly and retries once.
    @MainActor
    @discardableResult
    func saveWithRetry(_ context: ModelContext, operation: String = "save") async -> Bool {
        if save(context, operation: operation) { return true }
        
        // Wait 500ms and retry once
        try? await Task.sleep(for: .milliseconds(500))
        logger.info("Retrying save for [\(operation)]")
        return save(context, operation: "\(operation) (retry)")
    }
    
    // MARK: - Storage Health
    
    /// Check available device storage. Returns bytes available, or nil on error.
    func availableStorageBytes() -> Int64? {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        do {
            let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            return values.volumeAvailableCapacityForImportantUsage
        } catch {
            logger.error("Failed to check storage: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Returns true if storage is critically low (< 50 MB)
    var isStorageCriticallyLow: Bool {
        guard let bytes = availableStorageBytes() else { return false }
        return bytes < 50 * 1024 * 1024 // 50 MB
    }
    
    /// Returns true if storage is low (< 200 MB)
    var isStorageLow: Bool {
        guard let bytes = availableStorageBytes() else { return false }
        return bytes < 200 * 1024 * 1024 // 200 MB
    }
    
    /// Human-readable available storage string
    var availableStorageString: String {
        guard let bytes = availableStorageBytes() else { return "Unknown" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    // MARK: - Reset All Data
    
    /// Delete all fasting sessions and weight entries. Returns true on success.
    @MainActor
    func resetAllData(context: ModelContext) -> Bool {
        do {
            try context.delete(model: FastingSession.self)
            try context.delete(model: WeightEntry.self)
            try context.save()
            
            // Clear UserDefaults fasting state
            let keysToRemove = [
                "lf_fasting_active", "lf_fasting_start", "lf_fasting_end",
                "lf_fasting_plan", "lf_fasting_paused", "lf_fasting_pause_start",
                "lf_fasting_paused_total", "lf_fasting_water",
                "lf_completed_fasts_count", "lf_has_requested_review",
                "lf_last_review_request_date", "lf_soft_paywall_shown"
            ]
            for key in keysToRemove {
                UserDefaults.standard.removeObject(forKey: key)
            }
            
            // Cancel all notifications
            NotificationManager.shared.cancelAllNotifications()
            
            logger.info("All data reset successfully")
            return true
        } catch {
            logger.error("Failed to reset data: \(error.localizedDescription)")
            lastSaveError = DataSaveError(
                operation: "reset all data",
                underlyingError: error,
                timestamp: .now
            )
            showSaveErrorAlert = true
            return false
        }
    }
}

// MARK: - Error Type

struct DataSaveError: Identifiable {
    let id = UUID()
    let operation: String
    let underlyingError: Error
    let timestamp: Date
    
    var userMessage: String {
        "Your data couldn't be saved. Please try again. If this keeps happening, your device storage may be full."
    }
    
    var technicalDetail: String {
        underlyingError.localizedDescription
    }
}
