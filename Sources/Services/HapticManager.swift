import UIKit
import AudioToolbox

/// Centralized haptic & sound feedback manager.
/// Respects system haptic settings automatically — UIFeedbackGenerator
/// only fires when the user hasn't disabled haptics in Settings.
/// Sound uses AudioServicesPlaySystemSound for lightweight system sounds.
@MainActor
final class HapticManager {
    
    static let shared = HapticManager()
    
    // Pre-warmed generators for lower latency
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()
    
    private init() {
        // Pre-warm all generators so first haptic isn't delayed
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        selection.prepare()
        notification.prepare()
    }
    
    // MARK: - Impact Haptics
    
    /// Light tap — button presses, drink logging, minor interactions
    func lightTap() {
        lightImpact.impactOccurred()
        lightImpact.prepare()
    }
    
    /// Medium tap — start fast, important actions
    func mediumTap() {
        mediumImpact.impactOccurred()
        mediumImpact.prepare()
    }
    
    /// Heavy tap — end fast, destructive actions
    func heavyTap() {
        heavyImpact.impactOccurred()
        heavyImpact.prepare()
    }
    
    // MARK: - Selection Haptic
    
    /// Selection change — tab switches, plan picker, onboarding step changes
    func selectionChanged() {
        selection.selectionChanged()
        selection.prepare()
    }
    
    // MARK: - Notification Haptics
    
    /// Success — fast completed, goal reached
    func success() {
        notification.notificationOccurred(.success)
        notification.prepare()
    }
    
    /// Warning — approaching limit, careful action needed
    func warning() {
        notification.notificationOccurred(.warning)
        notification.prepare()
    }
    
    /// Error — action failed
    func error() {
        notification.notificationOccurred(.error)
        notification.prepare()
    }
    
    // MARK: - Compound Patterns (haptic + sound)
    
    /// Fast started — medium impact + subtle begin sound
    func fastStarted() {
        mediumImpact.impactOccurred()
        mediumImpact.prepare()
        // System sound 1113: subtle key-press tone
        AudioServicesPlaySystemSound(1113)
    }
    
    /// Fast completed — success notification + completion chime
    func fastCompleted() {
        notification.notificationOccurred(.success)
        notification.prepare()
        // System sound 1025: subtle alert tone (new mail)
        AudioServicesPlaySystemSound(1025)
    }
    
    /// Stage transition — light impact + tick sound
    func stageTransition() {
        lightImpact.impactOccurred()
        lightImpact.prepare()
        // System sound 1057: subtle "tock" click
        AudioServicesPlaySystemSound(1057)
    }
    
    /// Milestone reached during fast — double haptic for emphasis
    func milestoneReached() {
        heavyImpact.impactOccurred()
        heavyImpact.prepare()
        // System sound 1057: tock
        AudioServicesPlaySystemSound(1057)
    }
}
