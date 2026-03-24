import SwiftUI
import SwiftData
import StoreKit

/// Settings — theme, units, export, support, legal, about.
/// All interactive elements have VoiceOver accessibility labels.
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
            List {
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
    
    // MARK: - Activity Section (Challenges & Achievements)
    
    private var activitySection: some View {
        Section {
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
                }
            }
            .accessibilityHint("View fasting challenges and your progress")
            
            NavigationLink {
                AchievementsView(achievementManager: AchievementManager())
            } label: {
                Label("Achievements", systemImage: "trophy")
            }
            .accessibilityHint("View your earned badges and milestones")
        } header: {
            Text("Activity")
        }
    }
    
    // MARK: - Premium Section
    
    private var premiumSection: some View {
        Section {
            if subscriptionManager.isSubscribed {
                HStack {
                    Label("Premium", systemImage: "crown.fill")
                        .foregroundStyle(.purple)
                    Spacer()
                    Text("Active")
                        .font(.system(.footnote, weight: .medium))
                        .foregroundStyle(.green)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Premium subscription, Active")
                
                Button {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Manage Subscription", systemImage: "creditcard")
                }
                .accessibilityHint("Opens App Store subscription management")
            } else {
                Button {
                    HapticManager.shared.lightTap()
                    showPaywall = true
                } label: {
                    HStack {
                        Label("Upgrade to Premium", systemImage: "sparkles")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(.caption2))
                            .foregroundStyle(.tertiary)
                    }
                }
                .accessibilityHint("Opens premium subscription options")
                
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
                    }
                }
                .disabled(subscriptionManager.isRestoring)
                .accessibilityHint("Restores previously purchased subscriptions")
            }
        } header: {
            Text("Subscription")
        }
    }
    
    // MARK: - Theme Section
    
    private var themeSection: some View {
        Section {
            // Theme preview card
            ThemePreviewCard(theme: themeManager.selectedTheme)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            
            // Free themes
            VStack(alignment: .leading, spacing: 10) {
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
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            
            // Premium themes
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.purple)
                    Text("PREMIUM THEMES")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.purple)
                }
                .padding(.leading, 4)
                
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
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
        } header: {
            Text("Theme")
        }
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        Section {
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
        } header: {
            Text("Appearance")
        }
    }
    
    // MARK: - Sounds & Haptics Section
    
    private var soundsSection: some View {
        Section {
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
        } header: {
            Text("Sound & Haptics")
        } footer: {
            Text("When disabled, system sounds are muted. Haptic feedback follows your device settings.")
        }
    }
    
    // MARK: - Units Section
    
    private var unitsSection: some View {
        Section {
            Picker(selection: $useMetric) {
                Text("Kilograms (kg)").tag(true)
                Text("Pounds (lbs)").tag(false)
            } label: {
                Label("Weight Unit", systemImage: "scalemass")
            }
            .accessibilityLabel("Weight unit preference")
            .accessibilityHint("Choose between kilograms and pounds for weight display")
        } header: {
            Text("Units")
        }
    }
    
    // MARK: - Data Section
    
    private var dataSection: some View {
        Section {
            Button {
                HapticManager.shared.exportCompleted()
                exportData()
            } label: {
                Label("Export Fasting History", systemImage: "square.and.arrow.up")
            }
            .disabled(sessions.isEmpty)
            .accessibilityLabel("Export fasting history as CSV")
            .accessibilityHint(sessions.isEmpty
                ? "No fasting data to export"
                : "Exports \(sessions.count) fasting sessions as a CSV file")
        } header: {
            Text("Data")
        } footer: {
            Text("Export your fasting history as a CSV file. Your data always stays on your device unless you choose to share it.")
        }
    }
    
    // MARK: - Share Section
    
    private var shareSection: some View {
        Section {
            ShareLink(
                item: URL(string: "https://apps.apple.com/app/lumifaste/id6740062938")!,
                subject: Text("Check out Lumifaste"),
                message: Text("I've been using Lumifaste for intermittent fasting — no ads, just a clean timer. Give it a try!")
            ) {
                Label("Share with Friends", systemImage: "person.2")
            }
            .accessibilityHint("Share Lumifaste with friends via messages, email, or social media")
            
            Button {
                HapticManager.shared.lightTap()
                ReviewRequestManager.requestReviewIfAppropriate()
            } label: {
                Label("Rate Lumifaste", systemImage: "star")
            }
            .accessibilityHint("Rate this app in the App Store")
        } header: {
            Text("Spread the Word")
        }
    }
    
    // MARK: - Support Section
    
    private var supportSection: some View {
        Section {
            Button {
                HapticManager.shared.lightTap()
                sendSupportEmail()
            } label: {
                Label("Contact Support", systemImage: "envelope")
            }
            .accessibilityLabel("Contact support by email")
            .accessibilityHint("Opens email to send feedback or get help")
            
            Button {
                showHealthDisclaimer = true
            } label: {
                Label("Health Disclaimer", systemImage: "heart.text.square")
            }
            .accessibilityHint("View important health and safety information")
        } header: {
            Text("Support")
        }
    }
    
    // MARK: - Legal Section
    
    private var legalSection: some View {
        Section {
            Link(destination: URL(string: "https://theknack2020-sketch.github.io/lumifaste/privacy/")!) {
                HStack {
                    Label("Privacy Policy", systemImage: "hand.raised")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(.caption2))
                        .foregroundStyle(.tertiary)
                }
            }
            .accessibilityHint("Opens privacy policy in your browser")
            
            Link(destination: URL(string: "https://theknack2020-sketch.github.io/lumifaste/terms/")!) {
                HStack {
                    Label("Terms of Use", systemImage: "doc.text")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(.caption2))
                        .foregroundStyle(.tertiary)
                }
            }
            .accessibilityHint("Opens terms of use in your browser")
        } header: {
            Text("Legal")
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("App version \(appVersion)")
        } header: {
            Text("About")
        } footer: {
            Text("Made with ❤️ for your health journey.\nLumifaste — No ads. No tricks. Just results.")
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
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
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.red)
                        
                        Text("Health Disclaimer")
                            .font(.system(.title2, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
                    
                    disclaimerSection(
                        title: "Not Medical Advice",
                        text: "Lumifaste is a wellness tracking tool designed to help you monitor your intermittent fasting schedule. It does not provide medical advice, diagnosis, or treatment."
                    )
                    
                    disclaimerSection(
                        title: "Consult Your Doctor",
                        text: "Always consult a qualified healthcare professional before starting any fasting program, especially if you have diabetes, eating disorders, are pregnant or breastfeeding, take medications, or have any chronic health condition."
                    )
                    
                    disclaimerSection(
                        title: "Listen to Your Body",
                        text: "If you feel dizzy, faint, or unwell during a fast, stop fasting immediately and eat. Fasting is not suitable for everyone, and your health and safety should always come first."
                    )
                    
                    disclaimerSection(
                        title: "Fasting Stage Information",
                        text: "The fasting stages and their descriptions shown in this app are based on general scientific research. Individual results vary significantly based on metabolism, diet, exercise, and many other factors. The times shown are approximate averages, not guarantees."
                    )
                    
                    disclaimerSection(
                        title: "Your Data",
                        text: "All your health and fasting data is stored locally on your device. We never collect, store, or share your personal health information."
                    )
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .accessibilityLabel("Dismiss health disclaimer")
                }
            }
        }
    }
    
    private func disclaimerSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.headline))
            Text(text)
                .font(.system(.body))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [FastingSession.self, WeightEntry.self, FastingJournal.self], inMemory: true)
        .environment(SubscriptionManager())
        .environment(ThemeManager())
}
