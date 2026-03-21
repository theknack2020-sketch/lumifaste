import Foundation
import SwiftUI

/// Oruç aşamaları — vücutta neler oluyor.
/// Saat eşikleri araştırmadan (fasting-science.md):
///   0-4h: Fed, 4-12h: Early Fasting, 12-18h: Fat Burning, 18-24h: Ketosis, 24h+: Autophagy
enum FastingStage: String, CaseIterable, Identifiable, Codable {
    case fed = "Fed"
    case earlyFasting = "Early Fasting"
    case fatBurning = "Fat Burning"
    case ketosis = "Ketosis"
    case autophagy = "Autophagy"
    
    var id: String { rawValue }
    
    /// Bu aşamanın başladığı saat
    var startHour: Double {
        switch self {
        case .fed: 0
        case .earlyFasting: 4
        case .fatBurning: 12
        case .ketosis: 18
        case .autophagy: 24
        }
    }
    
    /// Bu aşamanın rengi
    var color: Color {
        switch self {
        case .fed: .gray
        case .earlyFasting: .yellow
        case .fatBurning: .orange
        case .ketosis: .blue
        case .autophagy: .purple
        }
    }
    
    /// SF Symbol ikonu
    var icon: String {
        switch self {
        case .fed: "fork.knife"
        case .earlyFasting: "hourglass.bottomhalf.filled"
        case .fatBurning: "flame.fill"
        case .ketosis: "bolt.fill"
        case .autophagy: "sparkles"
        }
    }
    
    /// Kısa açıklama
    var subtitle: String {
        switch self {
        case .fed: "Digesting food"
        case .earlyFasting: "Blood sugar dropping"
        case .fatBurning: "Burning stored fat"
        case .ketosis: "Producing ketones"
        case .autophagy: "Cellular cleanup"
        }
    }
    
    /// Verilen süreye göre hangi aşamadayız
    static func stage(for elapsed: TimeInterval) -> FastingStage {
        let hours = elapsed / 3600
        switch hours {
        case ..<4: return .fed
        case 4..<12: return .earlyFasting
        case 12..<18: return .fatBurning
        case 18..<24: return .ketosis
        default: return .autophagy
        }
    }
    
    /// Stage index (progress hesaplaması için)
    var index: Int {
        switch self {
        case .fed: 0
        case .earlyFasting: 1
        case .fatBurning: 2
        case .ketosis: 3
        case .autophagy: 4
        }
    }
    
    /// Sonraki stage (varsa)
    var next: FastingStage? {
        let all = FastingStage.allCases
        guard let idx = all.firstIndex(of: self), idx + 1 < all.count else { return nil }
        return all[idx + 1]
    }
}
