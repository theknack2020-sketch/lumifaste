import Foundation

/// Desteklenen oruç planları.
/// Fasting window süreleri saat cinsinden.
enum FastingPlan: String, CaseIterable, Identifiable, Codable {
    case twelveTwelve = "12:12"
    case fourteenTen = "14:10"
    case sixteenEight = "16:8"
    case eighteenSix = "18:6"
    case twentyFour = "20:4"
    case omad = "OMAD"
    case fiveTwo = "5:2"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    /// Fasting window süresi (saat)
    var fastingHours: Double {
        switch self {
        case .twelveTwelve: 12
        case .fourteenTen: 14
        case .sixteenEight: 16
        case .eighteenSix: 18
        case .twentyFour: 20
        case .omad: 23
        case .fiveTwo: 24
        case .custom: 16 // default
        }
    }
    
    /// Eating window süresi (saat)
    var eatingHours: Double {
        24 - fastingHours
    }
    
    /// Fasting süresi TimeInterval olarak
    var fastingDuration: TimeInterval {
        fastingHours * 3600
    }
    
    /// Kullanıcı dostu açıklama
    var displayName: String {
        switch self {
        case .twelveTwelve: "12:12 Beginner"
        case .fourteenTen: "14:10 Easy"
        case .sixteenEight: "16:8 Popular"
        case .eighteenSix: "18:6 Intermediate"
        case .twentyFour: "20:4 Advanced"
        case .omad: "OMAD (23:1)"
        case .fiveTwo: "5:2 Weekly"
        case .custom: "Custom Plan"
        }
    }
    
    /// Kısa açıklama
    var subtitle: String {
        switch self {
        case .twelveTwelve: "12h fast · 12h eat"
        case .fourteenTen: "14h fast · 10h eat"
        case .sixteenEight: "16h fast · 8h eat"
        case .eighteenSix: "18h fast · 6h eat"
        case .twentyFour: "20h fast · 4h eat"
        case .omad: "23h fast · 1h eat"
        case .fiveTwo: "5 normal · 2 fast days"
        case .custom: "Your own schedule"
        }
    }
    
    /// Zorluk seviyesi
    var difficulty: Int {
        switch self {
        case .twelveTwelve: 1
        case .fourteenTen: 2
        case .sixteenEight: 2
        case .eighteenSix: 3
        case .twentyFour: 4
        case .omad: 5
        case .fiveTwo: 3
        case .custom: 3
        }
    }
}
