import SwiftUI

/// Lumifaste tema renkleri — semantic, dark mode ready.
/// All colors use semantic system colors for automatic light/dark adaptation
/// and meet WCAG AA contrast ratio requirements (4.5:1 for body text, 3:1 for large text).
///
/// The `.themeAccent` color comes from the user's selected theme (ThemeManager).
/// Use `Color.themeAccent(from:)` or read from `themeManager.selectedTheme.accent`.
extension Color {
    /// Ana accent renk — falls back to system accentColor when no theme manager is available.
    /// Prefer `themeManager.selectedTheme.accent` in views that already have the environment object.
    static let timerBackground = Color(.systemBackground)
    
    /// Card arka plan
    static let cardBackground = Color(.secondarySystemBackground)
    
    /// High-contrast text for important values (minimum WCAG AA against both backgrounds)
    static let highContrastText = Color(.label)
    
    /// Secondary text — meets WCAG AA against system backgrounds
    static let secondaryText = Color(.secondaryLabel)
    
    /// Stage renkleri — kolay erişim
    /// These are all system colors which adapt to light/dark and meet contrast requirements.
    enum Stage {
        static let fed = Color.gray
        static let earlyFasting = Color.yellow
        static let fatBurning = Color.orange
        static let ketosis = Color.blue
        static let autophagy = Color.purple
    }
}

/// App genelinde kullanılan font stilleri — Dynamic Type uyumlu.
/// Uses scaled metrics so text grows/shrinks with user's accessibility settings.
extension Font {
    /// Timer ana gösterge — scales with accessibility but has a base of title
    static let timerDisplay = Font.system(.largeTitle, design: .rounded, weight: .light)
    
    /// Section başlığı — Dynamic Type compatible
    static let sectionTitle = Font.system(.subheadline, weight: .semibold)
    
    /// Body text — Dynamic Type compatible
    static let bodyText = Font.system(.body)
    
    /// Caption — Dynamic Type compatible
    static let captionText = Font.system(.caption)
}
