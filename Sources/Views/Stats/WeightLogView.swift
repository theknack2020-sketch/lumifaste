import SwiftUI
import SwiftData
import AudioToolbox

/// Weight logging sheet — manual entry, stored via SwiftData.
/// Enhanced: BMI calculation with height, goal weight with progress indicator.
/// Data stays on device (K004).
struct WeightLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Query(sort: \WeightEntry.date, order: .reverse)
    private var entries: [WeightEntry]
    
    @AppStorage("lf_weight_unit") private var useMetric = true
    @AppStorage("lf_user_height_cm") private var heightCm: Double = 0
    @AppStorage("lf_goal_weight_kg") private var goalWeightKg: Double = 0
    @State private var weightText = ""
    @State private var noteText = ""
    @State private var logDate = Date.now
    @State private var validationError: String?
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var showHeightEntry = false
    @State private var heightText = ""
    @State private var showGoalEntry = false
    @State private var goalText = ""
    @FocusState private var isWeightFocused: Bool
    
    private var unit: String { useMetric ? "kg" : "lbs" }
    
    private var parsedWeight: Double? {
        guard let val = Double(weightText), val > 0, val < 1000 else { return nil }
        return val
    }
    
    /// Current weight in kg (from latest entry)
    private var currentWeightKg: Double? {
        entries.first?.weightKg
    }
    
    /// BMI calculation: weight(kg) / height(m)²
    private var bmi: Double? {
        guard heightCm > 0, let weight = currentWeightKg else { return nil }
        let heightM = heightCm / 100
        return weight / (heightM * heightM)
    }
    
    private var bmiCategory: (label: String, color: Color)? {
        guard let bmi else { return nil }
        switch bmi {
        case ..<18.5: return ("Underweight", .blue)
        case 18.5..<25: return ("Normal", .green)
        case 25..<30: return ("Overweight", .orange)
        default: return ("Obese", .red)
        }
    }
    
    /// Goal weight progress (0...1)
    private var goalProgress: Double? {
        guard goalWeightKg > 0, let current = currentWeightKg, entries.count > 1 else { return nil }
        let startWeight = entries.last!.weightKg // oldest
        let totalToLose = startWeight - goalWeightKg
        guard totalToLose != 0 else { return nil }
        let lost = startWeight - current
        return min(max(lost / totalToLose, 0), 1)
    }
    
    var body: some View {
        let accent = themeManager.selectedTheme.accent
        
        NavigationStack {
            List {
                // Input Section
                Section {
                    HStack {
                        TextField("Weight", text: $weightText)
                            .keyboardType(.decimalPad)
                            .focused($isWeightFocused)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .accessibilityLabel("Weight value")
                            .accessibilityHint("Enter your weight in \(unit)")
                        
                        Picker("Unit", selection: $useMetric) {
                            Text("kg").tag(true)
                            Text("lbs").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                        .accessibilityLabel("Weight unit")
                    }
                    
                    DatePicker("Date", selection: $logDate, displayedComponents: .date)
                        .accessibilityLabel("Entry date")
                    
                    TextField("Note (optional)", text: $noteText)
                        .font(.system(size: 15))
                        .accessibilityLabel("Note")
                        .accessibilityHint("Optional note for this weight entry")
                } header: {
                    Text("Log Weight")
                } footer: {
                    Text("Your weight data stays on your device.")
                }
                
                // Save button
                Section {
                    Button {
                        if let error = InputValidator.validateWeight(weightText, isMetric: useMetric) {
                            validationError = error
                            HapticManager.shared.error()
                            return
                        }
                        if let noteError = InputValidator.validateNote(noteText) {
                            validationError = noteError
                            HapticManager.shared.error()
                            return
                        }
                        validationError = nil
                        saveEntry()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Save")
                                .font(.system(size: 17, weight: .semibold))
                            Spacer()
                        }
                    }
                    .disabled(parsedWeight == nil)
                    .accessibilityLabel("Save weight entry")
                    .accessibilityHint(parsedWeight == nil ? "Enter a valid weight first" : "Saves \(weightText) \(unit)")
                    
                    if let error = validationError {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                    }
                }
                
                // BMI & Goal Section
                if !entries.isEmpty {
                    Section("Body Metrics") {
                        // BMI Row
                        if let bmi, let category = bmiCategory {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("BMI")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(.secondary)
                                    HStack(spacing: 6) {
                                        Text(String(format: "%.1f", bmi))
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                        Text(category.label)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(category.color)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(
                                                Capsule()
                                                    .fill(category.color.opacity(0.12))
                                            )
                                    }
                                }
                                
                                Spacer()
                                
                                Button {
                                    heightText = heightCm > 0 ? String(format: "%.0f", useMetric ? heightCm : heightCm / 2.54) : ""
                                    showHeightEntry = true
                                } label: {
                                    Image(systemName: "pencil.circle")
                                        .font(.system(size: 18))
                                        .foregroundStyle(accent)
                                }
                                .accessibilityLabel("Edit height")
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("BMI: \(String(format: "%.1f", bmi)), \(category.label)")
                        } else {
                            // No height set — prompt
                            Button {
                                heightText = ""
                                showHeightEntry = true
                            } label: {
                                HStack {
                                    Image(systemName: "ruler")
                                        .font(.system(size: 14))
                                        .foregroundStyle(accent)
                                    Text("Set Height for BMI")
                                        .font(.system(size: 14, weight: .medium))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .accessibilityLabel("Set your height to calculate BMI")
                        }
                        
                        // Goal Weight Row
                        if goalWeightKg > 0 {
                            goalWeightRow(accent: accent)
                        } else {
                            Button {
                                goalText = ""
                                showGoalEntry = true
                            } label: {
                                HStack {
                                    Image(systemName: "target")
                                        .font(.system(size: 14))
                                        .foregroundStyle(accent)
                                    Text("Set Goal Weight")
                                        .font(.system(size: 14, weight: .medium))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .accessibilityLabel("Set a goal weight to track progress")
                        }
                    }
                }
                
                // Recent entries
                if entries.isEmpty {
                    Section {
                        emptyEntriesView
                    }
                } else {
                    Section("Recent") {
                        ForEach(entries.prefix(10)) { entry in
                            entryRow(entry: entry)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let arr = Array(entries.prefix(10))
                                if index < arr.count {
                                    modelContext.delete(arr[index])
                                }
                            }
                            let success = DataController.shared.save(modelContext, operation: "delete weight entry")
                            if !success {
                                errorMessage = "Couldn't delete the weight entry. Please try again."
                                showError = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("doneButton")
                        .accessibilityLabel("Done")
                        .accessibilityHint("Closes the weight log sheet")
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "Something went wrong. Please try again.")
            }
            .alert("Enter Height", isPresented: $showHeightEntry) {
                TextField(useMetric ? "Height in cm" : "Height in inches", text: $heightText)
                    .keyboardType(.decimalPad)
                Button("Save") {
                    if let val = Double(heightText), val > 0 {
                        heightCm = useMetric ? val : val * 2.54
                        HapticManager.shared.lightTap()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(useMetric ? "Enter your height in centimeters (e.g. 175)" : "Enter your height in inches (e.g. 69)")
            }
            .alert("Goal Weight", isPresented: $showGoalEntry) {
                TextField("Goal in \(unit)", text: $goalText)
                    .keyboardType(.decimalPad)
                Button("Save") {
                    if let val = Double(goalText), val > 0 {
                        goalWeightKg = useMetric ? val : val / 2.20462
                        HapticManager.shared.lightTap()
                    }
                }
                Button("Clear Goal", role: .destructive) {
                    goalWeightKg = 0
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Set a target weight to track your progress")
            }
            .onAppear {
                if let last = entries.first {
                    let val = useMetric ? last.weightKg : last.weightLbs
                    weightText = String(format: "%.1f", val)
                }
                isWeightFocused = true
            }
        }
    }
    
    // MARK: - Goal Weight Row
    
    private func goalWeightRow(accent: Color) -> some View {
        let goalDisplay = useMetric ? goalWeightKg : goalWeightKg * 2.20462
        let currentDisplay = useMetric ? (currentWeightKg ?? 0) : (currentWeightKg ?? 0) * 2.20462
        let remaining = currentDisplay - goalDisplay
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Goal Weight")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        Text(String(format: "%.1f %@", goalDisplay, unit))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        
                        if remaining > 0 {
                            Text(String(format: "%.1f %@ to go", remaining, unit))
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        } else if remaining <= 0 && currentWeightKg != nil {
                            Text("🎉 Goal reached!")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    goalText = String(format: "%.1f", goalDisplay)
                    showGoalEntry = true
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(accent)
                }
                .accessibilityLabel("Edit goal weight")
            }
            
            // Progress bar
            if let progress = goalProgress {
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color(.systemGray5))
                            
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [accent, accent.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * CGFloat(progress))
                        }
                    }
                    .frame(height: 8)
                    
                    Text(String(format: "%.0f%% of goal", progress * 100))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Goal weight: \(String(format: "%.1f %@", goalDisplay, unit))")
        .accessibilityValue(goalProgress.map { String(format: "%.0f percent progress", $0 * 100) } ?? "No progress data")
    }
    
    // MARK: - Entry Row
    
    private func entryRow(entry: WeightEntry) -> some View {
        HStack {
            // Accent left bar
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.pink.gradient)
                .frame(width: 3, height: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 14, weight: .medium))
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f %@", useMetric ? entry.weightKg : entry.weightLbs, unit))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                
                // Show BMI if height is set
                if heightCm > 0 {
                    let entryBmi = entry.weightKg / pow(heightCm / 100, 2)
                    Text(String(format: "BMI %.1f", entryBmi))
                        .font(.system(size: 10, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(entry.date.formatted(.dateTime.month(.abbreviated).day()))
        .accessibilityValue(String(format: "%.1f %@", useMetric ? entry.weightKg : entry.weightLbs, unit))
    }
    
    // MARK: - Empty Entries
    
    private var emptyEntriesView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 80, height: 80)
                    .shadow(color: .pink.opacity(0.15), radius: 8, y: 4)
                
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.pink)
            }
            .accessibilityHidden(true)
            
            VStack(spacing: 6) {
                Text("No Entries Yet")
                    .font(.system(.headline, design: .rounded))
                
                Text("Track your weight to see trends\nand how fasting affects your body.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("No entries yet. Track your weight to see trends and how fasting affects your body.")
            
            Button {
                isWeightFocused = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                    Text("Add Your First Entry")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.pink)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.pink.opacity(0.1))
                )
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("Add your first weight entry")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Save
    
    private func saveEntry() {
        guard let weight = parsedWeight else { return }
        let kg = useMetric ? weight : weight / 2.20462
        let entry = WeightEntry(date: logDate, weightKg: kg, note: noteText)
        modelContext.insert(entry)
        let success = DataController.shared.save(modelContext, operation: "save weight entry")
        if success {
            HapticManager.shared.success()
            AudioServicesPlaySystemSound(1057)
            dismiss()
        } else {
            HapticManager.shared.error()
            errorMessage = "Couldn't save your weight entry. Please check your device storage and try again."
            showError = true
        }
    }
}

#Preview {
    WeightLogView()
        .modelContainer(for: WeightEntry.self, inMemory: true)
        .environment(ThemeManager())
}
