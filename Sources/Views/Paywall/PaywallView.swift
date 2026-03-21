import SwiftUI
import StoreKit

/// Paywall ekranı — premium özelliklerin kapısı.
/// Araştırma: $3.99/ay, $29.99/yıl (%37 tasarruf), 7 gün free trial
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subscriptionManager = SubscriptionManager()
    @State private var selectedProduct: Product?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Features
                    featuresSection
                    
                    // Products
                    productsSection
                    
                    // CTA
                    purchaseButton
                    
                    // Legal
                    legalSection
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .task {
                await subscriptionManager.loadProducts()
                selectedProduct = subscriptionManager.yearlyProduct
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Lumifaste Premium")
                .font(.system(size: 26, weight: .bold))
            
            Text("Unlock your full fasting potential")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Features
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Advanced Insights", subtitle: "Weekly trends, averages, and correlations")
            FeatureRow(icon: "clock.badge.checkmark", title: "Unlimited History", subtitle: "Access all your past fasting sessions")
            FeatureRow(icon: "star.fill", title: "Detailed Stages", subtitle: "Deep dive into each fasting phase")
            FeatureRow(icon: "bell.badge", title: "Smart Reminders", subtitle: "Personalized notification timing")
            FeatureRow(icon: "heart.fill", title: "No Ads. Ever.", subtitle: "Clean, distraction-free experience")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Products
    
    private var productsSection: some View {
        VStack(spacing: 12) {
            if subscriptionManager.isLoadingProducts {
                ProgressView()
                    .padding()
            } else if subscriptionManager.productsLoadFailed {
                Text("Failed to load prices. Tap to retry.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .onTapGesture {
                        Task { await subscriptionManager.loadProducts() }
                    }
            } else {
                // Yearly (recommended)
                if let yearly = subscriptionManager.yearlyProduct {
                    ProductCard(
                        product: yearly,
                        label: "Yearly",
                        badge: "BEST VALUE",
                        savings: subscriptionManager.yearlySavingsPercent,
                        isSelected: selectedProduct?.id == yearly.id
                    ) {
                        selectedProduct = yearly
                    }
                }
                
                // Monthly
                if let monthly = subscriptionManager.monthlyProduct {
                    ProductCard(
                        product: monthly,
                        label: "Monthly",
                        badge: nil,
                        savings: 0,
                        isSelected: selectedProduct?.id == monthly.id
                    ) {
                        selectedProduct = monthly
                    }
                }
            }
        }
    }
    
    // MARK: - Purchase Button
    
    private var purchaseButton: some View {
        VStack(spacing: 10) {
            Button {
                guard let product = selectedProduct else { return }
                Task {
                    let success = await subscriptionManager.purchase(product)
                    if success { dismiss() }
                }
            } label: {
                HStack {
                    if subscriptionManager.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Start 7-Day Free Trial")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            .linearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .disabled(selectedProduct == nil || subscriptionManager.isPurchasing)
            
            if let error = subscriptionManager.purchaseError {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
            }
            
            // Restore
            Button("Restore Purchases") {
                Task { await subscriptionManager.restorePurchases() }
            }
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Legal
    
    private var legalSection: some View {
        VStack(spacing: 6) {
            Text("7-day free trial, then auto-renews. Cancel anytime in Settings.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Link("Terms of Use", destination: URL(string: "https://lumifaste.com/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://lumifaste.com/privacy")!)
            }
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.purple)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Product Card

private struct ProductCard: View {
    let product: Product
    let label: String
    let badge: String?
    let savings: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(label)
                            .font(.system(size: 16, weight: .semibold))
                        
                        if let badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(.purple)
                                )
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Text(product.displayPrice)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Text("/ \(label.lowercased())")
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                        
                        if savings > 0 {
                            Text("Save \(savings)%")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? .purple : .secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.purple : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView()
}
