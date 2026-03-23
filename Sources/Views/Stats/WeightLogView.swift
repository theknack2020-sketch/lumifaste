import SwiftUI
import SwiftData

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
                if !entries.isEmpty {
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
                            DataController.shared.save(modelContext, operation: "delete weight entry")
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
        DataController.shared.save(modelContext, operation: "save weight entry")
        HapticManager.shared.success()
        dismiss()
    }
}

#Preview {
    WeightLogView()
        .modelContainer(for: WeightEntry.self, inMemory: true)
}
