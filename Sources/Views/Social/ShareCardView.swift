import SwiftUI

// MARK: - Share Card (rendered to image via ImageRenderer)

/// Shareable image card showing fast results + app branding.
/// Rendered via ImageRenderer to UIImage for ShareLink.
struct FastShareCard: View {
    let duration: TimeInterval
    let stage: FastingStage
    let plan: FastingPlan
    let streak: Int
    
    var body: some View {
        VStack(spacing: 0) {
            // Top gradient header
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.28, green: 0.25, blue: 0.55), Color(red: 0.18, green: 0.15, blue: 0.40)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 28))
                        .scaleEffect(x: -1)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Text("Lumifaste")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.top, 16)
                .padding(.bottom, 12)
            }
            .frame(height: 100)
            
            // Content
            VStack(spacing: 20) {
                // Big duration
                VStack(spacing: 4) {
                    Text("I fasted for")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    
                    Text(formatDuration(duration))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                .padding(.top, 20)
                
                // Stats row
                HStack(spacing: 0) {
                    cardStat(title: "Plan", value: plan.rawValue, icon: "calendar", color: .orange)
                    
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: 1, height: 40)
                    
                    cardStat(title: "Stage", value: stage.rawValue, icon: stage.icon, color: stage.color)
                    
                    if streak > 0 {
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(width: 1, height: 40)
                        
                        cardStat(title: "Streak", value: "\(streak) days", icon: "flame.fill", color: .orange)
                    }
                }
                .padding(.horizontal, 8)
                
                // Stage badge
                HStack(spacing: 6) {
                    Image(systemName: stage.icon)
                        .font(.system(size: 14, weight: .semibold))
                    Text(stage.subtitle)
                        .font(.system(size: 13))
                }
                .foregroundStyle(stage.color)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(stage.color.opacity(0.12))
                .clipShape(Capsule())
                
                // Footer branding
                HStack(spacing: 4) {
                    Text("Track your fasts with")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    Text("Lumifaste")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("🍃")
                        .font(.system(size: 11))
                }
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
        }
        .frame(width: 340)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }
    
    private func cardStat(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}

// MARK: - Streak Milestone Share Card

struct StreakShareCard: View {
    let streakDays: Int
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 0) {
            // Top gradient
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.85, green: 0.45, blue: 0.1), Color(red: 0.75, green: 0.3, blue: 0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 28))
                        .scaleEffect(x: -1)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Text("Lumifaste")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.top, 16)
                .padding(.bottom, 12)
            }
            .frame(height: 100)
            
            VStack(spacing: 16) {
                // Big streak number
                VStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 40))
                    
                    Text("\(streakDays)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("Day Streak!")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                // Achievement badge
                HStack(spacing: 8) {
                    Image(systemName: achievement.icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(achievement.color)
                    Text(achievement.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(achievement.color)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(achievement.color.opacity(0.12))
                .clipShape(Capsule())
                
                // Footer
                HStack(spacing: 4) {
                    Text("Track your fasts with")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    Text("Lumifaste")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("🍃")
                        .font(.system(size: 11))
                }
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
        }
        .frame(width: 340)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }
}

// MARK: - Image Renderer Helper

@MainActor
enum ShareImageRenderer {
    
    /// Render a FastShareCard to UIImage using ImageRenderer.
    static func renderFastCard(
        duration: TimeInterval,
        stage: FastingStage,
        plan: FastingPlan,
        streak: Int
    ) -> UIImage? {
        let card = FastShareCard(duration: duration, stage: stage, plan: plan, streak: streak)
        let renderer = ImageRenderer(content: card)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
    
    /// Render a StreakShareCard to UIImage.
    static func renderStreakCard(
        streakDays: Int,
        achievement: Achievement
    ) -> UIImage? {
        let card = StreakShareCard(streakDays: streakDays, achievement: achievement)
        let renderer = ImageRenderer(content: card)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}

// MARK: - Transferable Image Wrapper (for ShareLink)

struct ShareableImage: Transferable {
    let image: UIImage
    let caption: String
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            guard let data = item.image.pngData() else {
                throw ShareError.renderFailed
            }
            return data
        }
    }
    
    enum ShareError: Error {
        case renderFailed
    }
}

#Preview("Fast Card") {
    FastShareCard(
        duration: 16 * 3600 + 23 * 60,
        stage: .fatBurning,
        plan: .sixteenEight,
        streak: 7
    )
    .padding()
    .background(Color(.systemGray5))
}

#Preview("Streak Card") {
    StreakShareCard(
        streakDays: 7,
        achievement: .sevenDayStreak
    )
    .padding()
    .background(Color(.systemGray5))
}
