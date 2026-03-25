import SwiftUI
import AudioToolbox

/// Enhanced water tracking card — daily goal, visual progress ring,
/// quick-add buttons, wave animation, celebration on goal completion.
/// Integrates with FastingManager.waterCount and persists goal via @AppStorage.
struct WaterTrackingCard: View {
    /// Current water count from FastingManager (binding for live updates)
    @Binding var waterCount: Int
    /// Callback when user adds water (parent handles FastingManager.logWater)
    var onAddWater: (Int) -> Void

    @AppStorage("lf_water_goal") private var dailyGoal: Int = 8
    @Environment(ThemeManager.self) private var themeManager
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var celebrationTriggered = false
    @State private var wavePhase: CGFloat = 0
    @State private var justAdded = false
    @State private var showGoalPicker = false
    @State private var showPaywall = false

    private var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1.0, Double(waterCount) / Double(dailyGoal))
    }

    private var goalReached: Bool {
        waterCount >= dailyGoal
    }

    private let waterBlue = Color(red: 0.20, green: 0.60, blue: 0.95)
    private let waterBlueDark = Color(red: 0.10, green: 0.45, blue: 0.85)

    var body: some View {
        VStack(spacing: 14) {
            // Header row
            headerRow

            HStack(spacing: 16) {
                // Water progress ring
                waterRing
                    .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 10) {
                    // Glass count label
                    glassCountLabel

                    // Quick-add buttons
                    quickAddButtons
                }

                Spacer(minLength: 0)
            }

            // Goal reached celebration banner
            if goalReached {
                goalReachedBanner
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                .shadow(color: waterBlue.opacity(0.1), radius: 12, x: 0, y: 2)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(waterBlue.gradient)
                .frame(width: 3)
                .padding(.vertical, 10)
        }
        .animation(.smoothSpring, value: waterCount)
        .animation(.smoothSpring, value: goalReached)
        .onChange(of: waterCount) { oldValue, newValue in
            if newValue >= dailyGoal && oldValue < dailyGoal && !celebrationTriggered {
                celebrationTriggered = true
                HapticManager.shared.achievementUnlocked()
            }
        }
        .sheet(isPresented: $showGoalPicker) {
            WaterGoalPickerSheet(currentGoal: $dailyGoal)
                .presentationDetents([.height(280)])
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("waterTrackingCard")
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(waterBlue)
                Text("Water Tracker")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .accessibilityLabel("Water Tracker")

            Spacer()

            Button {
                HapticManager.shared.lightTap()
                if subscriptionManager.isSubscribed {
                    showGoalPicker = true
                } else {
                    showPaywall = true
                }
            } label: {
                HStack(spacing: 3) {
                    Text("Goal: \(dailyGoal)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    Image(systemName: subscriptionManager.isSubscribed ? "chevron.right" : "lock.fill")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.bounce)
            .accessibilityLabel("Change daily water goal, current goal \(dailyGoal) glasses")
            .accessibilityIdentifier("waterGoalButton")
        }
    }

    // MARK: - Water Progress Ring

    private var waterRing: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(waterBlue.opacity(0.12), lineWidth: 6)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [waterBlue, waterBlueDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.progressSpring, value: progress)

            // Wave animation inside circle
            WaveShape(phase: wavePhase, amplitude: 3, frequency: 2)
                .fill(
                    LinearGradient(
                        colors: [waterBlue.opacity(0.3), waterBlue.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(Circle().inset(by: 6))
                .offset(y: CGFloat(1.0 - progress) * 60 - 24)
                .clipped()
                .clipShape(Circle().inset(by: 6))

            // Center count
            VStack(spacing: 0) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(waterBlue)
                Text("\(waterCount)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: false))
                    .scaleEffect(justAdded ? 1.2 : 1.0)
                    .animation(.tapSpring, value: justAdded)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                wavePhase = .pi * 2
            }
        }
        .accessibilityLabel("\(waterCount) of \(dailyGoal) glasses")
    }

    // MARK: - Glass Count Label

    private var glassCountLabel: some View {
        HStack(spacing: 4) {
            Text("\(waterCount)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(waterBlue)
                .contentTransition(.numericText(countsDown: false))

            Text("/ \(dailyGoal) glasses")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .accessibilityLabel("\(waterCount) of \(dailyGoal) glasses of water")
    }

    // MARK: - Quick Add Buttons

    private var quickAddButtons: some View {
        HStack(spacing: 10) {
            quickAddButton(count: 1, icon: "plus")
            quickAddButton(count: 2, icon: "plus")
        }
    }

    private func quickAddButton(count: Int, icon: String) -> some View {
        Button {
            HapticManager.shared.lightTap()
            onAddWater(count)
            justAdded = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                justAdded = false
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 10))
                Text(count == 1 ? "+1" : "+2")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(waterBlue)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(waterBlue.opacity(0.1))
            )
        }
        .buttonStyle(.bounce)
        .accessibilityLabel("Add \(count) glass\(count > 1 ? "es" : "") of water")
        .accessibilityIdentifier("addWater\(count)Button")
    }

    // MARK: - Goal Reached Banner

    private var goalReachedBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 16))
                .foregroundStyle(.green)
            Text("Daily water goal reached! 💧")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.green)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.green.opacity(0.1))
        )
        .accessibilityLabel("Daily water goal reached")
        .accessibilityIdentifier("waterGoalReachedBanner")
    }
}

// MARK: - Wave Shape

/// Simple sine wave shape for water animation inside the progress ring.
struct WaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY

        path.move(to: CGPoint(x: 0, y: midY))

        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / rect.width
            let sine = sin(relativeX * frequency * .pi * 2 + phase)
            let y = midY + amplitude * sine
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Water Goal Picker Sheet

struct WaterGoalPickerSheet: View {
    @Binding var currentGoal: Int
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGoal: Int = 8

    private let goalRange = Array(4...20)

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Daily Water Goal")
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                Text("\(selectedGoal)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.cyan)
                    .contentTransition(.numericText())
                    .animation(.tapSpring, value: selectedGoal)

                Text("glasses per day")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.secondary)

                Picker("Goal", selection: $selectedGoal) {
                    ForEach(goalRange, id: \.self) { count in
                        Text("\(count) glasses").tag(count)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 100)

                Button {
                    HapticManager.shared.mediumTap()
                    currentGoal = selectedGoal
                    dismiss()
                } label: {
                    Text("Set Goal")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.cyan)
                        )
                }
                .buttonStyle(.bounce)
                .accessibilityIdentifier("setWaterGoalButton")
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("cancelButton")
                }
            }
            .onAppear {
                selectedGoal = currentGoal
            }
        }
    }
}

#Preview {
    WaterTrackingCard(
        waterCount: .constant(5),
        onAddWater: { _ in }
    )
    .padding(20)
    .environment(ThemeManager())
}
