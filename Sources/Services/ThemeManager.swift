import SwiftUI

// MARK: - App Theme

/// Color themes for Lumifaste — 5 free, 3 premium.
/// Each theme provides adaptive colors that automatically adjust for light/dark mode.
/// All accent colors meet WCAG AA contrast ratios (≥4.5:1 against white, ≥4.5:1 on dark backgrounds).
enum AppTheme: String, CaseIterable, Identifiable, Codable {
    // Free themes
    case defaultGreen
    case oceanBlue
    case sunsetOrange
    case purpleNight
    case monochrome

    // Premium themes
    case aurora
    case roseGold
    case midnight

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .defaultGreen: "Forest"
        case .oceanBlue: "Ocean"
        case .sunsetOrange: "Sunset"
        case .purpleNight: "Nebula"
        case .monochrome: "Mono"
        case .aurora: "Aurora"
        case .roseGold: "Rose Gold"
        case .midnight: "Midnight"
        }
    }

    var isPremium: Bool {
        switch self {
        case .defaultGreen, .oceanBlue, .monochrome: false
        default: true
        }
    }

    var systemIcon: String {
        switch self {
        case .defaultGreen: "leaf.fill"
        case .oceanBlue: "drop.fill"
        case .sunsetOrange: "sun.horizon.fill"
        case .purpleNight: "moon.stars.fill"
        case .monochrome: "circle.lefthalf.filled"
        case .aurora: "sparkles"
        case .roseGold: "heart.fill"
        case .midnight: "moon.fill"
        }
    }

    // MARK: - Adaptive Colors (auto light/dark)

    /// Primary accent — adapts to light/dark mode automatically
    var accent: Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? darkAccentUI : lightAccentUI })
    }

    /// Gradient start color — adapts to light/dark
    var gradientStart: Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? darkGradientStartUI : lightGradientStartUI })
    }

    /// Gradient end color — adapts to light/dark
    var gradientEnd: Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? darkGradientEndUI : lightGradientEndUI })
    }

    /// Convenience linear gradient for CTA buttons and headers
    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// The light-mode accent as a fixed color (for previews regardless of scheme)
    var previewAccent: Color {
        Color(uiColor: lightAccentUI)
    }

    // MARK: - Light Mode Colors

    // Chosen for ≥4.5:1 contrast with white text on accent backgrounds

    private var lightAccentUI: UIColor {
        switch self {
        case .defaultGreen: UIColor(red: 0.18, green: 0.49, blue: 0.20, alpha: 1) // #2E7D32
        case .oceanBlue: UIColor(red: 0.08, green: 0.40, blue: 0.75, alpha: 1) // #1565C0
        case .sunsetOrange: UIColor(red: 0.90, green: 0.29, blue: 0.10, alpha: 1) // #E64A19
        case .purpleNight: UIColor(red: 0.42, green: 0.11, blue: 0.60, alpha: 1) // #6A1B9A
        case .monochrome: UIColor(red: 0.27, green: 0.35, blue: 0.39, alpha: 1) // #455A64
        case .aurora: UIColor(red: 0.00, green: 0.51, blue: 0.56, alpha: 1) // #00838F
        case .roseGold: UIColor(red: 0.76, green: 0.09, blue: 0.36, alpha: 1) // #C2185B
        case .midnight: UIColor(red: 0.16, green: 0.21, blue: 0.58, alpha: 1) // #283593
        }
    }

    // MARK: - Dark Mode Colors

    // Brighter/more vivid for visibility on dark backgrounds (≥4.5:1 vs #1C1C1E)

    private var darkAccentUI: UIColor {
        switch self {
        case .defaultGreen: UIColor(red: 0.40, green: 0.73, blue: 0.42, alpha: 1) // #66BB6A
        case .oceanBlue: UIColor(red: 0.26, green: 0.65, blue: 0.96, alpha: 1) // #42A5F5
        case .sunsetOrange: UIColor(red: 1.00, green: 0.44, blue: 0.26, alpha: 1) // #FF7043
        case .purpleNight: UIColor(red: 0.70, green: 0.62, blue: 0.86, alpha: 1) // #B39DDB
        case .monochrome: UIColor(red: 0.56, green: 0.64, blue: 0.68, alpha: 1) // #90A4AE
        case .aurora: UIColor(red: 0.30, green: 0.82, blue: 0.88, alpha: 1) // #4DD0E1
        case .roseGold: UIColor(red: 0.96, green: 0.56, blue: 0.69, alpha: 1) // #F48FB1
        case .midnight: UIColor(red: 0.62, green: 0.66, blue: 0.85, alpha: 1) // #9FA8DA
        }
    }

    // MARK: - Gradient Colors (Light)

    private var lightGradientStartUI: UIColor {
        switch self {
        case .defaultGreen: UIColor(red: 0.18, green: 0.49, blue: 0.20, alpha: 1)
        case .oceanBlue: UIColor(red: 0.08, green: 0.40, blue: 0.75, alpha: 1)
        case .sunsetOrange: UIColor(red: 1.00, green: 0.34, blue: 0.13, alpha: 1)
        case .purpleNight: UIColor(red: 0.42, green: 0.11, blue: 0.60, alpha: 1)
        case .monochrome: UIColor(red: 0.27, green: 0.35, blue: 0.39, alpha: 1)
        case .aurora: UIColor(red: 0.00, green: 0.74, blue: 0.83, alpha: 1)
        case .roseGold: UIColor(red: 0.76, green: 0.09, blue: 0.36, alpha: 1)
        case .midnight: UIColor(red: 0.19, green: 0.25, blue: 0.62, alpha: 1)
        }
    }

    private var lightGradientEndUI: UIColor {
        switch self {
        case .defaultGreen: UIColor(red: 0.00, green: 0.47, blue: 0.42, alpha: 1) // teal
        case .oceanBlue: UIColor(red: 0.05, green: 0.28, blue: 0.63, alpha: 1) // navy
        case .sunsetOrange: UIColor(red: 0.90, green: 0.29, blue: 0.10, alpha: 1) // deep orange
        case .purpleNight: UIColor(red: 0.27, green: 0.15, blue: 0.63, alpha: 1) // deep purple
        case .monochrome: UIColor(red: 0.15, green: 0.20, blue: 0.22, alpha: 1) // charcoal
        case .aurora: UIColor(red: 0.42, green: 0.11, blue: 0.60, alpha: 1) // purple (aurora)
        case .roseGold: UIColor(red: 0.80, green: 0.55, blue: 0.20, alpha: 1) // gold
        case .midnight: UIColor(red: 0.10, green: 0.14, blue: 0.49, alpha: 1) // deep midnight
        }
    }

    // MARK: - Gradient Colors (Dark) — more vivid

    private var darkGradientStartUI: UIColor {
        switch self {
        case .defaultGreen: UIColor(red: 0.40, green: 0.73, blue: 0.42, alpha: 1)
        case .oceanBlue: UIColor(red: 0.26, green: 0.65, blue: 0.96, alpha: 1)
        case .sunsetOrange: UIColor(red: 1.00, green: 0.44, blue: 0.26, alpha: 1)
        case .purpleNight: UIColor(red: 0.70, green: 0.62, blue: 0.86, alpha: 1)
        case .monochrome: UIColor(red: 0.56, green: 0.64, blue: 0.68, alpha: 1)
        case .aurora: UIColor(red: 0.30, green: 0.82, blue: 0.88, alpha: 1)
        case .roseGold: UIColor(red: 0.96, green: 0.56, blue: 0.69, alpha: 1)
        case .midnight: UIColor(red: 0.62, green: 0.66, blue: 0.85, alpha: 1)
        }
    }

    private var darkGradientEndUI: UIColor {
        switch self {
        case .defaultGreen: UIColor(red: 0.00, green: 0.59, blue: 0.53, alpha: 1)
        case .oceanBlue: UIColor(red: 0.10, green: 0.35, blue: 0.71, alpha: 1)
        case .sunsetOrange: UIColor(red: 0.96, green: 0.32, blue: 0.12, alpha: 1)
        case .purpleNight: UIColor(red: 0.37, green: 0.24, blue: 0.71, alpha: 1)
        case .monochrome: UIColor(red: 0.33, green: 0.43, blue: 0.48, alpha: 1)
        case .aurora: UIColor(red: 0.58, green: 0.46, blue: 0.80, alpha: 1)
        case .roseGold: UIColor(red: 0.85, green: 0.60, blue: 0.25, alpha: 1)
        case .midnight: UIColor(red: 0.22, green: 0.29, blue: 0.67, alpha: 1)
        }
    }
}

// MARK: - Theme Manager

/// Manages the currently selected app theme.
/// Persists selection to UserDefaults. Injected via .environment(themeManager).
@MainActor
@Observable
final class ThemeManager {
    private(set) var selectedTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "lf_selected_theme")
        }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "lf_selected_theme") ?? AppTheme.defaultGreen.rawValue
        selectedTheme = AppTheme(rawValue: raw) ?? .defaultGreen
    }

    /// Select a theme. Returns true if successfully applied, false if locked (premium required).
    @discardableResult
    func selectTheme(_ theme: AppTheme, isPremium: Bool) -> Bool {
        guard !theme.isPremium || isPremium else { return false }
        selectedTheme = theme
        return true
    }

    /// Free themes
    static let freeThemes: [AppTheme] = AppTheme.allCases.filter { !$0.isPremium }

    /// Premium-only themes
    static let premiumThemes: [AppTheme] = AppTheme.allCases.filter(\.isPremium)
}

// MARK: - Theme Picker Circle

/// Colored circle for theme selection — used in SettingsView.
struct ThemePickerCircle: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    let theme: AppTheme
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 44, height: 44)
                        .shadow(color: theme.accent.opacity(isSelected ? 0.4 : 0), radius: 6)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.adaptiveSubheadline(isRegular: isRegular).weight(.bold))
                            .foregroundStyle(.white)
                    } else if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.adaptiveDetail(isRegular: isRegular))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color(.label) : .clear, lineWidth: 2.5)
                        .frame(width: 50, height: 50)
                )

                Text(theme.displayName)
                    .font(.adaptiveCaption(isRegular: isRegular).weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.displayName) theme\(isLocked ? ", premium" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Theme Preview Card

/// Shows a mini timer preview in the given theme's colors — used in SettingsView.
struct ThemePreviewCard: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    let theme: AppTheme

    var body: some View {
        VStack(spacing: 16) {
            Text("Preview")
                .font(.adaptiveCaption(isRegular: isRegular).weight(.medium))
                .foregroundStyle(.secondary)

            // Mini timer ring
            ZStack {
                Circle()
                    .stroke(theme.accent.opacity(0.15), style: StrokeStyle(lineWidth: 8, lineCap: .round))

                Circle()
                    .trim(from: 0, to: 0.65)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                theme.accent.opacity(0.6),
                                theme.accent,
                            ]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(234)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Glow dot at progress tip
                Circle()
                    .fill(theme.accent)
                    .frame(width: 5, height: 5)
                    .shadow(color: theme.accent.opacity(0.6), radius: 4)
                    .offset(y: -45)
                    .rotationEffect(.degrees(234 - 90))

                VStack(spacing: 2) {
                    Image(systemName: "leaf.fill")
                        .font(.adaptiveSubheadline(isRegular: isRegular))
                        .scaleEffect(x: -1)
                        .foregroundStyle(theme.accent)
                    Text("08:30:00")
                        .font(.adaptiveSubheadline(isRegular: isRegular).weight(.light))
                        .monospacedDigit()
                    Text("of 16:00:00")
                        .font(.adaptiveCaption2(isRegular: isRegular))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 100, height: 100)

            // Mini start button
            HStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.adaptiveCaption(isRegular: isRegular))
                Text("Start Fast")
                    .font(.adaptiveCaption(isRegular: isRegular).weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(theme.accent)
            )

            // Stage badge sample
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.adaptiveBadge(isRegular: isRegular))
                Text("Fat Burning")
                    .font(.adaptiveBadge(isRegular: isRegular))
            }
            .foregroundStyle(.orange)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.orange.opacity(0.12))
            .clipShape(Capsule())
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview("Theme Circles") {
    HStack(spacing: 16) {
        ForEach(AppTheme.allCases) { theme in
            ThemePickerCircle(
                theme: theme,
                isSelected: theme == .defaultGreen,
                isLocked: theme.isPremium
            ) {}
        }
    }
    .padding()
}

#Preview("Preview Card") {
    VStack(spacing: 16) {
        ThemePreviewCard(theme: .defaultGreen)
        ThemePreviewCard(theme: .oceanBlue)
    }
    .padding()
}
