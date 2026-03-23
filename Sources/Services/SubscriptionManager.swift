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
    var isRestoring = false
    var restoreResult: RestoreResult?
    
    enum RestoreResult: Equatable {
        case success
        case noPurchasesFound
        case failed(String)
    }
    
    private let productIDs: Set<String> = [
        "com.theknack.lumifaste.premium.monthly",
        "com.theknack.lumifaste.premium.yearly"
    ]
    
    @ObservationIgnored
    nonisolated(unsafe) private var transactionListener: Task<Void, Never>?
    
    init() {
        transactionListener = listenForTransactions()
    }
    
    // Note: transactionListener uses [weak self] so it auto-stops when SubscriptionManager
    // is deallocated. No explicit cancel needed in deinit (Swift 6 deinit can't access
    // MainActor-isolated stored properties).
    
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
    
    /// Whether any product has an introductory offer (free trial)
    var hasIntroOffer: Bool {
        products.contains { $0.subscription?.introductoryOffer != nil }
    }
    
    /// Introductory offer for the selected or first available product
    func introOffer(for product: Product?) -> Product.SubscriptionOffer? {
        (product ?? products.first)?.subscription?.introductoryOffer
    }
    
    /// Human-readable trial text, e.g. "7-day free trial"
    func trialText(for product: Product?) -> String? {
        guard let offer = introOffer(for: product),
              offer.paymentMode == .freeTrial else { return nil }
        let period = offer.period
        let value = period.value
        switch period.unit {
        case .day: return "\(value)-day free trial"
        case .week: return "\(value * 7)-day free trial"
        case .month: return "\(value)-month free trial"
        case .year: return "\(value)-year free trial"
        @unknown default: return "Free trial"
        }
    }
    
    /// Monthly equivalent price text for yearly product
    var yearlyMonthlyEquivalent: String? {
        guard let yearly = yearlyProduct else { return nil }
        let monthly = yearly.price / Decimal(12)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = yearly.priceFormatStyle.locale
        return formatter.string(from: NSDecimalNumber(decimal: monthly))
    }
    
    func loadProducts() async {
        guard !isLoadingProducts else { return }
        
        isLoadingProducts = true
        productsLoadFailed = false
        purchaseError = nil
        
        logger.info("Loading products: \(self.productIDs.joined(separator: ", "))")
        
        // Exponential backoff: 1s, 2s, 4s
        for attempt in 1...3 {
            do {
                try Task.checkCancellation()
                
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
                    let delay = pow(2.0, Double(attempt - 1)) // 1, 2, 4 seconds
                    try await Task.sleep(for: .seconds(delay))
                }
            } catch is CancellationError {
                logger.info("Product load cancelled")
                isLoadingProducts = false
                return
            } catch {
                logger.error("Attempt \(attempt) failed: \(error.localizedDescription)")
                if attempt < 3 {
                    let delay = pow(2.0, Double(attempt - 1))
                    try? await Task.sleep(for: .seconds(delay))
                }
            }
        }
        
        productsLoadFailed = products.isEmpty
        isLoadingProducts = false
        
        if productsLoadFailed {
            purchaseError = "Couldn't connect to the App Store. Please check your connection and try again."
            logger.error("All product load attempts failed")
        }
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
                purchaseError = "Purchase is pending approval. You'll get access once it's confirmed."
                return false
            @unknown default:
                return false
            }
        } catch is PurchaseTimeoutError {
            purchaseError = "Purchase timed out. Please check your connection and try again."
            return false
        } catch let error as StoreKitError {
            purchaseError = friendlyStoreKitError(error)
            return false
        } catch {
            purchaseError = "Something went wrong. Please try again."
            logger.error("Purchase error: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Status
    
    func checkSubscriptionStatus() async {
        var foundActive = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productType == .autoRenewable {
                    foundActive = true
                    break
                }
            } catch {
                // Verification failed for this transaction — log and continue checking others
                logger.warning("Skipping unverified entitlement during status check")
                continue
            }
        }
        
        isSubscribed = foundActive
        logger.info("Subscription status: \(foundActive ? "active" : "inactive")")
    }
    
    // MARK: - Restore
    
    func restorePurchases() async {
        isRestoring = true
        restoreResult = nil
        defer { isRestoring = false }
        
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            restoreResult = isSubscribed ? .success : .noPurchasesFound
        } catch {
            restoreResult = .failed("Could not connect to the App Store. Please try again later.")
            logger.error("Restore failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    self.checkSubscriptionStatusSync()
                } catch {
                    // Verification failed — don't finish the transaction.
                    // StoreKit will retry verification automatically.
                    logger.warning("Transaction update verification failed — will retry automatically")
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
        case .unverified(_, let error):
            logger.error("Transaction verification failed: \(error.localizedDescription)")
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Friendly Errors
    
    private func friendlyStoreKitError(_ error: StoreKitError) -> String {
        switch error {
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .userCancelled:
            return "" // Don't show error for user cancellation
        case .notAvailableInStorefront:
            return "This subscription is not available in your region."
        case .notEntitled:
            return "You're not eligible for this offer."
        default:
            return "Something went wrong with the purchase. Please try again."
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
