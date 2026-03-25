import SwiftUI

extension Font {
    /// Scaled system font that respects Dynamic Type.
    /// Use for custom-sized text that should scale with accessibility settings.
    static func scaledSystem(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        .system(size: size, weight: weight, design: design)
    }

    /// Rounded scaled font — matches app's design language.
    static func scaledRounded(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
