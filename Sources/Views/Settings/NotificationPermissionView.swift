import SwiftUI

/// Pre-permission explanation screen — shown before the system notification prompt.
/// Explains why notifications matter for fasting. Shows in onboarding and settings.
/// Visual polish: glassmorphism cards, layered shadows, accent bars — matches Timer.
struct NotificationPermissionView: View {
    @State private var permissionGranted = false
    @State private var permissionDenied = false
    @Environment(\.horizontalSizeClass) private var sizeClass
    var onComplete: () -> Void

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 100, height: 100)
                    .shadow(color: .blue.opacity(0.15), radius: 12, x: 0, y: 4)

                Image(systemName: "bell.badge.fill")
                    .font(.adaptiveDisplay(size: 44, weight: .regular, design: .default, isRegular: isRegular))
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
                    .font(.adaptiveDisplay(size: 26, weight: .bold, design: .rounded, isRegular: isRegular))

                Text("Notifications help you reach your fasting goals")
                    .font(.adaptiveSubheadline(isRegular: isRegular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Benefits list — glassmorphism card
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
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
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
                                HapticManager.shared.success()
                                onComplete()
                            } else {
                                HapticManager.shared.warning()
                                permissionDenied = true
                            }
                        }
                    } label: {
                        Text("Enable Notifications")
                            .font(.adaptiveBody(isRegular: isRegular).weight(.semibold))
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
                                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 4)
                            )
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel("Enable notifications")
                    .accessibilityHint("Requests permission to send fasting alerts and reminders")

                    Button("Skip for Now") {
                        HapticManager.shared.lightTap()
                        onComplete()
                    }
                    .font(.adaptiveSubheadline(isRegular: isRegular))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.pressable)
                    .accessibilityLabel("Skip for now")
                    .accessibilityHint("Continue without enabling notifications. You can enable them later in Settings.")
                }
            }
        }
        .padding(24)
    }

    // MARK: - Benefit Row

    private func benefitRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 34, height: 34)

                Image(systemName: icon)
                    .font(.adaptiveSubheadline(isRegular: isRegular))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))
                Text(subtitle)
                    .font(.adaptiveDetail(isRegular: isRegular))
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(subtitle)")
    }

    // MARK: - Denial Guidance

    /// In-app guidance when permission is denied
    private var deniedGuidance: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text("Notifications are disabled")
                    .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))
            }

            Text("You can enable them anytime in Settings → Lumifaste → Notifications")
                .font(.adaptiveDetail(isRegular: isRegular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Open Settings") {
                    HapticManager.shared.lightTap()
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.adaptiveSubheadline(isRegular: isRegular).weight(.medium))
                .foregroundStyle(.blue)
                .buttonStyle(.pressable)
                .accessibilityLabel("Open Settings")
                .accessibilityHint("Opens iOS Settings to enable notification permissions")

                Button("Continue Without") {
                    HapticManager.shared.lightTap()
                    onComplete()
                }
                .font(.adaptiveSubheadline(isRegular: isRegular))
                .foregroundStyle(.secondary)
                .buttonStyle(.pressable)
                .accessibilityLabel("Continue without notifications")
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.red.opacity(0.06))
                )
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Inline Denied Banner (for SettingsView)

/// Compact banner shown in settings when notifications are denied at OS level.
struct NotificationDeniedBanner: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.red.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: "bell.slash.fill")
                    .font(.adaptiveSubheadline(isRegular: isRegular))
                    .foregroundStyle(.red)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Notifications Disabled")
                    .font(.adaptiveDetail(isRegular: isRegular).weight(.semibold))
                Text("Enable in iOS Settings to receive fasting alerts")
                    .font(.adaptiveCaption(isRegular: isRegular))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Settings") {
                HapticManager.shared.lightTap()
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.adaptiveDetail(isRegular: isRegular).weight(.medium))
            .foregroundStyle(.blue)
            .buttonStyle(.pressable)
            .accessibilityLabel("Open Settings")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.red.opacity(0.06))
                )
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .shadow(color: .red.opacity(0.1), radius: 10, x: 0, y: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Notifications are disabled. Enable in iOS Settings to receive fasting alerts.")
    }
}

#Preview {
    NotificationPermissionView(onComplete: {})
}
