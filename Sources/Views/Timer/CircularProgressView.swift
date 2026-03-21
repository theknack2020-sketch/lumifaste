import SwiftUI

/// Circular progress ring — oruç ilerlemesini gösterir.
struct CircularProgressView: View {
    let progress: Double
    let stage: FastingStage
    let lineWidth: CGFloat
    
    init(progress: Double, stage: FastingStage, lineWidth: CGFloat = 20) {
        self.progress = progress
        self.stage = stage
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    stage.color.opacity(0.15),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            
            // Progress ring
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            stage.color.opacity(0.6),
                            stage.color
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * progress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
            
            // Glow at progress tip
            if progress > 0.01 {
                Circle()
                    .fill(stage.color)
                    .frame(width: lineWidth * 0.6, height: lineWidth * 0.6)
                    .shadow(color: stage.color.opacity(0.6), radius: 6)
                    .offset(y: -UIScreen.main.bounds.width * 0.35 / 2)
                    .rotationEffect(.degrees(360 * progress - 90))
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        CircularProgressView(progress: 0.65, stage: .fatBurning)
            .frame(width: 250, height: 250)
        CircularProgressView(progress: 0.3, stage: .earlyFasting)
            .frame(width: 200, height: 200)
    }
    .padding()
    .preferredColorScheme(.dark)
}
