import SwiftUI
import SwiftData
import AudioToolbox

/// Weight logging sheet — manual entry, stored via SwiftData.
/// Data stays on device (K004).
struct WeightLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WeightEntry.date, order: .reverse)
    private var entries: [WeightEntry]
    
    @AppStorage("lf_weight_unit") private var useMetric = true
    @State private var weightText = ""
    @State private var noteText = ""
    @State private var logDate = Date.now
    @State private var validationError: String?
    @State private var showError = false
    @State private var errorMessage: String?
    @FocusState private var isWeightFocused: Bool
    
    private var unit: String { useMetric ? "kg" : "lbs" }
    
    private var parsedWeight: Double? {
        guard let val = Double(weightText), val > 0, val < 1000 else { return nil }
        return val
    }
    
    /// Validate weight input and return whether it's valid
    private var isWeightValid: Bool {
        InputValidator.validateWeight(weightText, isMetric: useMetric) == nil
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Input Section
                Section {
                    HStack {
                        TextField("Weight", text: $weightText)
                            .keyboardType(.decimalPad)
                            .focused($isWeightFocused)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        
                        // Unit picker
                        Picker("Unit", selection: $useMetric) {
                            Text("kg").tag(true)
                            Text("lbs").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }
                    
                    DatePicker("Date", selection: $logDate, displayedComponents: .date)
                    
                    TextField("Note (optional)", text: $noteText)
                        .font(.system(size: 15))
                } header: {
                    Text("Log Weight")
                } footer: {
                    Text("Your weight data stays on your device.")
                }
                
                // Save button
                Section {
                    Button {
                        // Validate before saving
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
                    
                    if let error = validationError {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                    }
                }
                
                // Recent entries
                if entries.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.pink.opacity(0.08))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "scalemass.fill")
                                    .font(.system(size: 32, weight: .light))
                                    .foregroundStyle(.pink)
                            }
                            .accessibilityHidden(true)
                            
                            VStack(spacing: 6) {
                                Text("No Entries Yet")
                                    .font(.system(size: 17, weight: .semibold))
                                
                                Text("Track your weight to see trends\nand how fasting affects your body.")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            
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
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                } else if !entries.isEmpty {
                    Section("Recent") {
                        ForEach(entries.prefix(10)) { entry in
                            HStack {
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
                                
                                Text(String(format: "%.1f %@", useMetric ? entry.weightKg : entry.weightLbs, unit))
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .monospacedDigit()
                            }
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
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "Something went wrong. Please try again.")
            }
            .onAppear {
                // Pre-fill with last weight if available
                if let last = entries.first {
                    let val = useMetric ? last.weightKg : last.weightLbs
                    weightText = String(format: "%.1f", val)
                }
                isWeightFocused = true
            }
        }
    }
    
    private func saveEntry() {
        guard let weight = parsedWeight else { return }
        let kg = useMetric ? weight : weight / 2.20462
        let entry = WeightEntry(date: logDate, weightKg: kg, note: noteText)
        modelContext.insert(entry)
        let success = DataController.shared.save(modelContext, operation: "save weight entry")
        if success {
            HapticManager.shared.success()
            // Sound 1057: tock on weight save
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
}
