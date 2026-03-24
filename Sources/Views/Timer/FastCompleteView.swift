import SwiftUI
import SwiftData

/// Oruç tamamlama raporu — doğal premium conversion moment.
/// Free: tebrik + basit özet. Premium: detaylı breakdown.
/// Now includes mood picker (#6), fast note (#10), and share button.
struct FastCompleteView: View {
    let session: FastingSession
    let isPremium: Bool
    let onUpgrade: () -> Void
    var streak: Int = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @State private var showConfetti = false
    @State private var selectedMood: String?
    @State private var noteText: String = ""
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var celebrationScale: CGFloat = 0.3
    @State private var celebrationOpacity: Double = 0
    @State private var contentAppeared = false
    @State private var showJournal = false
    
    private let moods = ["😴", "😐", "😊", "🔥"]
    private let moodLabels = ["Tired", "Okay", "Good", "Energized"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Celebratory warm gradient background — gold/amber
                LinearGradient(
                    colors: [
                        Color(red: 0.18, green: 0.12, blue: 0.0),
                        Color.orange.opacity(0.12),
                        Color.yellow.opacity(0.08),
                        Color(.systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Celebration header
                        celebrationHeader
                            .entranceAnimation(delay: 0.1)
                        
                        // Basic stats — always visible
                        basicStats
                            .entranceAnimation(delay: 0.25)
                        
                        // Mood picker (#6)
                        moodPicker
                            .entranceAnimation(delay: 0.3)
                        
                        // Fast note (#10)
                        noteSection
                            .entranceAnimation(delay: 0.35)
                        
                        // Share My Fast button
                        shareButton
                            .entranceAnimation(delay: 0.38)
                        
                        // Journal entry button
                        journalButton
                            .entranceAnimation(delay: 0.42)
                        
                        // Premium breakdown
                        if isPremium {
                            premiumBreakdown
                                .entranceAnimation(delay: 0.4)
                        } else {
                            premiumTeaser
                                .entranceAnimation(delay: 0.4)
                        }
                        
                        // Done button
                        Button {
                            HapticManager.shared.lightTap()
                            saveMoodAndNote()
                            dismiss()
                        } label: {
                            Text("Done")
                                .font(.system(.body, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(themeManager.selectedTheme.accentGradient)
                                )
                                .shadow(color: themeManager.selectedTheme.accent.opacity(0.4), radius: 12, y: 4)
                        }
                        .buttonStyle(.pressable)
                        .entranceAnimation(delay: 0.5)
                        .accessibilityLabel("Done")
                        .accessibilityHint("Dismiss the fast completion report")
                    }
                    .padding(24)
                    .scaleEffect(contentAppeared ? 1.0 : 0.92)
                    .opacity(contentAppeared ? 1.0 : 0)
                }
                
                // Confetti overlay
                ConfettiView(isActive: showConfetti)
                    .ignoresSafeArea()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveMoodAndNote()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityIdentifier("closeButton")
                    .accessibilityLabel("Close")
                }
            }
            .onAppear {
                HapticManager.shared.fastCompleted()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    contentAppeared = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showConfetti = true
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = shareImage {
                    ActivityShareSheet(
                        image: image,
                        caption: "I just completed a \(formatDuration(session.actualDuration)) fast with Lumifaste! 🍃 #Lumifaste #IntermittentFasting"
                    )
                }
            }
            .sheet(isPresented: $showJournal) {
                JournalEntryView(session: session)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "Something went wrong. Please try again.")
            }
        }
    }
    
    // MARK: - Share My Fast
    
    private var shareButton: some View {
        Button {
            HapticManager.shared.shareAction()
            shareImage = ShareImageRenderer.renderFastCard(
                duration: session.actualDuration,
                stage: session.stage,
                plan: session.plan,
                streak: streak
            )
            if shareImage != nil {
                showShareSheet = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                Text("Share My Fast")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
            )
            .shadow(color: Color.accentColor.opacity(0.2), radius: 8, y: 3)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("Share my fast results")
        .accessibilityHint("Creates a shareable image card of your fasting results")
    }
    
    // MARK: - Journal Entry Button
    
    private var journalButton: some View {
        Button {
            HapticManager.shared.lightTap()
            showJournal = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text("Add Journal Entry")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
            )
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("Add a journal entry about this fast")
    }
    
    // MARK: - Save mood and note to session
    
    private func saveMoodAndNote() {
        if let mood = selectedMood {
            session.mood = mood
        }
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            // Validate note length
            if InputValidator.validateNote(trimmed) == nil {
                session.note = String(trimmed.prefix(500))
            }
        }
        let success = DataController.shared.save(modelContext, operation: "save fast mood/note")
        if !success {
            errorMessage = "Couldn't save your mood and notes. Your fast was recorded, but these details may be lost."
            showError = true
        }
        ReviewRequestManager.recordCompletedFast()
    }
    
    // MARK: - Personalized congratulation based on fast length
    
    private var fastLengthCongrats: (title: String, subtitle: String) {
        let hours = session.actualDuration / 3600
        switch hours {
        case ..<14:
            return ("Quick Fast! ⚡", "Every fast counts — you're building the habit.")
        case 14..<18:
            return ("Solid Fast! 💪", "Your body entered fat-burning mode. Great work.")
        case 18..<24:
            return ("Warrior Fast! 🔥", "Deep ketosis and cellular repair activated.")
        default:
            return ("Epic Fast! 🏆", "Incredible willpower. Your body thanks you.")
        }
    }
    
    // MARK: - Celebration
    
    private var celebrationHeader: some View {
        VStack(spacing: 12) {
            // Large checkmark icon — premium celebration
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.orange.opacity(0.3), Color.yellow.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .orange.opacity(0.5), radius: 16, x: 0, y: 4)
            }
            .scaleEffect(celebrationScale)
            .opacity(celebrationOpacity)
            .accessibilityHidden(true)
            
            Text(fastLengthCongrats.title)
                .font(.system(.title, weight: .bold))
            
            Text(fastLengthCongrats.subtitle)
                .font(.system(.subheadline))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if streak > 1 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                    Text("\(streak)-day streak!")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.orange)
                }
                .padding(.top, 4)
            }
        }
        .padding(.top, 8)
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.5).delay(0.15)) {
                celebrationScale = 1.0
                celebrationOpacity = 1.0
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Congratulations! \(fastLengthCongrats.title). \(fastLengthCongrats.subtitle)")
    }
    
    // MARK: - Basic Stats (Free)
    
    private var basicStats: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                StatItem(title: "Duration", value: formatDuration(session.actualDuration), icon: "clock.fill", color: .blue)
                StatItem(title: "Plan", value: session.plan.rawValue, icon: "calendar", color: .orange)
                StatItem(title: "Stage", value: session.stage.rawValue, icon: session.stage.icon, color: session.stage.color)
            }
            
            // Water count display (#5)
            if session.waterCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.cyan)
                    Text("\(session.waterCount) glasses of water")
                        .font(.system(size: 13))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                .shadow(color: .orange.opacity(0.1), radius: 16, x: 0, y: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Duration \(formatDuration(session.actualDuration)), Plan \(session.plan.rawValue), Reached \(session.stage.rawValue) stage")
    }
    
    // MARK: - Mood Picker (#6)
    
    private var moodPicker: some View {
        VStack(spacing: 10) {
            Text("How do you feel?")
                .font(.system(size: 15, weight: .semibold))
            
            HStack(spacing: 16) {
                ForEach(Array(zip(moods, moodLabels)), id: \.0) { emoji, label in
                    Button {
                        HapticManager.shared.moodSelected()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedMood = emoji
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(emoji)
                                .font(.system(size: 32))
                            Text(label)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectedMood == emoji ? Color.accentColor.opacity(0.15) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(selectedMood == emoji ? Color.accentColor : Color.clear, lineWidth: 1.5)
                        )
                        .scaleEffect(selectedMood == emoji ? 1.1 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(label) mood")
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Fast Note (#10)
    
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add a note")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            
            TextField("How was this fast?", text: $noteText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(2...4)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.tertiarySystemBackground))
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        )
    }
    
    // MARK: - Premium Breakdown
    
    private var premiumBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Stage Breakdown")
                .font(.system(.body, weight: .bold))
            
            ForEach(Array(FastingStage.allCases.enumerated()), id: \.element.id) { index, stage in
                let timeInStage = stageTime(for: stage)
                if timeInStage > 0 {
                    HStack(spacing: 12) {
                        Image(systemName: stage.icon)
                            .font(.system(.footnote))
                            .foregroundStyle(stage.color)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stage.rawValue)
                                .font(.system(.footnote, weight: .medium))
                            Text(stage.subtitle)
                                .font(.system(.caption))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(formatDurationShort(timeInStage))
                            .font(.system(.footnote, design: .rounded, weight: .semibold))
                            .monospacedDigit()
                    }
                    .padding(.vertical, 4)
                    .staggeredAppear(index: index)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(stage.rawValue): \(formatDurationShort(timeInStage)). \(stage.subtitle)")
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Premium Teaser (Free users)
    
    private var premiumTeaser: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(themeManager.selectedTheme.accent)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("See Your Full Report")
                        .font(.system(.body, weight: .semibold))
                    Text("Stage breakdown, time in each phase, and trends over time")
                        .font(.system(.footnote))
                        .foregroundStyle(.secondary)
                }
            }
            
            Button {
                saveMoodAndNote()
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onUpgrade()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(.footnote))
                    Text("Try Premium Free")
                        .font(.system(.subheadline, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(themeManager.selectedTheme.accentGradient)
                )
            }
            .accessibilityLabel("Try Premium Free")
            .accessibilityHint("Unlock detailed stage breakdown and fasting reports")
            .buttonStyle(.pressable)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Helpers
    
    private func stageTime(for stage: FastingStage) -> TimeInterval {
        let total = session.actualDuration
        let stageStart = stage.startHour * 3600
        let nextStart = stage.next?.startHour ?? 999
        let stageEnd = nextStart * 3600
        
        guard total > stageStart else { return 0 }
        return min(total, stageEnd) - stageStart
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
    
    private func formatDurationShort(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(.body))
                .foregroundStyle(color)
            Text(value)
                .font(.system(.body, design: .rounded, weight: .bold))
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Free") {
    let session = FastingSession(
        startDate: Date.now.addingTimeInterval(-16 * 3600),
        targetEndDate: Date.now,
        planType: .sixteenEight
    )
    session.complete()
    return FastCompleteView(session: session, isPremium: false, onUpgrade: {}, streak: 5)
        .modelContainer(for: FastingSession.self, inMemory: true)
        .environment(ThemeManager())
}

#Preview("Premium") {
    let session = FastingSession(
        startDate: Date.now.addingTimeInterval(-20 * 3600),
        targetEndDate: Date.now,
        planType: .twentyFour
    )
    session.complete()
    return FastCompleteView(session: session, isPremium: true, onUpgrade: {}, streak: 12)
        .modelContainer(for: FastingSession.self, inMemory: true)
        .environment(ThemeManager())
}
