import SwiftUI

/// Pre-permission explanation screen — shown before the system notification prompt.
/// Explains why notifications matter for fasting. Shows in onboarding and settings.
struct NotificationPermissionView: View {
    @State private var permissionGranted = false
    @State private var permissionDenied = false
    var onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 10) {
                Text("Stay on Track")
                    .font(.system(size: 26, weight: .bold))
                
                Text("Notifications help you reach your fasting goals")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Benefits list
            VStack(alignment: .leading, spacing: 14) {
                benefitRow(
                    icon: "flag.checkered",
                    color: .green,
                    title: "Milestone Alerts",
                    subtitle: "Know when you hit 25%, 50%, 75%"
                )
                benefitRow(
                    icon: "flame.fill",
                    color: .orange,
                    title: "Stage Transitions",
                    subtitle: "Find out when you enter Fat Burning, Ketosis"
                )
                benefitRow(
                    icon: "trophy.fill",
                    color: .yellow,
                    title: "Completion Celebration",
                    subtitle: "Get notified the moment you reach your goal"
                )
                benefitRow(
                    icon: "bolt.fill",
                    color: .purple,
                    title: "Streak Protection",
                    subtitle: "Gentle reminders to keep your streak alive"
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            
            Spacer()
            
            if permissionDenied {
                deniedGuidance
            } else {
                VStack(spacing: 12) {
                    Button {
                        Task {
                            let granted = await NotificationManager.shared.requestPermission()
                            if granted {
                                permissionGranted = true
                                onComplete()
                            } else {
                                permissionDenied = true
                            }
                        }
                    } label: {
                        Text("Enable Notifications")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        .linearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    
                    Button("Skip for Now") {
                        onComplete()
                    }
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
    }
    
    // MARK: - Benefit Row
    
    private func benefitRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
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
    
    // MARK: - Denial Guidance
    
    /// In-app guidance when permission is denied
    private var deniedGuidance: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text("Notifications are disabled")
                    .font(.system(size: 15, weight: .semibold))
            }
            
            Text("You can enable them anytime in Settings → Lumifaste → Notifications")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.blue)
                
                Button("Continue Without") {
                    onComplete()
                }
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Inline Denied Banner (for SettingsView)

/// Compact banner shown in settings when notifications are denied at OS level.
struct NotificationDeniedBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 18))
                .foregroundStyle(.red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Notifications Disabled")
                    .font(.system(size: 14, weight: .semibold))
                Text("Enable in iOS Settings to receive fasting alerts")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.blue)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.red.opacity(0.08))
        )
    }
}

#Preview {
    NotificationPermissionView(onComplete: {})
}
