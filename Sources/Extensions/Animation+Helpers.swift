import SwiftUI

// MARK: - Reusable Animation Constants

extension Animation {
    /// Standard spring for state transitions (start/stop fast, stage changes)
    static let smoothSpring = Animation.spring(duration: 0.5, bounce: 0.3)

    /// Quick spring for button taps and small interactions
    static let tapSpring = Animation.spring(duration: 0.3, bounce: 0.4)

    /// Gentle spring for progress bar changes
    static let progressSpring = Animation.spring(duration: 0.6, bounce: 0.15)

    /// Entrance animation
    static let entrance = Animation.spring(duration: 0.7, bounce: 0.25)

    /// Stagger delay helper
    static func staggered(index: Int, base: Animation = .spring(duration: 0.4, bounce: 0.2)) -> Animation {
        base.delay(Double(index) * 0.06)
    }
}

// MARK: - Bouncy Button Style (scale bounce on tap)

/// Subtle scale bounce on button taps — use throughout the app.
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.tapSpring, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BounceButtonStyle {
    static var bounce: BounceButtonStyle {
        BounceButtonStyle()
    }
}

// MARK: - Pressable Button Style (scale + opacity on press)

/// Prominent press effect for major action buttons — start/stop fast, etc.
/// Combines scale reduction with slight opacity fade for tactile feedback.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle {
        PressableButtonStyle()
    }
}

extension View {
    /// Apply PressableButtonStyle — shorthand for `.buttonStyle(.pressable)`
    func pressable() -> some View {
        buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Pulsing Ring Modifier (active timer glow)

struct PulsingModifier: ViewModifier {
    let isActive: Bool
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive && isPulsing ? 1.02 : 1.0)
            .opacity(isActive && isPulsing ? 0.92 : 1.0)
            .onAppear {
                guard isActive else { return }
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    isPulsing = false
                    withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPulsing = false
                    }
                }
            }
    }
}

extension View {
    func pulsing(when active: Bool) -> some View {
        modifier(PulsingModifier(isActive: active))
    }
}

// MARK: - Staggered Appear Modifier (for list items)

struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .onAppear {
                withAnimation(.spring(duration: 0.4, bounce: 0.2).delay(Double(index) * 0.06)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func staggeredAppear(index: Int) -> some View {
        modifier(StaggeredAppearModifier(index: index))
    }
}

// MARK: - Confetti / Particle Effect for Fast Completion

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let velocityX: CGFloat
    let velocityY: CGFloat
}

struct ConfettiView: View {
    let isActive: Bool
    @State private var particles: [ConfettiParticle] = []
    @State private var animationProgress: CGFloat = 0

    private let colors: [Color] = [
        .purple, .blue, .orange, .yellow, .green, .pink, .mint, .cyan,
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    RoundedRectangle(cornerRadius: particle.size * 0.2, style: .continuous)
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size * CGFloat.random(in: 0.5 ... 1.5))
                        .rotationEffect(.degrees(particle.rotation + Double(animationProgress) * 360))
                        .position(
                            x: particle.x + particle.velocityX * animationProgress,
                            y: particle.y + particle.velocityY * animationProgress + 200 * animationProgress * animationProgress
                        )
                        .opacity(Double(max(0, 1 - animationProgress * 0.8)))
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    spawnParticles(in: geo.size)
                    animationProgress = 0
                    withAnimation(.easeOut(duration: 2.0)) {
                        animationProgress = 1
                    }
                    // Clean up after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                        particles.removeAll()
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func spawnParticles(in size: CGSize) {
        particles = (0 ..< 40).map { _ in
            ConfettiParticle(
                x: size.width * 0.5 + CGFloat.random(in: -30 ... 30),
                y: size.height * 0.3,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4 ... 8),
                rotation: Double.random(in: 0 ... 360),
                velocityX: CGFloat.random(in: -120 ... 120),
                velocityY: CGFloat.random(in: -280 ... -80)
            )
        }
    }
}

// MARK: - Entrance Animation Modifier

struct EntranceModifier: ViewModifier {
    @State private var appeared = false
    let delay: Double

    init(delay: Double = 0) {
        self.delay = delay
    }

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.92)
            .onAppear {
                withAnimation(.entrance.delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func entranceAnimation(delay: Double = 0) -> some View {
        modifier(EntranceModifier(delay: delay))
    }
}

// MARK: - Breathing Scale Modifier (idle button pulse)

/// Subtle breathing scale animation — use on idle start buttons.
/// Oscillates scale from 1.0 to maxScale with a smooth easeInOut cycle.
struct BreathingScaleModifier: ViewModifier {
    let isActive: Bool
    let maxScale: CGFloat
    let duration: Double
    @State private var phase = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive && phase ? maxScale : 1.0)
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                        phase = true
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        phase = false
                    }
                }
            }
            .onAppear {
                if isActive {
                    withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                        phase = true
                    }
                }
            }
    }
}

extension View {
    /// Subtle breathing scale animation — idle button pulse
    func breathingScale(when active: Bool, maxScale: CGFloat = 1.05, duration: Double = 2.0) -> some View {
        modifier(BreathingScaleModifier(isActive: active, maxScale: maxScale, duration: duration))
    }
}

// MARK: - Slide-In From Edge Modifier

struct SlideInModifier: ViewModifier {
    let edge: Edge
    let delay: Double
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(x: appeared ? 0 : (edge == .trailing ? 60 : edge == .leading ? -60 : 0),
                    y: appeared ? 0 : (edge == .bottom ? 30 : edge == .top ? -30 : 0))
            .onAppear {
                withAnimation(.spring(duration: 0.6, bounce: 0.2).delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func slideIn(from edge: Edge, delay: Double = 0) -> some View {
        modifier(SlideInModifier(edge: edge, delay: delay))
    }
}

// MARK: - Animated Value Modifier (for growing bars from 0)

struct AnimateFromZeroModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false

    var animatedFraction: Double {
        appeared ? 1.0 : 0.0
    }

    func body(content: Content) -> some View {
        content
            .onAppear {
                withAnimation(.spring(duration: 0.8, bounce: 0.15).delay(delay)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Gold Glow Modifier (for achievement badges)

struct GoldGlowModifier: ViewModifier {
    let isActive: Bool
    @State private var glowPhase = false

    func body(content: Content) -> some View {
        content
            .shadow(
                color: isActive ? Color.yellow.opacity(glowPhase ? 0.6 : 0.2) : .clear,
                radius: isActive ? (glowPhase ? 12 : 4) : 0
            )
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        glowPhase = true
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        glowPhase = false
                    }
                }
            }
            .onAppear {
                if isActive {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        glowPhase = true
                    }
                }
            }
    }
}

extension View {
    func goldGlow(when active: Bool) -> some View {
        modifier(GoldGlowModifier(isActive: active))
    }
}

// MARK: - Shimmer Rotation Modifier (for circular progress)

struct ShimmerRotationModifier: ViewModifier {
    let isActive: Bool
    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    .white.opacity(0),
                                    .white.opacity(0),
                                    .white.opacity(0.15),
                                    .white.opacity(0),
                                    .white.opacity(0),
                                ]),
                                center: .center,
                                startAngle: .degrees(rotation),
                                endAngle: .degrees(rotation + 360)
                            ),
                            lineWidth: 28
                        )
                        .blendMode(.overlay)
                        .allowsHitTesting(false)
                }
            }
            .onAppear {
                if isActive {
                    withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    rotation = 0
                    withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            }
    }
}

extension View {
    func shimmerRotation(when active: Bool) -> some View {
        modifier(ShimmerRotationModifier(isActive: active))
    }
}
