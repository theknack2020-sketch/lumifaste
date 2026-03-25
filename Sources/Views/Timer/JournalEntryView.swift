import SwiftUI
import SwiftData

/// Post-fast journal entry — shown after fast completion.
/// Quick emoji mood picker, energy slider (1-5), optional notes.
/// Saves a FastingJournal record linked to the completed session.
struct JournalEntryView: View {
    let session: FastingSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Environment(SubscriptionManager.self) private var subscriptionManager
    
    @State private var selectedMood: FastingMood?
    @State private var energy: Double = 3
    @State private var noteText: String = ""
    @State private var saved = false
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var showPaywall = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                        .entranceAnimation(delay: 0.05)
                    
                    // Mood picker — always available
                    moodSection
                        .entranceAnimation(delay: 0.15)
                    
                    // Energy slider — Pro only
                    if subscriptionManager.isSubscribed {
                        energySection
                            .entranceAnimation(delay: 0.25)
                    } else {
                        journalProLockedSection(
                            icon: "battery.100percent.bolt",
                            title: "Energy Tracking",
                            subtitle: "Track your energy levels with Pro"
                        )
                        .entranceAnimation(delay: 0.25)
                    }
                    
                    // Notes — Pro only
                    if subscriptionManager.isSubscribed {
                        notesSection
                            .entranceAnimation(delay: 0.35)
                    } else {
                        journalProLockedSection(
                            icon: "note.text",
                            title: "Detailed Notes",
                            subtitle: "Add notes to your journal with Pro"
                        )
                        .entranceAnimation(delay: 0.35)
                    }
                    
                    // Save button
                    saveButton
                        .entranceAnimation(delay: 0.45)
                    
                    // Skip link
                    Button {
                        dismiss()
                    } label: {
                        Text("Skip for now")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .entranceAnimation(delay: 0.5)
                }
                .padding(24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityIdentifier("closeButton")
                    .accessibilityLabel("Close journal")
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "Something went wrong.")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 36))
                .foregroundStyle(themeManager.selectedTheme.accent)
            
            Text("How was your fast?")
                .font(.system(.title3, weight: .bold))
            
            Text("Take a moment to reflect on your \(formatDuration(session.actualDuration)) fast.")
                .font(.system(.subheadline))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [themeManager.selectedTheme.accent.opacity(0.12), themeManager.selectedTheme.accent.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Mood Picker
    
    private var moodSection: some View {
        VStack(spacing: 12) {
            Text("Mood")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                ForEach(FastingMood.allCases) { mood in
                    Button {
                        HapticManager.shared.moodSelected()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedMood = mood
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(mood.emoji)
                                .font(.system(size: 32, design: .rounded))
                            Text(mood.label)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(selectedMood == mood ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selectedMood == mood
                                    ? themeManager.selectedTheme.accent.opacity(0.12)
                                    : Color(.tertiarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(selectedMood == mood
                                    ? themeManager.selectedTheme.accent.opacity(0.5)
                                    : Color.clear, lineWidth: 1.5)
                        )
                        .scaleEffect(selectedMood == mood ? 1.05 : 1.0)
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel("\(mood.label) mood, \(mood.emoji)")
                    .accessibilityAddTraits(selectedMood == mood ? .isSelected : [])
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }
    
    // MARK: - Energy Slider
    
    private var energySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Energy Level")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Spacer()
                Text(energyLabel)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(themeManager.selectedTheme.accent)
            }
            
            HStack(spacing: 12) {
                Image(systemName: "battery.25percent")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                
                Slider(value: $energy, in: 1...5, step: 1)
                    .tint(themeManager.selectedTheme.accent)
                    .onChange(of: energy) { _, _ in
                        HapticManager.shared.selectionChanged()
                    }
                
                Image(systemName: "battery.100percent.bolt")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            
            // Energy dots visualization
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { level in
                    Circle()
                        .fill(level <= Int(energy)
                            ? themeManager.selectedTheme.accent
                            : Color(.systemGray4))
                        .frame(width: 10, height: 10)
                        .animation(.spring(response: 0.2), value: energy)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Energy level, \(energyLabel)")
        .accessibilityValue("\(Int(energy)) of 5")
    }
    
    private var energyLabel: String {
        switch Int(energy) {
        case 1: "Very Low"
        case 2: "Low"
        case 3: "Normal"
        case 4: "High"
        case 5: "Very High"
        default: "Normal"
        }
    }
    
    // MARK: - Notes
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
            
            Text("Optional — anything you want to remember")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.tertiary)
            
            TextField("How did the fast go?", text: $noteText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(3...6)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.tertiarySystemBackground))
                )
                .onChange(of: noteText) { _, newValue in
                    if newValue.count > 500 {
                        noteText = String(newValue.prefix(500))
                    }
                }
            
            if !noteText.isEmpty {
                Text("\(noteText.count)/500")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            saveJournal()
        } label: {
            HStack(spacing: 8) {
                if saved {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .transition(.scale.combined(with: .opacity))
                }
                Text(saved ? "Saved!" : "Save Journal Entry")
                    .font(.system(.body, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(saved
                        ? Color.green
                        : themeManager.selectedTheme.accent)
            )
            .animation(.smoothSpring, value: saved)
        }
        .buttonStyle(.pressable)
        .disabled(saved)
        .accessibilityLabel(saved ? "Journal saved" : "Save journal entry")
    }
    
    // MARK: - Pro Locked Journal Section
    
    private func journalProLockedSection(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Text(subtitle)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button {
                showPaywall = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                    Text("Upgrade to Pro")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(.pressable)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle). Upgrade to Pro to unlock.")
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Save
    
    private func saveJournal() {
        let mood = selectedMood ?? .neutral
        let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let journal = FastingJournal(
            sessionID: session.id,
            mood: mood,
            energy: Int(energy),
            notes: trimmedNote
        )
        
        modelContext.insert(journal)
        
        let success = DataController.shared.save(modelContext, operation: "save journal entry")
        if success {
            HapticManager.shared.success()
            withAnimation(.smoothSpring) {
                saved = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                dismiss()
            }
        } else {
            errorMessage = "Couldn't save your journal entry. Please try again."
            showError = true
        }
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

#Preview {
    let session = FastingSession(
        startDate: Date.now.addingTimeInterval(-16 * 3600),
        targetEndDate: Date.now,
        planType: .sixteenEight
    )
    session.complete()
    return JournalEntryView(session: session)
        .modelContainer(for: [FastingSession.self, FastingJournal.self], inMemory: true)
        .environment(ThemeManager())
        .environment(SubscriptionManager())
}
