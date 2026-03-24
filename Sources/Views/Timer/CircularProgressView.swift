import SwiftUI

/// Circular progress ring — oruç ilerlemesini gösterir.
/// Fully accessible: announces progress percentage and current stage to VoiceOver.
/// Uses the app theme's accent color as the primary ring color when in fed/idle state.
/// Redesigned: thicker ring, strong glow shadow on arc, breathing pulse animation,
/// inner radial gradient fill, premium-grade depth and visibility.
struct CircularProgressView: View {
    let progress: Double
    let stage: FastingStage
    let lineWidth: CGFloat
    var themeAccent: Color = .accentColor
    var isBreathing: Bool = false
    
    init(progress: Double, stage: FastingStage, lineWidth: CGFloat = 28, themeAccent: Color = .accentColor, isBreathing: Bool = false) {
        self.progress = progress
        self.stage = stage
        self.lineWidth = lineWidth
        self.themeAccent = themeAccent
        self.isBreathing = isBreathing
    }
    
    private var progressPercent: Int {
        Int(min(progress, 1.0) * 100)
    }
    
    /// Ring color: use stage color when actively fasting, theme accent when idle/fed
    private var ringColor: Color {
        stage == .fed ? themeAccent : stage.color
    }
    
    /// Secondary ring color for gradient effect
    private var ringSecondaryColor: Color {
        switch stage {
        case .fed: themeAccent.opacity(0.7)
        case .earlyFasting: .orange
        case .fatBurning: .red
        case .ketosis: .purple
        case .autophagy: .pink
        }
    }
    
    var body: some View {
        ZStack {
            // Inner radial gradient fill — very faint stage-tinted glow inside the circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            ringColor.opacity(0.06),
                            ringColor.opacity(0.02),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 140
                    )
                )
                .padding(lineWidth + 8)
            
            // Outer ambient glow ring — creates depth
            if progress > 0.01 {
                Circle()
                    .stroke(
                        ringColor.opacity(0.15),
                        style: StrokeStyle(lineWidth: lineWidth + 24, lineCap: .round)
                    )
                    .blur(radius: 10)
            }
            
            // Background ring — more visible against dark backgrounds
            Circle()
                .stroke(
                    ringColor.opacity(0.2),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: stage)
            
            // Glow shadow layer (drawn behind progress ring) — intensified for visibility
            if progress > 0.01 {
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(
                        ringColor,
                        style: StrokeStyle(lineWidth: lineWidth + 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 16)
                    .opacity(0.6)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: stage)
            }
            
            // Progress ring — gradient stroke with strong glow
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            ringSecondaryColor.opacity(0.5),
                            ringColor.opacity(0.8),
                            ringColor
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * min(progress, 1.0))
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: ringColor.opacity(0.7), radius: 15, x: 0, y: 0)
                .shadow(color: ringColor.opacity(0.4), radius: 25, x: 0, y: 0)
                .shadow(color: ringColor.opacity(0.15), radius: 40, x: 0, y: 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: stage)
            
            // Bright dot at progress tip
            if progress > 0.01 {
                GeometryReader { geo in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white, ringColor],
                                center: .center,
                                startRadius: 0,
                                endRadius: lineWidth * 0.5
                            )
                        )
                        .frame(width: lineWidth * 0.55, height: lineWidth * 0.55)
                        .shadow(color: ringColor.opacity(0.9), radius: 12)
                        .shadow(color: ringColor.opacity(0.5), radius: 24)
                        .position(x: geo.size.width / 2, y: lineWidth / 2)
                        .rotationEffect(.degrees(360 * min(progress, 1.0) - 90), anchor: .center)
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: stage)
            }
            
            // Inner decorative ring (thin)
            Circle()
                .stroke(
                    ringColor.opacity(0.08),
                    style: StrokeStyle(lineWidth: 1)
                )
                .padding(lineWidth + 6)
        }
        .modifier(BreathingGlowModifier(isActive: isBreathing, color: ringColor))
        .shimmerRotation(when: isBreathing)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fasting progress")
        .accessibilityValue("\(progressPercent) percent complete, \(stage.rawValue) stage")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Breathing Glow Modifier

/// Subtle breathing glow animation on the progress ring during active fasting.
/// Oscillates shadow radius and opacity in a smooth cycle.
private struct BreathingGlowModifier: ViewModifier {
    let isActive: Bool
    let color: Color
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: isActive ? color.opacity(0.3 + 0.2 * phase) : .clear,
                radius: isActive ? 20 + 10 * phase : 0
            )
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                        phase = 1
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.4)) {
                        phase = 0
                    }
                }
            }
            .onAppear {
                if isActive {
                    withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                        phase = 1
                    }
                }
            }
    }
}

#Preview {
    VStack(spacing: 40) {
        CircularProgressView(progress: 0.65, stage: .fatBurning, themeAccent: .green, isBreathing: true)
            .frame(width: 260, height: 260)
        CircularProgressView(progress: 0.3, stage: .earlyFasting, themeAccent: .blue)
            .frame(width: 200, height: 200)
    }
    .padding()
    .preferredColorScheme(.dark)
}
