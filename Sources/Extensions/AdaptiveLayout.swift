import SwiftUI

// MARK: - Adaptive Font Extension

extension Font {
    /// Minimum readable body text — never below caption on any device
    /// On iPad uses footnote (13pt) instead of caption (12pt)
    static func adaptiveCaption(isRegular: Bool) -> Font {
        isRegular ? .footnote : .caption
    }

    /// Smallest allowed text — caption on iPad, caption2 on iPhone
    /// ⚠️ Use sparingly — only for legal text, timestamps, axis labels
    static func adaptiveCaption2(isRegular: Bool) -> Font {
        isRegular ? .caption : .caption2
    }

    /// Detail text that needs to be comfortably readable
    static func adaptiveDetail(isRegular: Bool) -> Font {
        isRegular ? .subheadline : .footnote
    }

    /// Subheadline that scales up for iPad
    static func adaptiveSubheadline(isRegular: Bool) -> Font {
        isRegular ? .body : .subheadline
    }

    /// Body that scales up for iPad
    static func adaptiveBody(isRegular: Bool) -> Font {
        isRegular ? .title3 : .body
    }

    /// Headline that scales up for iPad
    static func adaptiveHeadline(isRegular: Bool) -> Font {
        isRegular ? .title3 : .headline
    }

    /// Title3 that scales for iPad
    static func adaptiveTitle3(isRegular: Bool) -> Font {
        isRegular ? .title2 : .title3
    }

    /// Title2 that scales for iPad
    static func adaptiveTitle2(isRegular: Bool) -> Font {
        isRegular ? .title : .title2
    }

    /// Large display number (timer, progress, stats)
    static func adaptiveDisplay(size: CGFloat, weight: Font.Weight = .bold, design: Font.Design = .rounded, isRegular: Bool) -> Font {
        let scaledSize = isRegular ? size * 1.25 : size
        return .system(size: scaledSize, weight: weight, design: design)
    }

    /// Scaled system font for custom sizes
    static func adaptiveSystem(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default, isRegular: Bool) -> Font {
        let scaledSize = isRegular ? size * 1.2 : size
        return .system(size: scaledSize, weight: weight, design: design)
    }

    /// Chart axis label — guaranteed readable on all devices
    static func chartAxisLabel(isRegular: Bool) -> Font {
        isRegular ? .caption : .system(size: 11, weight: .medium)
    }

    /// Badge / pill text — small but readable
    static func adaptiveBadge(isRegular: Bool) -> Font {
        isRegular ? .caption.weight(.semibold) : .system(size: 11, weight: .semibold)
    }

    /// Timer display — extra large for fasting timer
    static func timerDisplay(isRegular: Bool) -> Font {
        isRegular
            ? .system(size: 72, weight: .light, design: .rounded)
            : .system(size: 56, weight: .light, design: .rounded)
    }

    /// Section header
    static func adaptiveSectionHeader(isRegular: Bool) -> Font {
        isRegular ? .headline : .subheadline.weight(.semibold)
    }

    /// Small label (tags, badges, status)
    static func adaptiveSmallLabel(isRegular: Bool) -> Font {
        isRegular ? .footnote.weight(.medium) : .system(size: 11, weight: .medium)
    }
}

// MARK: - Adaptive Spacing

struct AdaptiveSpacing {
    let isRegular: Bool

    /// Minimum padding (8 iPhone, 12 iPad)
    var xs: CGFloat {
        isRegular ? 12 : 8
    }

    /// Small padding (12 iPhone, 16 iPad)
    var sm: CGFloat {
        isRegular ? 16 : 12
    }

    /// Standard padding (16 iPhone, 24 iPad)
    var md: CGFloat {
        isRegular ? 24 : 16
    }

    /// Large padding (20 iPhone, 32 iPad)
    var lg: CGFloat {
        isRegular ? 32 : 20
    }

    /// Extra large (24 iPhone, 40 iPad)
    var xl: CGFloat {
        isRegular ? 40 : 24
    }

    /// Section spacing (20 iPhone, 28 iPad)
    var section: CGFloat {
        isRegular ? 28 : 20
    }

    /// Card inner padding (16 iPhone, 20 iPad)
    var card: CGFloat {
        isRegular ? 20 : 16
    }
}

// MARK: - Adaptive Sizes

struct AdaptiveSizes {
    let isRegular: Bool

    /// Fasting timer ring diameter
    var timerRing: CGFloat {
        isRegular ? 380 : 280
    }

    /// Progress ring stroke width
    var ringStroke: CGFloat {
        isRegular ? 28 : 22
    }

    /// Stage icon
    var stageIcon: CGFloat {
        isRegular ? 64 : 48
    }

    /// Achievement badge
    var achievementBadge: CGFloat {
        isRegular ? 100 : 72
    }

    /// Achievement badge celebration
    var achievementCelebration: CGFloat {
        isRegular ? 130 : 100
    }

    /// Chart height
    var chartHeight: CGFloat {
        isRegular ? 260 : 200
    }

    /// Small icon circle
    var smallIcon: CGFloat {
        isRegular ? 48 : 40
    }

    /// Touch target minimum
    var touchTarget: CGFloat {
        isRegular ? 52 : 44
    }

    /// Max content width for iPad readability
    var maxContentWidth: CGFloat {
        isRegular ? 680 : .infinity
    }

    /// Paywall comparison cell height
    var paywallCell: CGFloat {
        isRegular ? 72 : 54
    }

    /// Hero icon size
    var heroIcon: CGFloat {
        isRegular ? 72 : 56
    }

    /// Onboarding illustration
    var onboardingIllustration: CGFloat {
        isRegular ? 96 : 72
    }

    /// Grid columns for achievements
    var achievementColumns: Int {
        isRegular ? 4 : 3
    }

    /// Grid columns for challenges
    var challengeColumns: Int {
        isRegular ? 3 : 2
    }

    /// Grid columns for stats
    var statsColumns: Int {
        isRegular ? 3 : 2
    }

    /// Grid columns for recipes
    var recipeColumns: Int {
        isRegular ? 3 : 2
    }
}

// MARK: - View Modifier: Adaptive Container

/// Wraps content in a centered, max-width container for iPad readability
struct AdaptiveContainerModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass
    var maxWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: sizeClass == .regular ? maxWidth : .infinity)
    }
}

extension View {
    /// Constrains width for iPad readability — centers content naturally
    func adaptiveContainer(maxWidth: CGFloat = 680) -> some View {
        modifier(AdaptiveContainerModifier(maxWidth: maxWidth))
    }

    /// Applies adaptive horizontal padding that scales with size class
    func adaptivePadding(_ isRegular: Bool) -> some View {
        padding(.horizontal, isRegular ? 32 : 16)
    }

    /// Limits Dynamic Type to prevent overflow in constrained spaces
    func limitDynamicType(_ limit: DynamicTypeSize = .accessibility1) -> some View {
        dynamicTypeSize(...limit)
    }
}

// MARK: - Adaptive Grid Helper

extension [GridItem] {
    /// Creates adaptive grid columns based on size class
    static func adaptive(
        compact compactCount: Int,
        regular regularCount: Int,
        spacing: CGFloat = 12,
        isRegular: Bool
    ) -> [GridItem] {
        let count = isRegular ? regularCount : compactCount
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: count)
    }
}
