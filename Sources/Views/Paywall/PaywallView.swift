import SwiftUI
import StoreKit

/// Paywall ekranı — premium özelliklerin kapısı.
/// Araştırma: $3.99/ay, $29.99/yıl (%37 tasarruf), 7 gün free trial.
/// Entrance animations, bounce buttons, smooth transitions.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(ThemeManager.self) private var themeManager
    @State private var selectedProduct: Product?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                        .entranceAnimation(delay: 0.1)
                    
                    // Features
                    featuresSection
                        .entranceAnimation(delay: 0.2)
                    
                    // Products
                    productsSection
                        .entranceAnimation(delay: 0.3)
                    
                    // CTA
                    purchaseButton
                        .entranceAnimation(delay: 0.4)
                    
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
                withAnimation(.tapSpring) {
                    selectedProduct = subscriptionManager.yearlyProduct
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(themeManager.selectedTheme.accentGradient)
            
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
        let accent = themeManager.selectedTheme.accent
        return VStack(alignment: .leading, spacing: 14) {
            // Free features
            Text("ALWAYS FREE")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 2)
            
            FeatureRow(icon: "timer", title: "Fasting Timer", subtitle: "All preset plans: 16:8, 18:6, 20:4, OMAD...", isFree: true)
            FeatureRow(icon: "flame.fill", title: "Fasting Stages", subtitle: "See which stage you're in", isFree: true)
            FeatureRow(icon: "bell.badge", title: "Milestone Alerts", subtitle: "Notifications at key fasting hours", isFree: true)
            FeatureRow(icon: "clock.arrow.circlepath", title: "Recent History", subtitle: "Your last 7 fasting sessions", isFree: true)
            
            Divider().padding(.vertical, 4)
            
            // Premium features
            Text("PREMIUM")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(accent)
                .padding(.bottom, 2)
            
            FeatureRow(icon: "sparkles", title: "Stage Science", subtitle: "What's happening in your body + tips", isFree: false, premiumColor: accent)
            FeatureRow(icon: "clock.badge.checkmark", title: "Unlimited History", subtitle: "All your fasts, forever", isFree: false, premiumColor: accent)
            FeatureRow(icon: "bolt.fill", title: "Streak Tracking", subtitle: "Daily streak counter and motivation", isFree: false, premiumColor: accent)
            FeatureRow(icon: "chart.bar.fill", title: "Detailed Reports", subtitle: "Stage breakdown after each fast", isFree: false, premiumColor: accent)
            FeatureRow(icon: "slider.horizontal.3", title: "Custom Plans", subtitle: "Create your own fasting schedule", isFree: false, premiumColor: accent)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Products
    
    private var productsSection: some View {
        let accent = themeManager.selectedTheme.accent
        return VStack(spacing: 12) {
            if subscriptionManager.isLoadingProducts {
                ProgressView()
                    .padding()
            } else if subscriptionManager.productsLoadFailed {
                VStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                    Text("Couldn't load prices")
                        .font(.system(size: 14, weight: .medium))
                    Text("Check your internet connection and tap to retry.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
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
                        isSelected: selectedProduct?.id == yearly.id,
                        accentColor: accent
                    ) {
                        HapticManager.shared.selectionChanged()
                        withAnimation(.tapSpring) {
                            selectedProduct = yearly
                        }
                    }
                }
                
                // Monthly
                if let monthly = subscriptionManager.monthlyProduct {
                    ProductCard(
                        product: monthly,
                        label: "Monthly",
                        badge: nil,
                        savings: 0,
                        isSelected: selectedProduct?.id == monthly.id,
                        accentColor: accent
                    ) {
                        HapticManager.shared.selectionChanged()
                        withAnimation(.tapSpring) {
                            selectedProduct = monthly
                        }
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
                        .fill(themeManager.selectedTheme.accentGradient)
                )
            }
            .buttonStyle(.bounce)
            .disabled(selectedProduct == nil || subscriptionManager.isPurchasing)
            
            if let error = subscriptionManager.purchaseError {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
            Text("Try all Premium features free for 7 days. After trial, auto-renews. Cancel anytime in Settings.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Link("Terms of Use", destination: URL(string: "https://theknack2020-sketch.github.io/lumifaste/terms/")!)
                Link("Privacy Policy", destination: URL(string: "https://theknack2020-sketch.github.io/lumifaste/privacy/")!)
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
    var isFree: Bool = false
    var premiumColor: Color = .purple
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(isFree ? .green : premiumColor)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                    if isFree {
                        Text("FREE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(.green.opacity(0.15)))
                    }
                }
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
    var accentColor: Color = .purple
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
                                    Capsule().fill(accentColor)
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
                    .foregroundStyle(isSelected ? accentColor : .secondary)
                    .animation(.tapSpring, value: isSelected)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? accentColor : .clear, lineWidth: 2)
            )
            .animation(.tapSpring, value: isSelected)
        }
        .buttonStyle(.bounce)
    }
}

#Preview {
    PaywallView()
        .environment(SubscriptionManager())
        .environment(ThemeManager())
}

// MARK: - Soft Paywall (shown after N fasts)

/// Non-blocking paywall suggestion — slides up as a banner/sheet.
/// Designed to be triggered after completing 3 fasts or accessing locked history.
struct SoftPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(ThemeManager.self) private var themeManager
    @State private var showFullPaywall = false
    
    let reason: SoftPaywallReason
    
    var body: some View {
        VStack(spacing: 20) {
            // Handle indicator
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            Image(systemName: reason.icon)
                .font(.system(size: 36))
                .foregroundStyle(themeManager.selectedTheme.accentGradient)
            
            Text(reason.title)
                .font(.system(size: 20, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text(reason.subtitle)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            // Key benefits
            VStack(alignment: .leading, spacing: 10) {
                SoftPaywallBenefit(icon: "sparkles", text: "Understand what happens in each fasting stage", accentColor: themeManager.selectedTheme.accent)
                SoftPaywallBenefit(icon: "chart.bar.fill", text: "Get detailed reports after every fast", accentColor: themeManager.selectedTheme.accent)
                SoftPaywallBenefit(icon: "bolt.fill", text: "Track your streak and build consistency", accentColor: themeManager.selectedTheme.accent)
            }
            .padding(.horizontal, 8)
            
            Button {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showFullPaywall = true
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                    Text("Try Premium Free")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(themeManager.selectedTheme.accentGradient)
                )
            }
            
            Button("Not Now") {
                dismiss()
            }
            .font(.system(size: 15))
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .sheet(isPresented: $showFullPaywall) {
            PaywallView()
        }
    }
}

enum SoftPaywallReason {
    case completedFasts(count: Int)
    case historyLimit
    
    var icon: String {
        switch self {
        case .completedFasts: "trophy.fill"
        case .historyLimit: "clock.badge.checkmark"
        }
    }
    
    var title: String {
        switch self {
        case .completedFasts(let count):
            "You've completed \(count) fasts! 🎉"
        case .historyLimit:
            "Want to see your full history?"
        }
    }
    
    var subtitle: String {
        switch self {
        case .completedFasts:
            "You're building a great habit. Unlock deeper insights to take your fasting further."
        case .historyLimit:
            "Free accounts can view the last 7 fasts. Upgrade to see your complete fasting journey."
        }
    }
}

private struct SoftPaywallBenefit: View {
    let icon: String
    let text: String
    var accentColor: Color = .purple
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(accentColor)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.primary)
        }
    }
}
