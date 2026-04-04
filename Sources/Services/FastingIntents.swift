import AppIntents
import Foundation

// MARK: - Start Fast Intent

/// Siri shortcut: "Start a fast with Lumifaste"
struct StartFastIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Start a Fast"
    nonisolated(unsafe) static var description = IntentDescription("Start a 16:8 intermittent fast with Lumifaste.")
    nonisolated(unsafe) static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = FastingManager()
        guard !manager.isActive else {
            return .result(dialog: "You already have an active fast running.")
        }
        manager.startFast(plan: .sixteenEight)
        return .result(dialog: "Your 16:8 fast has started. Good luck!")
    }
}

// MARK: - Stop Fast Intent

/// Siri shortcut: "End my fast in Lumifaste"
struct StopFastIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "End My Fast"
    nonisolated(unsafe) static var description = IntentDescription("End your current fast in Lumifaste.")
    nonisolated(unsafe) static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = FastingManager()
        guard manager.isActive else {
            return .result(dialog: "You don't have an active fast right now.")
        }
        // We can't save to SwiftData without a ModelContext from the app scene,
        // so we clear state and let the app handle persistence on next foreground.
        manager.cancelFast()
        return .result(dialog: "Your fast has been ended.")
    }
}

// MARK: - Fasting Status Intent

/// Siri shortcut: "How is my fast going in Lumifaste"
struct FastingStatusIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Fasting Status"
    nonisolated(unsafe) static var description = IntentDescription("Check your current fasting status in Lumifaste.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = FastingManager()
        guard manager.isActive else {
            return .result(dialog: "You're not fasting right now. Open Lumifaste to start one!")
        }

        let hours = Int(manager.elapsedTime) / 3600
        let minutes = (Int(manager.elapsedTime) % 3600) / 60
        let stage = manager.currentStage.rawValue

        let status = if hours > 0 {
            "You've been fasting for \(hours)h \(minutes)m. Current stage: \(stage)."
        } else {
            "You've been fasting for \(minutes) minutes. Current stage: \(stage)."
        }
        return .result(dialog: "\(status)")
    }
}

// MARK: - App Shortcuts Provider

/// Registers all Lumifaste shortcuts with Siri and the Shortcuts app.
struct LumifasteShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartFastIntent(),
            phrases: [
                "Start a fast with \(.applicationName)",
                "Begin fasting in \(.applicationName)",
            ],
            shortTitle: "Start a Fast",
            systemImageName: "play.fill"
        )
        AppShortcut(
            intent: StopFastIntent(),
            phrases: [
                "End my fast in \(.applicationName)",
                "Stop fasting in \(.applicationName)",
            ],
            shortTitle: "End My Fast",
            systemImageName: "stop.fill"
        )
        AppShortcut(
            intent: FastingStatusIntent(),
            phrases: [
                "How is my fast going in \(.applicationName)",
                "Fasting status in \(.applicationName)",
            ],
            shortTitle: "Fasting Status",
            systemImageName: "clock.fill"
        )
    }
}
