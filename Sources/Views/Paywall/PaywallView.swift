import AudioToolbox
import StoreKit
import SwiftUI

/// Paywall ekranı — premium özelliklerin kapısı.
/// Research-backed design: comparison table, social proof, price anchoring,
/// urgency text, and a huge trial CTA.
/// Shows "You're Premium! ✨" state if already subscribed.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    @State private var selectedProduct: Product?
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var showRestoreError = false
    @State private var restoreErrorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if subscriptionManager.isSubscribed {
                    premiumActiveView
                } else {
                    paywallContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.shared.lightTap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.adaptiveTitle3(isRegular: isRegular))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityIdentifier("closeButton")
                    .accessibilityLabel("Close paywall")
                }
            }
            .task {
                await subscriptionManager.loadProducts()
                if selectedProduct == nil {
                    withAnimation(.tapSpring) {
                        selectedProduct = subscriptionManager.yearlyProduct
                    }
                }
            }
            .alert("Purchase Failed", isPresented: $showError) {
                Button("Try Again") {
                    guard let product = selectedProduct else { return }
                    Task {
                        let success = await subscriptionManager.purchase(product)
                        if success { dismiss() }
                        else if let error = subscriptionManager.purchaseError, !error.isEmpty {
                            errorMessage = error
                            showError = true
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Something went wrong with your purchase. Please try again.")
            }
            .alert("Restore Failed", isPresented: $showRestoreError) {
                Button("Try Again") {
                    Task {
                        await subscriptionManager.restorePurchases()
                        if case let .failed(msg) = subscriptionManager.restoreResult {
                            restoreErrorMessage = msg
                            showRestoreError = true
                        } else if case .noPurchasesFound = subscriptionManager.restoreResult {
                            restoreErrorMessage = "No previous purchases found. If you believe this is an error, contact Apple Support."
                            showRestoreError = true
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(restoreErrorMessage ?? "Couldn't restore purchases. Please check your connection and try again.")
            }
        }
    }

    // MARK: - Already Subscribed State

    private var premiumActiveView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                // Radial glow
                RadialGradient(
                    colors: [
                        themeManager.selectedTheme.accent.opacity(0.4),
                        themeManager.selectedTheme.accent.opacity(0.08),
                        .clear,
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: 80
                )
                .frame(width: 160, height: 160)

                Image(systemName: "crown.fill")
                    .font(.adaptiveDisplay(size: 60, weight: .regular, design: .default, isRegular: isRegular))
                    .foregroundStyle(themeManager.selectedTheme.accentGradient)
                    .shadow(color: themeManager.selectedTheme.accent.opacity(0.5), radius: 16, y: 4)
            }

            Text("You're Premium! ✨")
                .font(.adaptiveDisplay(size: 28, weight: .bold, design: .rounded, isRegular: isRegular))

            Text("All features are unlocked. Enjoy your full fasting experience.")
                .font(.adaptiveSubheadline(isRegular: isRegular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Feature list
            VStack(alignment: .leading, spacing: 12) {
                PremiumActiveFeature(icon: "clock.badge.checkmark", text: "Unlimited history")
                PremiumActiveFeature(icon: "chart.bar.fill", text: "Full charts & reports")
                PremiumActiveFeature(icon: "paintpalette.fill", text: "All 8 themes")
                PremiumActiveFeature(icon: "square.and.arrow.up", text: "CSV export")
                PremiumActiveFeature(icon: "scalemass.fill", text: "Weight tracking")
                PremiumActiveFeature(icon: "bolt.fill", text: "Streak tracking")
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal, 8)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Continue Fasting")
                    .font(.adaptiveBody(isRegular: isRegular).weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(themeManager.selectedTheme.accentGradient)
                    )
            }
            .buttonStyle(.pressable)
            .padding(.bottom, 16)
        }
        .padding()
        .entranceAnimation(delay: 0.1)
    }

    // MARK: - Paywall Content (Not Subscribed)

    private var paywallContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                    .entranceAnimation(delay: 0.1)

                // Urgency banner
                urgencyBanner
                    .entranceAnimation(delay: 0.15)

                // What you get with Pro — comparison table
                comparisonTable
                    .entranceAnimation(delay: 0.2)

                // Social proof
                socialProofBanner
                    .entranceAnimation(delay: 0.25)

                // Products — monthly first (price anchor), yearly with badge
                productsSection
                    .entranceAnimation(delay: 0.3)

                // CTA — huge trial button
                purchaseButton
                    .entranceAnimation(delay: 0.35)

                // Legal
                legalSection
            }
            .padding()
            .frame(maxWidth: isRegular ? 600 : .infinity)
            .frame(maxWidth: .infinity)
        }
        .background(
            // Glassmorphism gradient background
            ZStack {
                LinearGradient(
                    colors: [
                        themeManager.selectedTheme.accent.opacity(0.08),
                        Color(.systemBackground),
                        themeManager.selectedTheme.accent.opacity(0.04),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
        )
    }

    // MARK: - Header

    private var headerSection: some View {
        let accent = themeManager.selectedTheme.accent
        return VStack(spacing: 12) {
            ZStack {
                // Radial glow behind icon
                RadialGradient(
                    colors: [accent.opacity(0.3), accent.opacity(0.05), .clear],
                    center: .center,
                    startRadius: 10,
                    endRadius: 60
                )
                .frame(width: 120, height: 120)

                // Brand leaf with sparkle overlay — matches app icon
                ZStack {
                    Image(systemName: "leaf.fill")
                        .font(.adaptiveDisplay(size: 40, weight: .regular, design: .default, isRegular: isRegular))
                        .scaleEffect(x: -1)
                        .foregroundStyle(themeManager.selectedTheme.accentGradient)

                    Image(systemName: "sparkles")
                        .font(.adaptiveHeadline(isRegular: isRegular))
                        .foregroundStyle(.white.opacity(0.9))
                        .offset(x: 16, y: -16)
                }
                .shadow(color: accent.opacity(0.4), radius: 12, y: 4)
            }

            Text("Lumifaste Premium")
                .font(.adaptiveTitle2(isRegular: isRegular).weight(.bold))

            Text("Unlock your full fasting potential")
                .font(.adaptiveSubheadline(isRegular: isRegular))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Lumifaste Premium. Unlock your full fasting potential.")
    }

    // MARK: - Urgency Banner

    private var urgencyBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "gift.fill")
                .font(.adaptiveSubheadline(isRegular: isRegular))
                .foregroundStyle(.orange)

            Text(subscriptionManager.heroBannerText)
                .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(subscriptionManager.heroBannerText)
    }

    // MARK: - Comparison Table (What You Get with Pro)

    private var comparisonTable: some View {
        let accent = themeManager.selectedTheme.accent

        return VStack(spacing: 0) {
            // Section header
            Text("WHAT YOU GET WITH PRO")
                .font(.adaptiveBadge(isRegular: isRegular).weight(.bold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)

            // Column headers
            HStack {
                Text("Feature")
                    .font(.adaptiveCaption(isRegular: isRegular).weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Free")
                    .font(.adaptiveCaption(isRegular: isRegular).weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 70)

                Text("Pro")
                    .font(.adaptiveCaption(isRegular: isRegular).weight(.bold))
                    .foregroundStyle(accent)
                    .frame(width: 70)
            }
            .padding(.bottom, 8)

            Divider().opacity(0.3)

            // Comparison rows — spec: History, Charts, Themes, Export, Custom Plans, Challenges, Journal, Streak, Notifications, Achievements
            ComparisonRow(feature: "Fasting history", freeValue: .limited("7 days"), proValue: .check("Unlimited"))
            ComparisonRow(feature: "Charts & stats", freeValue: .limited("Basic"), proValue: .check("Full"))
            ComparisonRow(feature: "Themes", freeValue: .limited("3"), proValue: .check("8"))
            ComparisonRow(feature: "CSV export", freeValue: .missing, proValue: .check("Export"))
            ComparisonRow(feature: "Custom plans", freeValue: .missing, proValue: .check("Create"))
            ComparisonRow(feature: "Challenges", freeValue: .limited("1"), proValue: .check("All"))
            ComparisonRow(feature: "Journal", freeValue: .limited("Mood only"), proValue: .check("Full"))
            ComparisonRow(feature: "Streak protection", freeValue: .missing, proValue: .check("Freeze"))
            ComparisonRow(feature: "Smart alerts", freeValue: .limited("Basic"), proValue: .check("All"))
            ComparisonRow(feature: "Achievements", freeValue: .limited("5"), proValue: .check("13"))
            ComparisonRow(feature: "Recipes", freeValue: .limited("10"), proValue: .check("20"))
        }
        .padding(16)
        .background(
            ZStack {
                // Glassmorphism background
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pro comparison table. Unlimited history, full charts, 8 themes, CSV export, custom plans, all challenges, and full journal with Pro.")
    }

    // MARK: - Social Proof

    private var socialProofBanner: some View {
        HStack(spacing: 10) {
            // People stack icon
            ZStack {
                ForEach(0 ..< 3, id: \.self) { i in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    [Color.blue, Color.purple, Color.green][i],
                                    [Color.cyan, Color.pink, Color.teal][i],
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 26, height: 26)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.adaptiveBadge(isRegular: isRegular))
                                .foregroundStyle(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                        .offset(x: CGFloat(i) * 16)
                }
            }
            .frame(width: 60, alignment: .leading)

            Text("Join 10,000+ fasters who chose Pro")
                .font(.adaptiveDetail(isRegular: isRegular).weight(.medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Join 10,000 plus fasters who chose Pro")
    }

    // MARK: - Products (Price Anchoring: Monthly first, Yearly with badge)

    private var productsSection: some View {
        let accent = themeManager.selectedTheme.accent
        return VStack(spacing: 12) {
            if subscriptionManager.isLoadingProducts {
                ProgressView()
                    .padding()
            } else if subscriptionManager.productsLoadFailed {
                VStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.adaptiveTitle2(isRegular: isRegular))
                        .foregroundStyle(.secondary)
                    Text("Couldn't load prices")
                        .font(.system(.headline, design: .rounded))
                    Text("Check your internet connection and tap to retry.")
                        .font(.adaptiveDetail(isRegular: isRegular))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .onTapGesture {
                    Task { await subscriptionManager.loadProducts() }
                }
            } else {
                // Monthly FIRST — price anchor
                if let monthly = subscriptionManager.monthlyProduct {
                    ProductCard(
                        product: monthly,
                        label: "Monthly",
                        badge: nil,
                        perMonthText: nil,
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

                // Yearly — SAVE badge + Most Popular ribbon
                if let yearly = subscriptionManager.yearlyProduct {
                    ProductCard(
                        product: yearly,
                        label: "Yearly",
                        badge: "MOST POPULAR",
                        perMonthText: subscriptionManager.yearlyMonthlyEquivalent.map { "\($0)/mo" },
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
            }
        }
    }

    // MARK: - Purchase Button (Huge Trial CTA)

    private var purchaseButton: some View {
        VStack(spacing: 10) {
            // Huge green gradient CTA
            Button {
                HapticManager.shared.mediumTap()
                guard let product = selectedProduct else { return }
                Task {
                    let success = await subscriptionManager.purchase(product)
                    if success {
                        HapticManager.shared.success()
                        SubscriptionManager.playCelebrationSound()
                        dismiss()
                    } else if let error = subscriptionManager.purchaseError, !error.isEmpty {
                        errorMessage = error
                        showError = true
                    }
                }
            } label: {
                VStack(spacing: 4) {
                    HStack {
                        if subscriptionManager.isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))
                            Text(subscriptionManager.ctaLabel(for: selectedProduct))
                                .font(.adaptiveHeadline(isRegular: isRegular).weight(.bold))
                        }
                    }

                    if !subscriptionManager.isPurchasing {
                        Text(subscriptionManager.ctaSubtitle(for: selectedProduct))
                            .font(.adaptiveCaption(isRegular: isRegular).weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.78, blue: 0.35),
                                    Color(red: 0.0, green: 0.65, blue: 0.55),
                                    themeManager.selectedTheme.accent,
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: Color.green.opacity(0.45), radius: 20, y: 8)
                .shadow(color: Color.teal.opacity(0.3), radius: 10, y: 4)
                .shadow(color: themeManager.selectedTheme.accent.opacity(0.2), radius: 6, y: 2)
            }
            .buttonStyle(.pressable)
            .disabled(selectedProduct == nil || subscriptionManager.isPurchasing)

            // Trust indicators
            HStack(spacing: 16) {
                TrustIndicator(icon: "lock.shield.fill", text: "Secure payment")
                TrustIndicator(icon: "xmark.circle", text: "Cancel anytime")
                TrustIndicator(icon: "hand.raised.fill", text: "No commitment")
            }
            .padding(.top, 4)

            if let error = subscriptionManager.purchaseError {
                Text(error)
                    .font(.adaptiveDetail(isRegular: isRegular))
                    .foregroundStyle(.red)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // Restore
            Button("Restore Purchases") {
                HapticManager.shared.lightTap()
                Task {
                    await subscriptionManager.restorePurchases()
                    if case let .failed(msg) = subscriptionManager.restoreResult {
                        restoreErrorMessage = msg
                        showRestoreError = true
                    } else if case .noPurchasesFound = subscriptionManager.restoreResult {
                        restoreErrorMessage = "No previous purchases found. If you believe this is an error, contact Apple Support."
                        showRestoreError = true
                    } else if subscriptionManager.isSubscribed {
                        dismiss()
                    }
                }
            }
            .font(.adaptiveDetail(isRegular: isRegular))
            .foregroundStyle(.secondary)
            .accessibilityLabel("Restore purchases")
            .accessibilityHint("Restores previously purchased subscriptions")
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 6) {
            // Apple Guideline 3.1.2(c): must clearly disclose trial duration (if any),
            // recurring price, auto-renewal, and cancellation path — all in one place.
            Text(subscriptionManager.billingDisclosure(for: selectedProduct))
                .font(.adaptiveBadge(isRegular: isRegular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                Link("Terms of Use", destination: URL(string: "https://theknack2020-sketch.github.io/lumifaste/terms/")!)
                Link("Privacy Policy", destination: URL(string: "https://theknack2020-sketch.github.io/lumifaste/privacy/")!)
            }
            .font(.adaptiveBadge(isRegular: isRegular))
            .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Comparison Row

private enum ComparisonValue {
    case check(String)
    case limited(String)
    case missing
}

private struct ComparisonRow: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    let feature: String
    let freeValue: ComparisonValue
    let proValue: ComparisonValue

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(feature)
                    .font(.adaptiveDetail(isRegular: isRegular))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Free column
                Group {
                    switch freeValue {
                    case let .check(text):
                        Label(text, systemImage: "checkmark")
                            .font(.adaptiveCaption(isRegular: isRegular))
                            .foregroundStyle(.green)
                    case let .limited(text):
                        Text(text)
                            .font(.adaptiveCaption(isRegular: isRegular))
                            .foregroundStyle(.orange)
                    case .missing:
                        Image(systemName: "xmark")
                            .font(.adaptiveCaption(isRegular: isRegular).weight(.medium))
                            .foregroundStyle(.red.opacity(0.7))
                    }
                }
                .frame(width: 70)

                // Pro column
                Group {
                    switch proValue {
                    case let .check(text):
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark")
                                .font(.adaptiveCaption(isRegular: isRegular).weight(.bold))
                            Text(text)
                                .font(.adaptiveCaption(isRegular: isRegular))
                        }
                        .foregroundStyle(.green)
                    case let .limited(text):
                        Text(text)
                            .font(.adaptiveCaption(isRegular: isRegular))
                            .foregroundStyle(.orange)
                    case .missing:
                        Image(systemName: "xmark")
                            .font(.adaptiveCaption(isRegular: isRegular).weight(.medium))
                            .foregroundStyle(.red.opacity(0.7))
                    }
                }
                .frame(width: 70)
            }
            .padding(.vertical, 10)

            Divider().opacity(0.15)
        }
    }
}

// MARK: - Premium Active Feature

private struct PremiumActiveFeature: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.adaptiveSubheadline(isRegular: isRegular))
                .foregroundStyle(.green)
                .accessibilityHidden(true)

            Image(systemName: icon)
                .font(.adaptiveSubheadline(isRegular: isRegular))
                .foregroundStyle(.secondary)
                .frame(width: 22)
                .accessibilityHidden(true)

            Text(text)
                .font(.adaptiveSubheadline(isRegular: isRegular))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

// MARK: - Trust Indicator

private struct TrustIndicator: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.adaptiveDetail(isRegular: isRegular))
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            Text(text)
                .font(.adaptiveCaption(isRegular: isRegular).weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

// MARK: - Product Card

private struct ProductCard: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    let product: Product
    let label: String
    let badge: String?
    let perMonthText: String?
    let savings: Int
    let isSelected: Bool
    var accentColor: Color = .purple
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(label)
                                .font(.system(.headline, design: .rounded))

                            if savings > 0 {
                                Text("SAVE \(savings)%")
                                    .font(.adaptiveCaption(isRegular: isRegular).weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule().fill(
                                            LinearGradient(
                                                colors: [.green, .teal],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    )
                                    .shadow(color: .green.opacity(0.3), radius: 4, y: 2)
                            }
                        }

                        HStack(spacing: 4) {
                            Text(product.displayPrice)
                                .font(.adaptiveDetail(isRegular: isRegular))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                            Text("/ \(label.lowercased())")
                                .font(.adaptiveDetail(isRegular: isRegular))
                                .foregroundStyle(.tertiary)
                        }

                        if let perMonth = perMonthText {
                            Text("Just \(perMonth)")
                                .font(.adaptiveCaption(isRegular: isRegular).weight(.medium))
                                .foregroundStyle(accentColor)
                        }
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.adaptiveTitle2(isRegular: isRegular))
                        .foregroundStyle(isSelected ? accentColor : .secondary)
                        .animation(.tapSpring, value: isSelected)
                }
                .padding(16)
                .padding(.top, badge != nil ? 4 : 0)

                // "MOST POPULAR" ribbon
                if let badge {
                    Text(badge)
                        .font(.adaptiveSmallLabel(isRegular: isRegular).weight(.black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 0,
                                bottomLeadingRadius: 8,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 14
                            )
                            .fill(
                                LinearGradient(
                                    colors: [accentColor, accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .shadow(color: isSelected ? accentColor.opacity(0.3) : .black.opacity(0.1), radius: isSelected ? 14 : 6, y: isSelected ? 5 : 2)
            .shadow(color: isSelected ? accentColor.opacity(0.15) : .clear, radius: 6, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? accentColor : .clear, lineWidth: 2)
            )
            .animation(.tapSpring, value: isSelected)
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) plan, \(product.displayPrice)\(perMonthText.map { ", \($0)" } ?? "")\(savings > 0 ? ", save \(savings) percent" : "")\(isSelected ? ", selected" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    PaywallView()
        .environment(SubscriptionManager())
        .environment(ThemeManager())
}

// MARK: - Soft Paywall Reason

/// Reasons for showing the soft paywall — each has distinct icon, title, subtitle, and benefits.
enum SoftPaywallReason {
    case completedFasts(count: Int)
    case historyLimit
    case featureLocked(feature: String)
    case thirdFast

    var icon: String {
        switch self {
        case .completedFasts: "trophy.fill"
        case .historyLimit: "clock.badge.checkmark"
        case .featureLocked: "lock.fill"
        case .thirdFast: "flame.fill"
        }
    }

    var title: String {
        switch self {
        case let .completedFasts(count):
            "You've completed \(count) fasts! 🎉"
        case .historyLimit:
            "Your history is full"
        case let .featureLocked(feature):
            "Unlock \(feature)"
        case .thirdFast:
            "You're on a roll! 🔥"
        }
    }

    var subtitle: String {
        switch self {
        case .completedFasts:
            "You're building a great habit. Unlock deeper insights to take your fasting further."
        case .historyLimit:
            "Free accounts can view the last 7 fasts. Upgrade to see your complete fasting journey."
        case let .featureLocked(feature):
            "\(feature) is a Premium feature. Upgrade to unlock everything."
        case .thirdFast:
            "3 fasts completed — you're serious about fasting. Premium helps you go further."
        }
    }

    /// 3 key benefits shown on each soft paywall variant
    var benefits: [(icon: String, text: String)] {
        switch self {
        case .completedFasts, .thirdFast:
            [
                ("sparkles", "Understand what happens in each fasting stage"),
                ("chart.bar.fill", "Get detailed reports after every fast"),
                ("bolt.fill", "Track your streak and build consistency"),
            ]
        case .historyLimit:
            [
                ("clock.badge.checkmark", "Unlimited fasting history — all your fasts, forever"),
                ("chart.xyaxis.line", "Trend charts to visualize your progress over time"),
                ("square.and.arrow.up", "Export your data as CSV for personal records"),
            ]
        case .featureLocked:
            [
                ("lock.open.fill", "Full access to all Premium features"),
                ("paintpalette.fill", "All 8 beautiful themes to personalize your app"),
                ("scalemass.fill", "Weight tracking with trend visualization"),
            ]
        }
    }
}

// MARK: - Soft Paywall View (shown after N fasts or feature lock)

/// Non-blocking paywall suggestion — slides up as a sheet.
/// Reason-specific messaging, 3 key benefits, and trial CTA.
struct SoftPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    @State private var showFullPaywall = false

    let reason: SoftPaywallReason

    var body: some View {
        VStack(spacing: 20) {
            // Handle indicator
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            // Icon with glow
            ZStack {
                RadialGradient(
                    colors: [
                        themeManager.selectedTheme.accent.opacity(0.25),
                        .clear,
                    ],
                    center: .center,
                    startRadius: 5,
                    endRadius: 45
                )
                .frame(width: 90, height: 90)

                Image(systemName: reason.icon)
                    .font(.adaptiveDisplay(size: 36, weight: .regular, design: .default, isRegular: isRegular))
                    .foregroundStyle(themeManager.selectedTheme.accentGradient)
                    .shadow(color: themeManager.selectedTheme.accent.opacity(0.3), radius: 8, y: 3)
            }

            Text(reason.title)
                .font(.adaptiveTitle3(isRegular: isRegular).weight(.bold))
                .multilineTextAlignment(.center)

            Text(reason.subtitle)
                .font(.adaptiveSubheadline(isRegular: isRegular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            // 3 reason-specific benefits
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(reason.benefits.enumerated()), id: \.offset) { _, benefit in
                    SoftPaywallBenefit(
                        icon: benefit.icon,
                        text: benefit.text,
                        accentColor: themeManager.selectedTheme.accent
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            .padding(.horizontal, 4)

            // Trial CTA
            Button {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showFullPaywall = true
                }
            } label: {
                VStack(spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.adaptiveDetail(isRegular: isRegular))
                        Text(subscriptionManager.isEligibleForTrial ? "Start 7-Day Free Trial" : "Unlock Premium")
                            .font(.adaptiveSubheadline(isRegular: isRegular).weight(.bold))
                    }

                    Text(subscriptionManager.isEligibleForTrial ? "Cancel anytime" : "Auto-renews · Cancel anytime")
                        .font(.adaptiveBadge(isRegular: isRegular).weight(.medium))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.78, blue: 0.35),
                                    Color(red: 0.0, green: 0.65, blue: 0.55),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: Color.green.opacity(0.35), radius: 10, y: 4)
                .shadow(color: Color.teal.opacity(0.2), radius: 4, y: 2)
            }
            .buttonStyle(.pressable)

            Button("Not Now") {
                dismiss()
            }
            .font(.adaptiveSubheadline(isRegular: isRegular))
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .fullScreenCover(isPresented: $showFullPaywall) {
            PaywallView()
        }
    }
}

private struct SoftPaywallBenefit: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    let icon: String
    let text: String
    var accentColor: Color = .purple

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.adaptiveSubheadline(isRegular: isRegular))
                .foregroundStyle(accentColor)
                .frame(width: 24)
            Text(text)
                .font(.adaptiveDetail(isRegular: isRegular))
                .foregroundStyle(.primary)
        }
    }
}
