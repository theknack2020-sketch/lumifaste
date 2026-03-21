import SwiftUI

/// Ayarlar ekranı — subscription status, plan, restore, about.
struct SettingsView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var showPaywall = false
    
    var body: some View {
        NavigationStack {
            List {
                // Premium Section
                Section {
                    if subscriptionManager.isSubscribed {
                        HStack {
                            Label("Premium", systemImage: "crown.fill")
                                .foregroundStyle(.purple)
                            Spacer()
                            Text("Active")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.green)
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Label("Upgrade to Premium", systemImage: "sparkles")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        
                        Button("Restore Purchases") {
                            Task { await subscriptionManager.restorePurchases() }
                        }
                    }
                } header: {
                    Text("Subscription")
                }
                
                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://theknack2020-sketch.github.io/lumifaste/privacy/")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://theknack2020-sketch.github.io/lumifaste/terms/")!) {
                        HStack {
                            Text("Terms of Use")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("About")
                }
                
                // Health Disclaimer
                Section {
                    Text("Lumifaste is a wellness tracking tool. It does not provide medical advice, diagnosis, or treatment. Consult your doctor before starting any fasting program.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Disclaimer")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(SubscriptionManager())
}
