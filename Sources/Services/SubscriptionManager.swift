import Foundation
import StoreKit
import OSLog

private let logger = Logger(subsystem: "com.theknack.lumifaste", category: "StoreKit")

@MainActor
@Observable
final class SubscriptionManager {
    
    var isSubscribed = false
    var products: [Product] = []
    var purchaseError: String?
    var isPurchasing = false
    var isLoadingProducts = false
    var productsLoadFailed = false
    
    private let productIDs: Set<String> = [
        "com.theknack.lumifaste.premium.monthly",
        "com.theknack.lumifaste.premium.yearly"
    ]
    
    nonisolated(unsafe) private var transactionListener: Task<Void, Never>?
    
    init() {
        transactionListener = listenForTransactions()
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Products
    
    var monthlyProduct: Product? {
        products.first { $0.id.contains("monthly") }
    }
    
    var yearlyProduct: Product? {
        products.first { $0.id.contains("yearly") }
    }
    
    var yearlySavingsPercent: Int {
        guard let monthly = monthlyProduct,
              let yearly = yearlyProduct else { return 0 }
        let monthlyAnnual = monthly.price * Decimal(12)
        guard monthlyAnnual > 0 else { return 0 }
        let savings = ((monthlyAnnual - yearly.price) / monthlyAnnual) * Decimal(100)
        return NSDecimalNumber(decimal: savings).intValue
    }
    
    func loadProducts() async {
        guard !isLoadingProducts else { return }
        
        isLoadingProducts = true
        productsLoadFailed = false
        purchaseError = nil
        
        logger.info("Loading products: \(self.productIDs.joined(separator: ", "))")
        
        for attempt in 1...3 {
            do {
                let loaded = try await Product.products(for: productIDs)
                    .sorted { $0.price < $1.price }
                
                logger.info("Attempt \(attempt): loaded \(loaded.count) products")
                
                if !loaded.isEmpty {
                    products = loaded
                    productsLoadFailed = false
                    isLoadingProducts = false
                    return
                }
                
                if attempt < 3 {
                    try await Task.sleep(for: .seconds(Double(attempt) * 2.0))
                }
            } catch {
                logger.error("Attempt \(attempt) failed: \(error.localizedDescription)")
                if attempt < 3 {
                    try? await Task.sleep(for: .seconds(Double(attempt) * 2.0))
                }
            }
        }
        
        productsLoadFailed = products.isEmpty
        isLoadingProducts = false
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }
        
        do {
            let result = try await withThrowingTaskGroup(of: Product.PurchaseResult.self) { group in
                group.addTask { try await product.purchase() }
                group.addTask {
                    try await Task.sleep(for: .seconds(60))
                    throw PurchaseTimeoutError()
                }
                let first = try await group.next()!
                group.cancelAll()
                return first
            }
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await checkSubscriptionStatus()
                return true
            case .userCancelled:
                return false
            case .pending:
                purchaseError = "Purchase is pending approval."
                return false
            @unknown default:
                return false
            }
        } catch is PurchaseTimeoutError {
            purchaseError = "Purchase timed out. Please try again."
            return false
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Status
    
    func checkSubscriptionStatus() async {
        var foundActive = false
        
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.productType == .autoRenewable {
                    foundActive = true
                    break
                }
            }
        }
        
        isSubscribed = foundActive
        logger.info("Subscription status: \(foundActive ? "active" : "inactive")")
    }
    
    // MARK: - Restore
    
    func restorePurchases() async {
        try? await AppStore.sync()
        await checkSubscriptionStatus()
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                if let self, let transaction = try? self.checkVerified(result) {
                    await transaction.finish()
                    self.checkSubscriptionStatusSync()
                }
            }
        }
    }
    
    private func checkSubscriptionStatusSync() {
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    private struct PurchaseTimeoutError: Error {}
}

enum SubscriptionError: LocalizedError {
    case verificationFailed
    
    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            "Purchase verification failed. Please try again."
        }
    }
}
