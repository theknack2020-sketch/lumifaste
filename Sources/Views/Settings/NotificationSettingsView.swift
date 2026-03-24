import SwiftUI

/// Notification settings — per-type toggles, daily reminder time, quiet hours.
/// Visual polish: glassmorphism cards, layered shadows, rounded typography — matches Timer.
struct NotificationSettingsView: View {
    @State private var settings = NotificationManager.shared.settings
    @State private var systemPermissionDenied = false
    @State private var showTimePicker = false
    
    /// Computed Date binding for the daily reminder time picker
    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = settings.dailyReminderHour
                components.minute = settings.dailyReminderMinute
                return Calendar.current.date(from: components) ?? Date.now
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                settings.dailyReminderHour = components.hour ?? 20
                settings.dailyReminderMinute = components.minute ?? 0
                NotificationManager.shared.scheduleDailyReminder()
            }
        )
    }
    
    /// Computed Date binding for quiet hours start
    private var quietStart: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = settings.quietHoursStart
                components.minute = 0
                return Calendar.current.date(from: components) ?? Date.now
            },
            set: { newDate in
                settings.quietHoursStart = Calendar.current.component(.hour, from: newDate)
            }
        )
    }
    
    /// Computed Date binding for quiet hours end
    private var quietEnd: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = settings.quietHoursEnd
                components.minute = 0
                return Calendar.current.date(from: components) ?? Date.now
            },
            set: { newDate in
                settings.quietHoursEnd = Calendar.current.component(.hour, from: newDate)
            }
        )
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Permission denied banner
                if systemPermissionDenied {
                    NotificationDeniedBanner()
                        .shadow(color: .red.opacity(0.15), radius: 8, x: 0, y: 4)
                }
                
                // Fasting Notifications
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader("During Fasting")
                    
                    glassCard {
                        VStack(spacing: 0) {
                            notificationToggle(
                                icon: "flag.checkered",
                                iconColor: .green,
                                title: "Milestone Alerts",
                                subtitle: "25%, 50%, 75% progress",
                                isOn: $settings.milestoneEnabled
                            )
                            
                            notificationDivider
                            
                            notificationToggle(
                                icon: "flame.fill",
                                iconColor: .orange,
                                title: "Stage Transitions",
                                subtitle: "Fat Burning, Ketosis, Autophagy",
                                isOn: $settings.stageTransitionEnabled
                            )
                            
                            notificationDivider
                            
                            notificationToggle(
                                icon: "trophy.fill",
                                iconColor: .yellow,
                                title: "Fast Complete",
                                subtitle: "Celebration when you reach your goal",
                                isOn: $settings.fastCompleteEnabled
                            )
                            
                            notificationDivider
                            
                            notificationToggle(
                                icon: "quote.bubble.fill",
                                iconColor: .purple,
                                title: "Motivational Quotes",
                                subtitle: "Encouraging messages during fasts",
                                isOn: $settings.motivationalQuotesEnabled
                            )
                        }
                    }
                    
                    Text("These notifications are sent while you have an active fast running.")
                        .font(.system(.caption))
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 4)
                }
                
                // Daily Reminder
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader("Reminders")
                    
                    glassCard {
                        VStack(spacing: 0) {
                            notificationToggle(
                                icon: "bell.badge.fill",
                                iconColor: .blue,
                                title: "Daily Reminder",
                                subtitle: "Remind you to start a fast",
                                isOn: $settings.dailyReminderEnabled
                            )
                            .onChange(of: settings.dailyReminderEnabled) { _, newValue in
                                if newValue {
                                    NotificationManager.shared.scheduleDailyReminder()
                                } else {
                                    NotificationManager.shared.cancelDailyReminder()
                                }
                            }
                            
                            if settings.dailyReminderEnabled {
                                notificationDivider
                                
                                DatePicker(
                                    "Reminder Time",
                                    selection: reminderTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(.compact)
                                .padding(.vertical, 4)
                                .accessibilityLabel("Daily reminder time")
                            }
                        }
                    }
                }
                
                // Streak
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader("Streak")
                    
                    glassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            notificationToggle(
                                icon: "bolt.fill",
                                iconColor: .orange,
                                title: "Streak Reminder",
                                subtitle: "Don't break your fasting streak",
                                isOn: $settings.streakReminderEnabled
                            )
                            
                            Text("Sends a reminder the next evening if you have an active streak of 2+ days.")
                                .font(.system(.caption))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                
                // Quiet Hours
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader("Quiet Hours")
                    
                    glassCard {
                        VStack(spacing: 0) {
                            notificationToggle(
                                icon: "moon.fill",
                                iconColor: .indigo,
                                title: "Quiet Hours",
                                subtitle: "Suppress notifications during sleep",
                                isOn: $settings.quietHoursEnabled
                            )
                            .accessibilityLabel("Quiet hours")
                            .accessibilityValue(settings.quietHoursEnabled ? "On" : "Off")
                            .accessibilityHint("Suppresses notifications during your sleep hours")
                            
                            if settings.quietHoursEnabled {
                                notificationDivider
                                
                                DatePicker(
                                    "From",
                                    selection: quietStart,
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(.compact)
                                .padding(.vertical, 4)
                                .accessibilityLabel("Quiet hours start time")
                                
                                DatePicker(
                                    "Until",
                                    selection: quietEnd,
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(.compact)
                                .padding(.vertical, 4)
                                .accessibilityLabel("Quiet hours end time")
                                
                                notificationDivider
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                    Text("Fast completion notifications still come through during quiet hours.")
                                        .font(.system(.caption))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Notifications")
        .task {
            let status = await NotificationManager.shared.authorizationStatus()
            systemPermissionDenied = (status == .denied)
        }
    }
    
    // MARK: - Toggle Row
    
    private func notificationToggle(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.subheadline, weight: .medium))
                    Text(subtitle)
                        .font(.system(.caption))
                        .foregroundStyle(.secondary)
                }
            } icon: {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(iconColor)
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private var notificationDivider: some View {
        Divider().padding(.vertical, 6)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
