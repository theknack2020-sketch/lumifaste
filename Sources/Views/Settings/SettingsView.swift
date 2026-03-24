import SwiftUI
import SwiftData
import StoreKit

/// Settings — theme, units, export, support, legal, about.
/// All interactive elements have VoiceOver accessibility labels.
/// Visual polish: glassmorphism cards, layered shadows, rounded typography — matches Timer.
struct SettingsView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FastingSession.startDate, order: .reverse)
    private var sessions: [FastingSession]
    
    @AppStorage("lf_appearance_mode") private var appearanceMode: String = AppearanceMode.system.rawValue
    @AppStorage("lf_weight_unit") private var useMetric = true
    @AppStorage("lf_sounds_disabled") private var soundsDisabled = false
    
    @State private var showPaywall = false
    @State private var showRestoreAlert = false
    @State private var showExportShare = false
    @State private var exportFileURL: URL?
    @State private var showHealthDisclaimer = false
    @State private var showMailError = false
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var showResetConfirm = false
    @State private var challengeManager = ChallengeManager()
    
    private var selectedAppearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceMode) ?? .system }
        nonmutating set { appearanceMode = newValue.rawValue }
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    premiumSection
                    activitySection
                    themeSection
                    appearanceSection
                    soundsSection
                    unitsSection
                    dataSection
                    shareSection
                    supportSection
                    legalSection
                    aboutSection
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showExportShare) {
                if let url = exportFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .sheet(isPresented: $showHealthDisclaimer) {
                HealthDisclaimerView()
                    .presentationDetents([.medium, .large])
            }
            .alert("Restore Purchases", isPresented: $showRestoreAlert) {
                Button("OK") {}
            } message: {
                switch subscriptionManager.restoreResult {
                case .success:
                    Text("Your Premium subscription has been restored!")
                case .noPurchasesFound:
                    Text("No previous purchases found. If you believe this is an error, contact Apple Support.")
                case .failed(let msg):
                    Text(msg)
                case nil:
                    Text("")
                }
            }
            .alert("Email Not Available", isPresented: $showMailError) {
                Button("Copy Address") {
                    UIPasteboard.general.string = "support@lumifaste.com"
                    HapticManager.shared.success()
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text("Mail is not set up on this device. You can email us at support@lumifaste.com")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "Something went wrong. Please try again.")
            }
            .alert("Reset All Data?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) {
                    let success = DataController.shared.resetAllData(context: modelContext)
                    if !success {
                        errorMessage = "Couldn't reset your data. Please try again. If this keeps happening, your device storage may be full."
                        showError = true
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your fasting sessions and weight data. This cannot be undone.")
            }
            .onAppear {
                challengeManager.evaluate(sessions: sessions)
            }
        }
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(.footnote, design: .rounded, weight: .bold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
    }
    
    // MARK: - Glass Card Modifier
    
    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
            )
    }
    
    // MARK: - Activity Section (Challenges & Achievements)
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Activity")
            
            glassCard {
                VStack(spacing: 0) {
                    NavigationLink {
                        ChallengesView(challengeManager: challengeManager)
                    } label: {
                        HStack {
                            Label("Challenges", systemImage: "flag.checkered")
                            Spacer()
                            if challengeManager.completedCount > 0 {
                                Text("\(challengeManager.completedCount)/\(challengeManager.totalCount)")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(.caption2, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.pressable)
                    .accessibilityHint("View fasting challenges and your progress")
                    
                    Divider().padding(.vertical, 10)
                    
                    NavigationLink {
                        AchievementsView(achievementManager: AchievementManager())
                    } label: {
                        HStack {
                            Label("Achievements", systemImage: "trophy")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(.caption2, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.pressable)
                    .accessibilityHint("View your earned badges and milestones")
                }
            }
        }
    }
    
    // MARK: - Premium Section
    
    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Subscription")
            
            if subscriptionManager.isSubscribed {
                // Active premium — gradient banner
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Premium Active")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                            Text("All features unlocked")
                                .font(.system(.caption))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("✓")
                            .font(.system(.title3, weight: .bold))
                            .foregroundStyle(.green)
                    }
                    
                    Divider()
                    
                    Button {
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Label("Manage Subscription", systemImage: "creditcard")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(.caption2))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.pressable)
                    .accessibilityHint("Opens App Store subscription management")
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.green.opacity(0.08), .mint.opacity(0.04)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        .shadow(color: .green.opacity(0.1), radius: 12, x: 0, y: 2)
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Premium subscription, Active")
            } else {
                glassCard {
                    VStack(spacing: 12) {
                        Button {
                            HapticManager.shared.lightTap()
                            showPaywall = true
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.purple, .pink],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white)
                                }
                                
                                Text("Upgrade to Premium")
                                    .font(.system(.subheadline, weight: .semibold))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(.caption2, weight: .semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.pressable)
                        .accessibilityHint("Opens premium subscription options")
                        
                        Divider()
                        
                        Button {
                            Task {
                                await subscriptionManager.restorePurchases()
                                showRestoreAlert = true
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Label("Restore Purchases", systemImage: "arrow.clockwise")
                                if subscriptionManager.isRestoring {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.pressable)
                        .disabled(subscriptionManager.isRestoring)
                        .accessibilityHint("Restores previously purchased subscriptions")
                    }
                }
            }
        }
    }
    
    // MARK: - Theme Section
    
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Theme")
            
            VStack(spacing: 12) {
                // Theme preview card
                ThemePreviewCard(theme: themeManager.selectedTheme)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                
                // Free themes
                glassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("FREE THEMES")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(ThemeManager.freeThemes) { theme in
                                    ThemePickerCircle(
                                        theme: theme,
                                        isSelected: themeManager.selectedTheme == theme,
                                        isLocked: false
                                    ) {
                                        HapticManager.shared.selectionChanged()
                                        withAnimation(.smooth(duration: 0.35)) {
                                            _ = themeManager.selectTheme(theme, isPremium: subscriptionManager.isSubscribed)
                                        }
                                    }
                                    .scaleEffect(themeManager.selectedTheme == theme ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: themeManager.selectedTheme == theme)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
                
                // Premium themes
                glassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.purple)
                            Text("PREMIUM THEMES")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.purple)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(ThemeManager.premiumThemes) { theme in
                                    ThemePickerCircle(
                                        theme: theme,
                                        isSelected: themeManager.selectedTheme == theme,
                                        isLocked: !subscriptionManager.isSubscribed
                                    ) {
                                        if subscriptionManager.isSubscribed {
                                            HapticManager.shared.selectionChanged()
                                            withAnimation(.smooth(duration: 0.35)) {
                                                _ = themeManager.selectTheme(theme, isPremium: true)
                                            }
                                        } else {
                                            HapticManager.shared.warning()
                                            showPaywall = true
                                        }
                                    }
                                    .scaleEffect(themeManager.selectedTheme == theme ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: themeManager.selectedTheme == theme)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Appearance")
            
            glassCard {
                Picker(selection: Binding(
                    get: { selectedAppearance },
                    set: { newValue in
                        HapticManager.shared.selectionChanged()
                        appearanceMode = newValue.rawValue
                    }
                )) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.icon)
                            .tag(mode)
                    }
                } label: {
                    Label("Appearance", systemImage: "paintbrush")
                }
                .accessibilityLabel("App appearance")
                .accessibilityHint("Choose between system, light, or dark mode")
            }
        }
    }
    
    // MARK: - Sounds & Haptics Section
    
    private var soundsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Sound & Haptics")
            
            glassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: Binding(
                        get: { !soundsDisabled },
                        set: { newValue in
                            soundsDisabled = !newValue
                            if newValue {
                                HapticManager.shared.lightTap()
                            }
                        }
                    )) {
                        Label("Sound & Haptics", systemImage: "speaker.wave.2")
                    }
                    .accessibilityLabel("Sound and haptics")
                    .accessibilityHint(soundsDisabled ? "Sounds are off. Toggle to turn on." : "Sounds are on. Toggle to turn off.")
                    
                    Text("When disabled, system sounds are muted. Haptic feedback follows your device settings.")
                        .font(.system(.caption))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
    
    // MARK: - Units Section
    
    private var unitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Units")
            
            glassCard {
                Picker(selection: $useMetric) {
                    Text("Kilograms (kg)").tag(true)
                    Text("Pounds (lbs)").tag(false)
                } label: {
                    Label("Weight Unit", systemImage: "scalemass")
                }
                .accessibilityLabel("Weight unit preference")
                .accessibilityHint("Choose between kilograms and pounds for weight display")
            }
        }
    }
    
    // MARK: - Data Section
    
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Data")
            
            glassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        HapticManager.shared.exportCompleted()
                        exportData()
                    } label: {
                        HStack {
                            Label("Export Fasting History", systemImage: "square.and.arrow.up")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(.caption2))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.pressable)
                    .disabled(sessions.isEmpty)
                    .accessibilityLabel("Export fasting history as CSV")
                    .accessibilityHint(sessions.isEmpty
                        ? "No fasting data to export"
                        : "Exports \(sessions.count) fasting sessions as a CSV file")
                    
                    Text("Export your fasting history as a CSV file. Your data always stays on your device unless you choose to share it.")
                        .font(.system(.caption))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
    
    // MARK: - Share Section
    
    private var shareSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Spread the Word")
            
            glassCard {
                VStack(spacing: 0) {
                    ShareLink(
                        item: URL(string: "https://apps.apple.com/app/lumifaste/id6740062938")!,
                        subject: Text("Check out Lumifaste"),
                        message: Text("I've been using Lumifaste for intermittent fasting — no ads, just a clean timer. Give it a try!")
                    ) {
                        HStack {
                            Label("Share with Friends", systemImage: "person.2")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(.caption2))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.pressable)
                    .accessibilityHint("Share Lumifaste with friends via messages, email, or social media")
                    
                    Divider().padding(.vertical, 10)
                    
                    Button {
                        HapticManager.shared.lightTap()
                        ReviewRequestManager.requestReviewIfAppropriate()
                    } label: {
                        HStack {
                            Label("Rate Lumifaste", systemImage: "star")
                            Spacer()
                            HStack(spacing: 2) {
                                ForEach(0..<5) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.yellow)
                                }
                            }
                        }
                    }
                    .buttonStyle(.pressable)
                    .accessibilityHint("Rate this app in the App Store")
                }
            }
        }
    }
    
    // MARK: - Support Section
    
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Support")
            
            glassCard {
                VStack(spacing: 0) {
                    Button {
                        HapticManager.shared.lightTap()
                        sendSupportEmail()
                    } label: {
                        HStack {
                            Label("Contact Support", systemImage: "envelope")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(.caption2))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel("Contact support by email")
                    .accessibilityHint("Opens email to send feedback or get help")
                    
                    Divider().padding(.vertical, 10)
                    
                    Button {
                        showHealthDisclaimer = true
                    } label: {
                        HStack {
                            Label("Health Disclaimer", systemImage: "heart.text.square")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(.caption2, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.pressable)
                    .accessibilityHint("View important health and safety information")
                    
                    Divider().padding(.vertical, 10)
                    
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        HStack {
                            Label("Notifications", systemImage: "bell.badge")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(.caption2, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.pressable)
                    .accessibilityHint("Configure fasting notification preferences")
                }
            }
        }
    }
    
    // MARK: - Legal Section
    
    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Legal")
            
            glassCard {
                VStack(spacing: 0) {
                    Link(destination: URL(string: "https://theknack2020-sketch.github.io/lumifaste/privacy/")!) {
                        HStack {
                            Label("Privacy Policy", systemImage: "hand.raised")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(.caption2))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .accessibilityHint("Opens privacy policy in your browser")
                    
                    Divider().padding(.vertical, 10)
                    
                    Link(destination: URL(string: "https://theknack2020-sketch.github.io/lumifaste/terms/")!) {
                        HStack {
                            Label("Terms of Use", systemImage: "doc.text")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(.caption2))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .accessibilityHint("Opens terms of use in your browser")
                }
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(spacing: 12) {
            // Version card with accent bar
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(themeManager.selectedTheme.accent)
                    .frame(width: 3)
                    .padding(.vertical, 4)
                
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text(appVersion)
                        .font(.system(.footnote, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("App version \(appVersion)")
            
            // Footer
            VStack(spacing: 4) {
                Text("Made with ❤️ for your health journey.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.tertiary)
                Text("Lumifaste — No ads. No tricks. Just results.")
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(.quaternary)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
        }
    }
    
    // MARK: - Actions
    
    private func exportData() {
        guard let url = FastingDataExporter.exportToFile(sessions: sessions) else {
            errorMessage = "Couldn't export your data. Please check your device storage and try again."
            showError = true
            return
        }
        exportFileURL = url
        showExportShare = true
    }
    
    private func sendSupportEmail() {
        let subject = "Lumifaste Support"
        let body = "\n\n---\nApp Version: \(appVersion)\niOS: \(UIDevice.current.systemVersion)\nDevice: \(UIDevice.current.model)"
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:support@lumifaste.com?subject=\(encodedSubject)&body=\(encodedBody)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            showMailError = true
        }
    }
    
    private func rateApp() {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id6740062938?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Share Sheet (UIKit wrapper for file sharing)

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Health Disclaimer View

struct HealthDisclaimerView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.12))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "heart.text.square.fill")
                                .font(.system(size: 38))
                                .foregroundStyle(.red)
                        }
                        .shadow(color: .red.opacity(0.15), radius: 10, x: 0, y: 4)
                        
                        Text("Health Disclaimer")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
                    
                    disclaimerSection(
                        title: "Not Medical Advice",
                        text: "Lumifaste is a wellness tracking tool designed to help you monitor your intermittent fasting schedule. It does not provide medical advice, diagnosis, or treatment.",
                        color: .blue
                    )
                    
                    disclaimerSection(
                        title: "Consult Your Doctor",
                        text: "Always consult a qualified healthcare professional before starting any fasting program, especially if you have diabetes, eating disorders, are pregnant or breastfeeding, take medications, or have any chronic health condition.",
                        color: .green
                    )
                    
                    disclaimerSection(
                        title: "Listen to Your Body",
                        text: "If you feel dizzy, faint, or unwell during a fast, stop fasting immediately and eat. Fasting is not suitable for everyone, and your health and safety should always come first.",
                        color: .orange
                    )
                    
                    disclaimerSection(
                        title: "Fasting Stage Information",
                        text: "The fasting stages and their descriptions shown in this app are based on general scientific research. Individual results vary significantly based on metabolism, diet, exercise, and many other factors. The times shown are approximate averages, not guarantees.",
                        color: .purple
                    )
                    
                    disclaimerSection(
                        title: "Your Data",
                        text: "All your health and fasting data is stored locally on your device. We never collect, store, or share your personal health information.",
                        color: .cyan
                    )
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .accessibilityLabel("Dismiss health disclaimer")
                }
            }
        }
    }
    
    private func disclaimerSection(title: String, text: String, color: Color) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color)
                .frame(width: 3)
                .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                Text(text)
                    .font(.system(.body))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [FastingSession.self, WeightEntry.self, FastingJournal.self], inMemory: true)
        .environment(SubscriptionManager())
        .environment(ThemeManager())
}
