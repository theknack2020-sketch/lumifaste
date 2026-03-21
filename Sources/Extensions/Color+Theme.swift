import SwiftUI

/// Lumifaste tema renkleri — semantic, dark mode ready.
extension Color {
    /// Ana accent renk — calm blue-purple
    static let accent = Color.accentColor
    
    /// Timer arka plan
    static let timerBackground = Color(.systemBackground)
    
    /// Card arka plan
    static let cardBackground = Color(.secondarySystemBackground)
    
    /// Stage renkleri — kolay erişim
    enum Stage {
        static let fed = Color.gray
        static let earlyFasting = Color.yellow
        static let fatBurning = Color.orange
        static let ketosis = Color.blue
        static let autophagy = Color.purple
    }
}

/// App genelinde kullanılan font stilleri
extension Font {
    /// Timer ana gösterge
    static let timerDisplay = Font.system(size: 44, weight: .light, design: .rounded)
    
    /// Section başlığı
    static let sectionTitle = Font.system(size: 15, weight: .semibold)
    
    /// Body text
    static let bodyText = Font.system(size: 15)
    
    /// Caption
    static let caption = Font.system(size: 13)
}
