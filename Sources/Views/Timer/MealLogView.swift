import SwiftData
import SwiftUI

/// Sheet for logging meals — shown during eating windows or after completing a fast.
/// Supports pre-filling from a recipe selection.
struct MealLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    /// Optional pre-filled values from a recipe
    var prefillTitle: String?
    var prefillEmoji: String?
    var prefillMealType: String?

    @State private var selectedMealType: MealType = .lunch
    @State private var titleText: String = ""
    @State private var selectedEmoji: String = "🍽️"
    @State private var noteText: String = ""
    @State private var isFastingFriendly: Bool = true
    @State private var contentAppeared = false

    private let emojiOptions = ["🥗", "🍗", "🥚", "🍜", "🥑", "🍎", "🥤", "🍞", "🍲", "🐟"]

    enum MealType: String, CaseIterable, Identifiable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snack = "Snack"

        var id: String {
            rawValue
        }

        var emoji: String {
            switch self {
            case .breakfast: "🌅"
            case .lunch: "☀️"
            case .dinner: "🌙"
            case .snack: "🍿"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Meal type picker
                    mealTypePicker
                        .entranceAnimation(delay: 0.1)

                    // Title
                    titleField
                        .entranceAnimation(delay: 0.15)

                    // Emoji picker
                    emojiPicker
                        .entranceAnimation(delay: 0.2)

                    // Fasting friendly toggle
                    fastingFriendlyToggle
                        .entranceAnimation(delay: 0.25)

                    // Note
                    noteField
                        .entranceAnimation(delay: 0.3)

                    // Save button
                    saveButton
                        .entranceAnimation(delay: 0.35)
                }
                .padding(20)
                .opacity(contentAppeared ? 1 : 0)
                .scaleEffect(contentAppeared ? 1 : 0.95)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("closeMealLog")
                }
            }
            .onAppear {
                applyPrefill()
                withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                    contentAppeared = true
                }
            }
        }
    }

    // MARK: - Meal Type Picker

    private var mealTypePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Meal Type")
                .font(.adaptiveDetail(isRegular: isRegular).weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(MealType.allCases) { type in
                        Button {
                            HapticManager.shared.selectionChanged()
                            withAnimation(.tapSpring) {
                                selectedMealType = type
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(type.emoji)
                                    .font(.adaptiveHeadline(isRegular: isRegular))
                                Text(type.rawValue)
                                    .font(.adaptiveDetail(isRegular: isRegular).weight(.medium))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(selectedMealType == type
                                        ? themeManager.selectedTheme.accent.opacity(0.15)
                                        : Color(.tertiarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(selectedMealType == type
                                        ? themeManager.selectedTheme.accent.opacity(0.5)
                                        : Color.clear, lineWidth: 1.5)
                            )
                            .foregroundStyle(selectedMealType == type ? themeManager.selectedTheme.accent : .primary)
                        }
                        .buttonStyle(.bounce)
                        .accessibilityLabel("\(type.rawValue) meal type")
                        .accessibilityAddTraits(selectedMealType == type ? .isSelected : [])
                    }
                }
            }
        }
    }

    // MARK: - Title Field

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What did you eat?")
                .font(.adaptiveDetail(isRegular: isRegular).weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Grilled chicken salad…", text: $titleText)
                .font(.adaptiveSubheadline(isRegular: isRegular))
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.tertiarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                )
                .accessibilityLabel("Meal title")
        }
    }

    // MARK: - Emoji Picker

    private var emojiPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pick an emoji")
                .font(.adaptiveDetail(isRegular: isRegular).weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(emojiOptions, id: \.self) { emoji in
                    Button {
                        HapticManager.shared.lightTap()
                        withAnimation(.tapSpring) {
                            selectedEmoji = emoji
                        }
                    } label: {
                        Text(emoji)
                            .font(.adaptiveDisplay(size: 28, weight: .regular, design: .default, isRegular: isRegular))
                            .frame(width: 50, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(selectedEmoji == emoji
                                        ? themeManager.selectedTheme.accent.opacity(0.15)
                                        : Color(.tertiarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(selectedEmoji == emoji
                                        ? themeManager.selectedTheme.accent.opacity(0.6)
                                        : Color.clear, lineWidth: 1.5)
                            )
                            .scaleEffect(selectedEmoji == emoji ? 1.1 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Emoji \(emoji)")
                    .accessibilityAddTraits(selectedEmoji == emoji ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - Fasting Friendly Toggle

    private var fastingFriendlyToggle: some View {
        HStack(spacing: 12) {
            Image(systemName: isFastingFriendly ? "leaf.fill" : "leaf")
                .font(.adaptiveSubheadline(isRegular: isRegular))
                .foregroundStyle(isFastingFriendly ? .green : .secondary)
                .contentTransition(.symbolEffect(.replace))

            Text("Fasting-friendly meal")
                .font(.adaptiveDetail(isRegular: isRegular).weight(.medium))

            Spacer()

            Toggle("", isOn: $isFastingFriendly)
                .labelsHidden()
                .tint(.green)
                .onChange(of: isFastingFriendly) { _, _ in
                    HapticManager.shared.lightTap()
                }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Fasting-friendly meal, \(isFastingFriendly ? "on" : "off")")
    }

    // MARK: - Note Field

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note (optional)")
                .font(.adaptiveDetail(isRegular: isRegular).weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("How did it make you feel?", text: $noteText, axis: .vertical)
                .font(.adaptiveDetail(isRegular: isRegular))
                .lineLimit(2 ... 4)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.tertiarySystemBackground))
                )
                .accessibilityLabel("Meal note")
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            saveMeal()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))
                Text("Save Meal")
                    .font(.adaptiveBody(isRegular: isRegular).weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(themeManager.selectedTheme.accentGradient)
            )
            .shadow(color: themeManager.selectedTheme.accent.opacity(0.4), radius: 16, y: 6)
            .shadow(color: themeManager.selectedTheme.accent.opacity(0.2), radius: 6, y: 2)
        }
        .buttonStyle(.pressable)
        .disabled(titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
        .accessibilityLabel("Save meal entry")
        .accessibilityHint(titleText.isEmpty ? "Enter a meal title first" : "Saves your meal to the log")
    }

    // MARK: - Actions

    private func applyPrefill() {
        if let title = prefillTitle {
            titleText = title
        }
        if let emoji = prefillEmoji {
            selectedEmoji = emoji
        }
        if let mealType = prefillMealType,
           let type = MealType(rawValue: mealType)
        {
            selectedMealType = type
        }
    }

    private func saveMeal() {
        let trimmedTitle = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        HapticManager.shared.mediumTap()

        let entry = MealEntry(
            date: .now,
            mealType: selectedMealType.rawValue.lowercased(),
            title: String(trimmedTitle.prefix(200)),
            emoji: selectedEmoji,
            note: noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : String(noteText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(500)),
            isFastingFriendly: isFastingFriendly
        )

        modelContext.insert(entry)
        _ = DataController.shared.save(modelContext, operation: "save meal entry")

        dismiss()
    }
}

#Preview {
    MealLogView()
        .modelContainer(for: [MealEntry.self], inMemory: true)
        .environment(ThemeManager())
}
