# StoreKit 2 Implementation Research — Subscription-Based iOS App (2025–2026)

> Compiled March 2026. Covers iOS 15+ (StoreKit 2 baseline), with iOS 17+ SwiftUI views and WWDC 2025 updates through iOS 18.4+.

---

## Table of Contents

1. [Setting Up Auto-Renewable Subscriptions in App Store Connect](#1-setting-up-auto-renewable-subscriptions-in-app-store-connect)
2. [Product Configuration — Monthly, Yearly, Lifetime](#2-product-configuration--monthly-yearly-lifetime)
3. [Paywall UI Patterns in SwiftUI](#3-paywall-ui-patterns-in-swiftui)
4. [Free Trial Implementation](#4-free-trial-implementation)
5. [Introductory Offers and Promotional Offers](#5-introductory-offers-and-promotional-offers)
6. [Transaction Handling and Entitlement Management](#6-transaction-handling-and-entitlement-management)
7. [Receipt Validation — Server-Side vs On-Device](#7-receipt-validation--server-side-vs-on-device)
8. [Subscription Status Tracking with Product.SubscriptionInfo](#8-subscription-status-tracking-with-productsubscriptioninfo)
9. [Restore Purchases Flow](#9-restore-purchases-flow)
10. [Testing with StoreKit Configuration Files and Xcode Sandbox](#10-testing-with-storekit-configuration-files-and-xcode-sandbox)
11. [RevenueCat vs Native StoreKit 2 Tradeoffs](#11-revenuecat-vs-native-storekit-2-tradeoffs)
12. [App Store Server Notifications V2](#12-app-store-server-notifications-v2)

---

## 1. Setting Up Auto-Renewable Subscriptions in App Store Connect

### Steps

1. **App Store Connect → My Apps → Your App → Subscriptions** (not "In-App Purchases" — that section is for consumables/non-consumables).
2. **Create a Subscription Group** — a group contains related tiers (e.g., "Pro" group with monthly and yearly). Users can only have one active subscription per group. Apple handles upgrades/downgrades/crossgrades within a group automatically.
3. **Add subscriptions** to the group — each with a unique **Product ID** (e.g., `com.yourapp.pro.monthly`), reference name, duration, and price.
4. **Set pricing** — choose a price tier or custom price. Apple handles currency conversion per storefront.
5. **Add localized display names and descriptions** for each subscription.
6. **Submit for review** — subscriptions must be submitted with a binary that uses them.

### Key Configuration

- **Subscription Group ID** — used for `SubscriptionStoreView` and `subscriptionStatusTask`
- **Grace Period** — enable in App Store Connect to give users extra days when billing fails (6 or 16 days)
- **Billing Retry** — Apple automatically retries failed renewals for up to 60 days

### Required Capabilities

In Xcode: Target → Signing & Capabilities → add **In-App Purchase** capability.

---

## 2. Product Configuration — Monthly, Yearly, Lifetime

### Recommended Product Structure

| Product | Type | Product ID Example | Notes |
|---------|------|--------------------|-------|
| Monthly | Auto-renewable subscription | `com.yourapp.pro.monthly` | Most flexible, lower commitment |
| Yearly | Auto-renewable subscription | `com.yourapp.pro.yearly` | Higher LTV, usually discounted (e.g., "Save 50%") |
| Lifetime | Non-consumable IAP | `com.yourapp.pro.lifetime` | One-time purchase, lives under "In-App Purchases" not "Subscriptions" |

### Important Notes

- Monthly and Yearly go in the **same Subscription Group** — Apple handles upgrade/downgrade logic automatically within a group.
- Lifetime is a **non-consumable** in-app purchase, configured under "In-App Purchases" (separate from the subscription group).
- `SubscriptionStoreView` **does not support mixing** subscriptions with non-consumable lifetime purchases. You'll need a custom paywall or `ProductView` if you offer lifetime alongside subscriptions.
- **Never hardcode prices** — always use `product.displayPrice` for localized pricing.
- Serve product identifiers from a remote source in production to allow swapping products without an app update.

### Fetching Products

```swift
import StoreKit

let productIds = ["pro_monthly", "pro_yearly", "pro_lifetime"]

@MainActor
class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    
    func fetchProducts() async {
        do {
            products = try await Product.products(for: productIds)
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }
}
```

---

## 3. Paywall UI Patterns in SwiftUI

### Three Approaches (from simplest to most custom)

#### Approach A: `SubscriptionStoreView` (iOS 17+, least code)

Best for subscription-only paywalls (no lifetime option). One line of code renders a full paywall with pricing, trial eligibility, restore button, and purchase flow.

```swift
import StoreKit

struct PaywallView: View {
    var body: some View {
        SubscriptionStoreView(groupID: "YOUR_SUBSCRIPTION_GROUP_ID") {
            // Custom marketing header
            VStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.yellow)
                
                Text("Unlock Premium")
                    .font(.largeTitle.bold())
                
                Text("Get access to all features")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .subscriptionStorePolicyDestination(
            url: URL(string: "https://yourapp.com/privacy")!,
            for: .privacyPolicy
        )
        .subscriptionStorePolicyDestination(
            url: URL(string: "https://yourapp.com/terms")!,
            for: .termsOfService
        )
        .onInAppPurchaseCompletion { product, result in
            // Handle completion — dismiss paywall, etc.
        }
    }
}
```

**Pros:** Handles trial eligibility, restore, accessibility, localized pricing automatically.  
**Cons:** Limited styling. Cannot include lifetime purchases. No multi-page paywalls.

#### Approach B: `ProductView` building blocks (iOS 17+, moderate customization)

Mix different `productViewStyle` options (`.large`, `.regular`, `.compact`) to build custom layouts. Each `ProductView` handles its own purchase flow.

```swift
struct CustomPaywallView: View {
    var body: some View {
        ScrollView {
            // Featured yearly plan
            ProductView(id: "com.yourapp.pro.yearly") { _ in
                Image(systemName: "crown")
                    .resizable()
                    .scaledToFit()
            } placeholderIcon: {
                ProgressView()
            }
            .productViewStyle(.large)
            
            // Other options
            VStack(spacing: 16) {
                ProductView(id: "com.yourapp.pro.monthly")
                    .productViewStyle(.compact)
                ProductView(id: "com.yourapp.pro.lifetime")
                    .productViewStyle(.compact)
            }
            .padding()
            
            // Must add Restore manually with ProductView
            Button("Restore Purchases") {
                Task { try? await AppStore.sync() }
            }
        }
    }
}
```

**Pros:** Can mix subscriptions and lifetime purchases. More layout control.  
**Cons:** Must handle Restore button manually. Must manage trial eligibility display yourself.

#### Approach C: Fully custom paywall (maximum control)

Build your own UI and call `product.purchase()` directly. Necessary for advanced conversion-optimized designs.

```swift
struct FullCustomPaywallView: View {
    @StateObject private var store = StoreManager()
    @State private var selectedProduct: Product?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Custom marketing content
            FeatureListView()
            
            // Product selection
            ForEach(store.products.sorted(by: { $0.price > $1.price })) { product in
                ProductOptionRow(
                    product: product,
                    isSelected: selectedProduct?.id == product.id
                )
                .onTapGesture { selectedProduct = product }
            }
            
            // Purchase button
            Button("Continue") {
                guard let product = selectedProduct else { return }
                Task { await purchaseProduct(product) }
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedProduct == nil)
            
            Button("Restore Purchases") {
                Task { try? await AppStore.sync() }
            }
            .font(.footnote)
        }
        .task { await store.fetchProducts() }
    }
    
    func purchaseProduct(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    dismiss()
                }
            case .userCancelled:
                break
            case .pending:
                // Ask to Buy or pending approval
                break
            @unknown default:
                break
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }
}
```

### WWDC 2025: `SubscriptionOfferView` (iOS 18.4+)

A new view for merchandising individual subscription offers (promotional, win-back) with support for promotional icons from App Store Connect. Use `prefersPromotionalIcon` flag for custom icons.

### What Converts Best — Industry Patterns

- **Highlight the yearly plan** as "Best Value" with a savings badge (e.g., "Save 58%")
- **Show the free trial prominently** — "Start your 7-day free trial"
- **Feature list above pricing** — show value before asking for money
- **Single CTA button** at the bottom — reduce decision fatigue
- **Social proof** — "Join 100,000+ users"
- **Dismissible paywall** — forcing purchase increases churn and gets App Review rejections

---

## 4. Free Trial Implementation

### Configuration

Free trials are configured as **Introductory Offers** in App Store Connect:

1. Go to your subscription → Subscription Prices → Introductory Offers
2. Choose "Free" as the payment mode
3. Set duration: 3 days, 1 week, 2 weeks, 1 month, etc.

### Eligibility Check

A user is eligible for a free trial only once per subscription group. StoreKit 2 handles this automatically:

```swift
// Check if user is eligible for introductory offer
func isEligibleForTrial(_ product: Product) async -> Bool {
    guard let subscription = product.subscription else { return false }
    return await subscription.isEligibleForIntroOffer
}
```

### Displaying Trial Information

```swift
if let subscription = product.subscription,
   let introOffer = subscription.introductoryOffer {
    switch introOffer.paymentMode {
    case .freeTrial:
        Text("Start your \(introOffer.period.debugDescription) free trial")
    case .payAsYouGo:
        Text("\(introOffer.displayPrice) per \(introOffer.period.debugDescription)")
    case .payUpFront:
        Text("\(introOffer.displayPrice) for \(introOffer.period.debugDescription)")
    default:
        EmptyView()
    }
}
```

### Common Trial Durations

| Duration | Use Case |
|----------|----------|
| 3 days | Quick-try apps (utilities, tools) |
| 7 days | Most common — standard for productivity apps |
| 14 days | Complex apps where users need time to see value |
| 1 month | Enterprise / high-value apps |

### Key Rules

- **One introductory offer per subscription group per user** — Apple enforces this globally.
- `SubscriptionStoreView` **automatically shows/hides trial info** based on eligibility.
- For custom paywalls, always check `isEligibleForIntroOffer` before displaying trial messaging.

---

## 5. Introductory Offers and Promotional Offers

### Introductory Offers

Available to **new subscribers only** (never subscribed to any product in the group). Three types:

| Type | Payment Mode | Example |
|------|-------------|---------|
| Free trial | `.freeTrial` | 7 days free, then $9.99/month |
| Pay as you go | `.payAsYouGo` | $0.99/month for 3 months, then $9.99/month |
| Pay up front | `.payUpFront` | $1.99 for 2 months, then $9.99/month |

### Promotional Offers

Available to **existing or lapsed subscribers** — used for win-back and retention. Require server-side signature generation.

```swift
// Promotional offer purchase (requires server-signed signature)
func purchaseWithPromoOffer(
    product: Product,
    offerID: String,
    keyID: String,
    nonce: UUID,
    signature: Data,
    timestamp: Int
) async throws {
    let offer = Product.PurchaseOption.promotionalOffer(
        offerID: offerID,
        keyID: keyID,
        nonce: nonce,
        signature: signature,
        timestamp: timestamp
    )
    let result = try await product.purchase(options: [offer])
    // Handle result...
}
```

### WWDC 2025: Promotion Offer V2 Signatures

iOS 18.4 introduces `PromotionOfferV2SignatureCreator` using the App Store Server Library for streamlined JWS-based signing across Swift, Java, Python, and Node.js. This replaces the older ECDSA signing flow.

### Offer Codes

Redeemable codes (via URL or in-app) that grant introductory pricing. Configured in App Store Connect. Useful for marketing campaigns, influencer partnerships, etc.

---

## 6. Transaction Handling and Entitlement Management

### Core Pattern

StoreKit 2 uses two primary transaction streams:

1. **`Transaction.currentEntitlements`** — all active purchases (subscriptions + non-consumables)
2. **`Transaction.updates`** — real-time stream of new/changed transactions

### Production-Ready Store Manager

```swift
import StoreKit

@MainActor
final class Store: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var activeTransactions: Set<StoreKit.Transaction> = []
    @Published private(set) var isPro: Bool = false
    
    private var updates: Task<Void, Never>?
    
    init() {
        // Start listening for transaction updates immediately
        updates = Task {
            for await update in StoreKit.Transaction.updates {
                if let transaction = try? update.payloadValue {
                    await fetchActiveTransactions()
                    await transaction.finish()
                }
            }
        }
    }
    
    deinit {
        updates?.cancel()
    }
    
    func fetchProducts() async {
        do {
            products = try await Product.products(for: [
                "com.yourapp.pro.monthly",
                "com.yourapp.pro.yearly",
                "com.yourapp.pro.lifetime"
            ])
        } catch {
            products = []
        }
    }
    
    func fetchActiveTransactions() async {
        var active: Set<StoreKit.Transaction> = []
        
        for await entitlement in StoreKit.Transaction.currentEntitlements {
            if let transaction = try? entitlement.payloadValue {
                active.insert(transaction)
            }
        }
        
        self.activeTransactions = active
        self.isPro = !active.isEmpty
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verificationResult):
            if let transaction = try? verificationResult.payloadValue {
                activeTransactions.insert(transaction)
                isPro = true
                await transaction.finish()
            }
        case .userCancelled:
            break
        case .pending:
            // Ask to Buy — transaction arrives later via Transaction.updates
            break
        @unknown default:
            break
        }
    }
}
```

### Critical Rules

- **Always call `transaction.finish()`** — unfinished transactions will be re-delivered. Only finish after content is unlocked.
- **Start `Transaction.updates` listener at app launch** — catches deferred purchases (Ask to Buy), renewals, revocations, and refunds.
- **Always verify transactions** — use `payloadValue` (throws on verification failure) or switch on `.verified`/`.unverified` cases.
- **StoreKit 2 handles verification automatically** — transactions are JWS-signed. The `VerificationResult` type confirms the signature is valid.

### App Account Token

Link transactions to your user accounts:

```swift
let options: Set<Product.PurchaseOption> = [
    .appAccountToken(UUID()) // Your user ID as UUID
]
let result = try await product.purchase(options: options)
```

---

## 7. Receipt Validation — Server-Side vs On-Device

### StoreKit 2 Changes Everything

With StoreKit 1, receipt validation was the biggest pain point. StoreKit 2 fundamentally changes this:

- **Transactions are JWS-signed** (JSON Web Signature) — cryptographically signed by Apple
- **On-device verification is built in** — `VerificationResult.verified` / `.unverified` handles it
- **No more receipt parsing** — `Transaction.currentEntitlements` replaces the monolithic receipt

### On-Device Validation (Recommended for most apps)

```swift
for await result in Transaction.currentEntitlements {
    switch result {
    case .verified(let transaction):
        // Transaction is cryptographically verified by StoreKit
        // Safe to grant entitlements
        grantAccess(for: transaction.productID)
    case .unverified(let transaction, let error):
        // Verification failed — do NOT grant access
        print("Unverified transaction: \(error)")
    }
}
```

**When on-device is sufficient:**
- Apple-only app (no Android/web)
- No need for cross-platform subscription sharing
- No custom analytics beyond App Store Connect
- Simple entitlement model

### Server-Side Validation (Recommended for production apps with backends)

Use the **App Store Server API** (REST, JWT-authenticated):

| Endpoint | Purpose |
|----------|---------|
| `GET /inApps/v1/history/{originalTransactionId}` | Full purchase history |
| `GET /inApps/v1/subscriptions/{originalTransactionId}` | All subscription statuses |
| `GET /inApps/v1/transactions/{transactionId}` | Single transaction info |
| `GET /inApps/v1/refundHistory/{originalTransactionId}` | Refund history |

**When server-side is necessary:**
- Cross-platform apps (iOS + Android + Web)
- Need to notify users of billing issues via push/email
- Want deeper analytics (LTV, cohort analysis)
- Need to extend subscription dates, handle support cases
- Win-back campaigns for lapsed subscribers

### Hybrid Approach (Best Practice)

1. **On-device** for immediate entitlement — fast, works offline
2. **Server-side** for source of truth — handles edge cases, billing issues, analytics
3. **App Store Server Notifications V2** — real-time server updates

### Important: Price is Not in Transactions

The App Store Server API does **not** include price or currency in transaction data. The iOS app must send `product.price` and `product.displayPrice` to your server for LTV tracking.

---

## 8. Subscription Status Tracking with Product.SubscriptionInfo

### Using `subscriptionStatusTask` (iOS 17+, SwiftUI)

The cleanest way to observe subscription state reactively:

```swift
@main
struct MyApp: App {
    @State private var isPro = false
    
    var body: some Scene {
        WindowGroup {
            ContentView(isPro: isPro)
                .subscriptionStatusTask(for: "YOUR_GROUP_ID") { taskState in
                    if let statuses = taskState.value {
                        isPro = !statuses
                            .filter { $0.state != .revoked && $0.state != .expired }
                            .isEmpty
                    } else {
                        isPro = false
                    }
                }
        }
    }
}
```

### Subscription States

```swift
// Product.SubscriptionInfo.RenewalState
.subscribed       // Active subscription
.expired          // Subscription has expired
.inBillingRetryPeriod  // Payment failed, Apple is retrying
.inGracePeriod    // Payment failed but grace period is active
.revoked          // Refunded or family sharing revoked
```

### Manual Status Check

```swift
func checkSubscriptionStatus(for groupID: String) async -> Bool {
    guard let statuses = try? await Product.SubscriptionInfo.status(
        for: groupID
    ) else {
        return false
    }
    
    for status in statuses {
        guard case .verified(let renewalInfo) = status.renewalInfo,
              case .verified(let transaction) = status.transaction else {
            continue
        }
        
        switch status.state {
        case .subscribed, .inGracePeriod:
            return true
        case .inBillingRetryPeriod:
            // Optionally grant access during retry
            return true
        case .expired, .revoked:
            continue
        default:
            continue
        }
    }
    return false
}
```

### Handling Upgrades/Downgrades

Upgrades and downgrades within a subscription group are automatic:

```swift
func changeSubscription(to newProduct: Product) async throws {
    // StoreKit handles upgrade/downgrade automatically
    // when products are in the same subscription group
    let result = try await newProduct.purchase()
    // Process result as normal
}
```

### Offline Behavior

`Transaction.currentEntitlements` caches data locally and pushes new transactions when online. Users retain access offline based on cached entitlements, though the device needs internet periodically to refresh.

---

## 9. Restore Purchases Flow

### StoreKit 2 Makes Restore (Mostly) Unnecessary

`Transaction.currentEntitlements` automatically includes all active purchases — even those made on other devices. By checking entitlements on app launch, you effectively auto-restore.

```swift
// On app launch
func onAppLaunch() async {
    await store.fetchActiveTransactions()
    // This already includes purchases from other devices
}
```

### Still Need a Restore Button

Apple requires a visible "Restore Purchases" option per App Review Guidelines. Implementation:

```swift
func restorePurchases() async throws {
    // Syncs with App Store servers to get latest transaction state
    try await AppStore.sync()
    // Then refresh entitlements
    await fetchActiveTransactions()
}
```

### In the Paywall

```swift
// SubscriptionStoreView includes Restore automatically
SubscriptionStoreView(groupID: "YOUR_GROUP_ID")
// Restore button is built in

// For custom paywalls — add it manually
Button("Restore Purchases") {
    Task {
        do {
            try await AppStore.sync()
            await store.fetchActiveTransactions()
        } catch {
            // Show error to user
        }
    }
}
.font(.footnote)
```

### StoreView Restore Button Control

```swift
StoreView(ids: productIds)
    .storeButton(.visible, for: .restorePurchases)
```

---

## 10. Testing with StoreKit Configuration Files and Xcode Sandbox

### StoreKit Configuration File (Local Testing)

The fastest way to test purchases during development — no App Store Connect needed, no network required.

#### Setup

1. **File → New → File → StoreKit Configuration File** (e.g., `Products.storekit`)
2. Click **"+"** → Add Subscription Group or Add In-App Purchase
3. Configure products matching your production product IDs
4. **Edit Scheme → Run → Options → StoreKit Configuration** → select your `.storekit` file

> ⚠️ Do **not** select "Sync this file with an app in App Store Connect" for local testing — it adds unnecessary complexity.

#### Testing Capabilities

- Purchase flow (success, cancellation, failure)
- Subscription renewals (accelerated — renewals happen in minutes)
- Billing issues and billing retry
- Refunds
- Promotional offers and introductory offers
- Ask to Buy flow
- Grace periods
- Price increases

#### Transaction Manager

Xcode provides a Transaction Manager (Debug → StoreKit → Manage Transactions) to:
- View all transactions
- Approve/decline Ask to Buy
- Trigger refunds
- Force renewal failures

### Sandbox Testing (App Store Connect)

For testing against real App Store infrastructure:

1. Create **Sandbox Apple IDs** in App Store Connect → Users & Access → Sandbox Testers
2. Configure **renewal rate** per sandbox account (1x, 2x, 3x, etc.)
3. Change **storefront** per sandbox account for price testing
4. Subscriptions auto-renew at accelerated rates:

| Real Duration | Sandbox Duration |
|---------------|-----------------|
| 1 week | 3 minutes |
| 1 month | 5 minutes |
| 2 months | 10 minutes |
| 3 months | 15 minutes |
| 6 months | 30 minutes |
| 1 year | 1 hour |

### Testing Workflow

```
1. StoreKit Config File  → Unit tests, development, Xcode Previews
2. Sandbox               → Integration testing, server notification testing
3. TestFlight            → Beta testing with real users (sandbox transactions)
4. Production            → Live App Store
```

### Xcode Previews Support

StoreKit views work in Xcode Previews when a StoreKit configuration file is set in the scheme — you can see your paywall without running on a device.

---

## 11. RevenueCat vs Native StoreKit 2 Tradeoffs

### Native StoreKit 2

| Pros | Cons |
|------|------|
| Zero dependencies | Must build/maintain your own backend for server-side validation |
| No third-party SDK costs | No built-in cross-platform subscription sharing |
| Full control over implementation | No remote paywall configuration |
| Apple's latest APIs immediately | No A/B testing framework for paywalls |
| No revenue share to third party | No built-in analytics beyond App Store Connect |
| Works offline with local verification | Must handle billing retry notifications yourself |
| SwiftUI views (iOS 17+) reduce code dramatically | No dashboard for customer support/subscription management |

### RevenueCat

| Pros | Cons |
|------|------|
| Cross-platform SDK (iOS, Android, Flutter, React Native, Web) | Revenue share: free up to $2,500 MTR, then 1% (Starter), 0.5-0.65% (Pro/Scale) |
| Server-side infrastructure managed for you | Third-party dependency |
| Paywall templates + remote configuration | SDK updates may lag Apple releases |
| A/B testing for paywalls built in | Some 3rd-party analytics SDKs don't fully support SK2 purchases via RevenueCat |
| Entitlements dashboard + customer support tools | Adds SDK size to your binary |
| Handles StoreKit 1 ↔ StoreKit 2 migration | Less control over edge cases |
| Revenue analytics, cohort analysis, LTV tracking | Vendor lock-in risk |
| Webhook integrations (Slack, Mixpanel, Firebase, etc.) | |

### Decision Framework

**Choose Native StoreKit 2 when:**
- Apple-only app with simple subscription tiers
- You want zero dependencies and full control
- Your app has < $10K MTR and you want to avoid any revenue share
- You have iOS 17+ as minimum target (SwiftUI views simplify everything)
- You're building a new app and can use `SubscriptionStoreView`

**Choose RevenueCat when:**
- Cross-platform app (iOS + Android)
- You need paywall A/B testing
- You want remote paywall configuration without App Store review
- You need analytics beyond App Store Connect
- You want managed server infrastructure
- Speed to market matters (integration in ~1 hour vs days/weeks)
- Team doesn't have StoreKit expertise

### Cost Reality Check

A developer with StoreKit experience estimates roughly **2 full-time weeks** (~80 hours) to build a production-grade native StoreKit implementation. RevenueCat's Starter plan ($119/month) equates to about 2.5 days of freelance billable time, making it cost-effective for most indie developers and small teams.

### Middle Ground: Native StoreKit + Observer Mode

You can use native StoreKit 2 for purchases while running RevenueCat in "observer mode" for analytics only — avoiding full SDK dependency for the purchase flow while getting dashboards and integrations.

---

## 12. App Store Server Notifications V2

### Overview

Server-to-server notifications that inform your backend of subscription lifecycle events in real time. V1 is deprecated — use V2.

### Setup

1. **App Store Connect → App → App Information → App Store Server Notifications**
2. Set **Production Server URL** (HTTPS endpoint on your server)
3. Set **Sandbox Server URL** (can be the same or different)
4. Choose **Version 2**

### Notification Types (V2)

| Type | Subtype | Description |
|------|---------|-------------|
| `SUBSCRIBED` | `INITIAL_BUY` | New subscription |
| `SUBSCRIBED` | `RESUBSCRIBE` | User re-subscribed after expiry |
| `DID_RENEW` | — | Successful renewal |
| `DID_FAIL_TO_RENEW` | `GRACE_PERIOD` | Billing failed, grace period active |
| `DID_FAIL_TO_RENEW` | — | Billing failed, no grace period |
| `EXPIRED` | `VOLUNTARY` | User cancelled |
| `EXPIRED` | `BILLING_RETRY` | Expired after billing retry exhausted |
| `EXPIRED` | `PRICE_INCREASE` | User didn't consent to price increase |
| `DID_CHANGE_RENEWAL_PREF` | `UPGRADE` | Upgraded plan |
| `DID_CHANGE_RENEWAL_PREF` | `DOWNGRADE` | Downgraded (takes effect at next renewal) |
| `DID_CHANGE_RENEWAL_STATUS` | `AUTO_RENEW_ENABLED` | Re-enabled auto-renew |
| `DID_CHANGE_RENEWAL_STATUS` | `AUTO_RENEW_DISABLED` | Turned off auto-renew |
| `REFUND` | — | Transaction was refunded |
| `REVOKE` | — | Family sharing access revoked |
| `CONSUMPTION_REQUEST` | — | Apple asking for consumption info (refund decision) |
| `OFFER_REDEEMED` | — | Promo/offer code redeemed |

### Payload Format

V2 notifications are JWS-signed (same format as StoreKit 2 transactions). Verify the signature using the x5c certificate chain:

1. Extract the x5c certificate chain from the JWS header
2. Validate each certificate is issued by the next in the chain
3. Verify the root certificate fingerprint matches Apple's Root CA - G3
4. Validate the JWS signature using the leaf certificate's public key

### Server Library

Apple provides official server libraries for signature verification and JWT generation:
- **Swift**, **Java**, **Python**, **Node.js**

```python
# Python example using apple-app-store-server-library
from appstoreserverlibrary.signed_data_verifier import SignedDataVerifier

verifier = SignedDataVerifier(
    root_certificates,
    enable_online_checks=True,
    environment=Environment.PRODUCTION,
    bundle_id="com.yourapp",
    app_apple_id=123456789
)

notification = verifier.verify_and_decode_notification(signed_payload)
```

### Best Practices

- **Process notifications idempotently** — you may receive duplicates
- **Apply updates immediately** — upgrades and refunds are time-sensitive
- **Handle duplicates from on-device + server** — the app sends transactions via `Transaction.updates`, and your server receives the same events via notifications. Your backend must deduplicate.
- **Use notification history endpoint** to catch missed notifications:  
  `GET /inApps/v2/notifications/history`
- **Respond with HTTP 200** quickly — Apple retries on failure

### Complementary: App Store Server API

For on-demand queries (not just push notifications):

```
GET /inApps/v1/subscriptions/{originalTransactionId}
```

Returns all subscription statuses for a user. Use as a fallback when notifications are missed, or for customer support lookups.

---

## Quick Reference: Minimum iOS Versions

| Feature | Minimum iOS |
|---------|------------|
| StoreKit 2 (core) | iOS 15 |
| `Product.products(for:)` | iOS 15 |
| `Transaction.currentEntitlements` | iOS 15 |
| `Transaction.updates` | iOS 15 |
| `ProductView`, `StoreView` | iOS 17 |
| `SubscriptionStoreView` | iOS 17 |
| `subscriptionStatusTask` | iOS 17 |
| `onInAppPurchaseCompletion` | iOS 17 |
| `PurchaseAction` environment value | iOS 18.2 |
| `SubscriptionOfferView` | iOS 18.4 |
| `appTransactionID` (backdeployed) | iOS 15 |

---

## Sources

1. Apple Developer — StoreKit 2 Overview: https://developer.apple.com/storekit/
2. Apple WWDC 2025 — What's New in StoreKit: https://developer.apple.com/videos/play/wwdc2025/241/
3. RevenueCat — iOS In-App Subscription Tutorial with StoreKit 2: https://www.revenuecat.com/blog/engineering/ios-in-app-subscription-tutorial-with-storekit-2-and-swift/
4. RevenueCat — StoreKit Views Guide: https://www.revenuecat.com/blog/engineering/storekit-views-guide-paywall-swift-ui/
5. Superwall — StoreKit 2 Tutorial: https://superwall.com/blog/make-a-swiftui-app-with-in-app-purchases-and-subscriptions-using-storekit-2/
6. Swift with Majid — Mastering StoreKit 2: https://swiftwithmajid.com/2023/08/01/mastering-storekit2/
7. Swift with Majid — StoreKit 2 View Modifiers: https://swiftwithmajid.com/2023/08/29/mastering-storekit2-swiftui-view-modifiers/
8. Create with Swift — Implementing Subscriptions (Dec 2025): https://www.createwithswift.com/implementing-subscriptions-in-app-purchases-with-storekit-2/
9. Apple Developer Documentation — App Store Server Notifications V2: https://developer.apple.com/documentation/AppStoreServerNotifications/App-Store-Server-Notifications-V2
10. RevenueCat — StoreKit 1 vs 2 Migration: https://www.revenuecat.com/blog/engineering/migrating-from-storekit-1-to-storekit-2/
11. RevenueCat — StoreKit With and Without RevenueCat: https://www.revenuecat.com/blog/engineering/implementing-storekit/
12. Qonversion — App Store Server API Guide: https://qonversion.io/blog/app-store-server-api
13. DEV Community — StoreKit 2 WWDC 2025 Updates: https://dev.to/arshtechpro/wwdc-2025-whats-new-in-storekit-and-in-app-purchase-31if
14. Apple Developer Forums — currentEntitlements offline behavior: https://developer.apple.com/forums/thread/706450
