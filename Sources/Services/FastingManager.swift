import Foundation
import SwiftData
import SwiftUI

/// Oruç yöneticisi — timer state, persistence, stage tracking.
/// Timestamp-based: asla tick counter kullanmaz, Date.now'dan hesaplar.
@Observable
final class FastingManager {
    
    // MARK: - Persisted State (UserDefaults — survives kill)
    
    private(set) var isActive: Bool {
        didSet { UserDefaults.standard.set(isActive, forKey: "lf_fasting_active") }
    }
    
    private(set) var startDate: Date? {
        didSet { UserDefaults.standard.set(startDate, forKey: "lf_fasting_start") }
    }
    
    private(set) var targetEndDate: Date? {
        didSet { UserDefaults.standard.set(targetEndDate, forKey: "lf_fasting_end") }
    }
    
    private(set) var currentPlan: FastingPlan {
        didSet { UserDefaults.standard.set(currentPlan.rawValue, forKey: "lf_fasting_plan") }
    }
    
    // MARK: - Computed (always from Date.now)
    
    /// Geçen süre (saniye)
    var elapsedTime: TimeInterval {
        guard let start = startDate, isActive else { return 0 }
        return max(0, Date.now.timeIntervalSince(start))
    }
    
    /// Kalan süre (saniye) — target'a göre
    var remainingTime: TimeInterval {
        guard let end = targetEndDate, isActive else { return 0 }
        return max(0, end.timeIntervalSince(Date.now))
    }
    
    /// 0.0 - 1.0 arası ilerleme
    var progress: Double {
        guard let start = startDate, let end = targetEndDate, isActive else { return 0 }
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(1.0, elapsedTime / total)
    }
    
    /// Şu anki fasting stage
    var currentStage: FastingStage {
        FastingStage.stage(for: elapsedTime)
    }
    
    /// Target'ı aştık mı (bonus time)
    var isOvertime: Bool {
        guard isActive else { return false }
        return remainingTime <= 0
    }
    
    // MARK: - Init (restore from persistence)
    
    init() {
        self.isActive = UserDefaults.standard.bool(forKey: "lf_fasting_active")
        self.startDate = UserDefaults.standard.object(forKey: "lf_fasting_start") as? Date
        self.targetEndDate = UserDefaults.standard.object(forKey: "lf_fasting_end") as? Date
        let planRaw = UserDefaults.standard.string(forKey: "lf_fasting_plan") ?? FastingPlan.sixteenEight.rawValue
        self.currentPlan = FastingPlan(rawValue: planRaw) ?? .sixteenEight
    }
    
    // MARK: - Actions
    
    /// Yeni oruç başlat
    func startFast(plan: FastingPlan) {
        let now = Date.now
        startDate = now
        targetEndDate = now.addingTimeInterval(plan.fastingDuration)
        currentPlan = plan
        isActive = true
        
        // Schedule milestone notifications
        Task { @MainActor in
            _ = await NotificationManager.shared.requestPermission()
            NotificationManager.shared.scheduleFastingNotifications(startDate: now, plan: plan)
        }
    }
    
    /// Orucu bitir ve SwiftData'ya kaydet
    @discardableResult
    func endFast(context: ModelContext) -> FastingSession? {
        guard isActive, let start = startDate, let target = targetEndDate else { return nil }
        
        let session = FastingSession(
            startDate: start,
            targetEndDate: target,
            planType: currentPlan
        )
        session.complete()
        context.insert(session)
        
        // Cancel pending notifications
        Task { @MainActor in
            NotificationManager.shared.cancelAllFastingNotifications()
        }
        
        // State temizle
        isActive = false
        startDate = nil
        targetEndDate = nil
        
        return session
    }
    
    /// Orucu iptal et (kaydetmeden)
    func cancelFast() {
        isActive = false
        startDate = nil
        targetEndDate = nil
        
        Task { @MainActor in
            NotificationManager.shared.cancelAllFastingNotifications()
        }
    }
    
    /// Plan değiştir (aktif oruç yokken)
    func setPlan(_ plan: FastingPlan) {
        guard !isActive else { return }
        currentPlan = plan
    }
}
