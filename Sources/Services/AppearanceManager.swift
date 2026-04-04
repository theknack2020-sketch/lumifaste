import SwiftUI

/// User-selectable appearance mode: light, dark, or system.
/// Stored in UserDefaults via @AppStorage, applied at the app root via .preferredColorScheme.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String {
        rawValue
    }

    /// Map to SwiftUI's optional ColorScheme (nil = follow system)
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }
}
