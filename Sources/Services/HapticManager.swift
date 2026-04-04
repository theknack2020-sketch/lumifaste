import AudioToolbox
import UIKit

/// Centralized haptic & sound feedback manager.
/// Respects system haptic settings automatically — UIFeedbackGenerator
/// only fires when the user hasn't disabled haptics in Settings.
/// Sound uses AudioServicesPlaySystemSound for lightweight system sounds.
/// Sound can be disabled by the user via lf_sounds_disabled UserDefaults key.
@MainActor
final class HapticManager {
    static let shared = HapticManager()

    // Pre-warmed generators for lower latency
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()

    /// Whether system sounds are enabled (user preference).
    /// Reads from UserDefaults "lf_sounds_disabled" — false by default (sounds ON).
    private var soundsEnabled: Bool {
        !UserDefaults.standard.bool(forKey: "lf_sounds_disabled")
    }

    private init() {
        // Pre-warm all generators so first haptic isn't delayed
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        selection.prepare()
        notification.prepare()
    }

    /// Play a system sound only if sounds are enabled
    private func playSound(_ soundID: SystemSoundID) {
        guard soundsEnabled else { return }
        AudioServicesPlaySystemSound(soundID)
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
        playSound(1025) // completion chime
    }

    /// Warning — approaching limit, careful action needed
    func warning() {
        notification.notificationOccurred(.warning)
        notification.prepare()
        playSound(1306) // warning tone
    }

    /// Error — action failed
    func error() {
        notification.notificationOccurred(.error)
        notification.prepare()
        playSound(1053) // error tone
    }

    // MARK: - Compound Patterns (haptic + sound)

    /// Fast started — medium impact + subtle begin sound
    func fastStarted() {
        mediumImpact.impactOccurred()
        mediumImpact.prepare()
        playSound(1113) // subtle key-press tone
    }

    /// Fast completed — success notification + completion chime
    func fastCompleted() {
        notification.notificationOccurred(.success)
        notification.prepare()
        playSound(1025) // subtle alert tone (new mail)
    }

    /// Stage transition — light impact + tick sound
    func stageTransition() {
        lightImpact.impactOccurred()
        lightImpact.prepare()
        playSound(1057) // subtle "tock" click
    }

    /// Milestone reached during fast — double haptic for emphasis
    func milestoneReached() {
        heavyImpact.impactOccurred()
        heavyImpact.prepare()
        playSound(1057) // tock
    }

    /// Achievement unlocked — celebration chime
    func achievementUnlocked() {
        notification.notificationOccurred(.success)
        notification.prepare()
        playSound(1025) // celebration chime
    }

    /// Water logged — refreshing tick
    func waterLogged() {
        lightImpact.impactOccurred()
        lightImpact.prepare()
        playSound(1104) // subtle tick
    }

    /// Tab changed — selection tick
    func tabChanged() {
        selection.selectionChanged()
        selection.prepare()
        playSound(1104) // subtle tick
    }

    /// Plan selected — soft tock
    func planSelected() {
        selection.selectionChanged()
        selection.prepare()
        playSound(1057) // tock
    }

    /// Delete action — destructive confirmation
    func deleteAction() {
        heavyImpact.impactOccurred()
        heavyImpact.prepare()
        playSound(1073) // delete sound
    }

    /// Export completed — success chime
    func exportCompleted() {
        notification.notificationOccurred(.success)
        notification.prepare()
        playSound(1001) // mail sent chime
    }

    /// Mood selected — light feedback
    func moodSelected() {
        selection.selectionChanged()
        selection.prepare()
        playSound(1104) // subtle tick
    }

    /// Pause or resume fast — medium feedback + tone
    func pauseResume() {
        mediumImpact.impactOccurred()
        mediumImpact.prepare()
        playSound(1113) // key-press tone
    }

    /// Share action — light feedback
    func shareAction() {
        lightImpact.impactOccurred()
        lightImpact.prepare()
        playSound(1001) // chime
    }

    /// Streak celebration — heavy impact + celebration
    func streakCelebration() {
        heavyImpact.impactOccurred()
        heavyImpact.prepare()
        playSound(1025) // celebration chime
    }
}
