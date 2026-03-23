import SwiftUI

/// Notification settings — per-type toggles, daily reminder time, quiet hours.
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
    
    var body: some View {
        List {
            // Permission denied banner
            if systemPermissionDenied {
                Section {
                    NotificationDeniedBanner()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
            
            // Fasting Notifications
            Section {
                Toggle(isOn: $settings.milestoneEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Milestone Alerts")
                            Text("25%, 50%, 75% progress")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "flag.checkered")
                            .foregroundStyle(.green)
                    }
                }
                
                Toggle(isOn: $settings.stageTransitionEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Stage Transitions")
                            Text("Fat Burning, Ketosis, Autophagy")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                    }
                }
                
                Toggle(isOn: $settings.fastCompleteEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Fast Complete")
                            Text("Celebration when you reach your goal")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.yellow)
                    }
                }
                
                Toggle(isOn: $settings.motivationalQuotesEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Motivational Quotes")
                            Text("Encouraging messages during fasts")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "quote.bubble.fill")
                            .foregroundStyle(.purple)
                    }
                }
            } header: {
                Text("During Fasting")
            } footer: {
                Text("These notifications are sent while you have an active fast running.")
            }
            
            // Daily Reminder
            Section {
                Toggle(isOn: $settings.dailyReminderEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Daily Reminder")
                            Text("Remind you to start a fast")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(.blue)
                    }
                }
                .onChange(of: settings.dailyReminderEnabled) { _, newValue in
                    if newValue {
                        NotificationManager.shared.scheduleDailyReminder()
                    } else {
                        NotificationManager.shared.cancelDailyReminder()
                    }
                }
                
                if settings.dailyReminderEnabled {
                    DatePicker(
                        "Reminder Time",
                        selection: reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                }
            } header: {
                Text("Reminders")
            }
            
            // Streak
            Section {
                Toggle(isOn: $settings.streakReminderEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Streak Reminder")
                            Text("Don't break your fasting streak")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.orange)
                    }
                }
            } header: {
                Text("Streak")
            } footer: {
                Text("Sends a reminder the next evening if you have an active streak of 2+ days.")
            }
            
            // Quiet Hours
            Section {
                Toggle(isOn: $settings.quietHoursEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Quiet Hours")
                            Text("Suppress notifications during sleep")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "moon.fill")
                            .foregroundStyle(.indigo)
                    }
                }
                
                if settings.quietHoursEnabled {
                    DatePicker(
                        "From",
                        selection: quietStart,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                    
                    DatePicker(
                        "Until",
                        selection: quietEnd,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                    
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text("Fast completion notifications still come through during quiet hours.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Quiet Hours")
            }
        }
        .navigationTitle("Notifications")
        .task {
            let status = await NotificationManager.shared.authorizationStatus()
            systemPermissionDenied = (status == .denied)
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
