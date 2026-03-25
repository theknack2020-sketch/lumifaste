import SwiftUI

/// Detailed educational view for a specific fasting stage.
/// Shows what happens to the body, metabolic info, tips, and scientific references.
struct StageDetailView: View {
    let detail: FastingEducation.StageDetail
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Stage header
                headerSection
                    .entranceAnimation(delay: 0.1)
                
                // Body text
                bodySection
                    .entranceAnimation(delay: 0.2)
                
                // Metabolic info
                metabolicSection
                    .entranceAnimation(delay: 0.25)
                
                // What happens
                whatHappensSection
                    .entranceAnimation(delay: 0.3)
                
                // Tips
                tipsSection
                    .entranceAnimation(delay: 0.35)
                
                // Reference
                referenceSection
                    .entranceAnimation(delay: 0.4)
                
                // Disclaimer
                disclaimerFooter
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .navigationTitle(detail.stage.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: detail.stage.icon)
                .font(.system(size: 36))
                .foregroundStyle(detail.stage.color)
                .accessibilityLabel("\(detail.stage.rawValue) stage icon")
            
            Text(detail.headline)
                .font(.system(size: 22, weight: .bold))
            
            HStack(spacing: 6) {
                Text("Starts at \(Int(detail.stage.startHour))h")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(detail.stage.color)
                
                if let next = detail.stage.next {
                    Text("→")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                    Text("\(next.rawValue) at \(Int(next.startHour))h")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [detail.stage.color.opacity(0.12), detail.stage.color.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: detail.stage.color.opacity(0.15), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(detail.stage.rawValue) stage. \(detail.headline). Starts at \(Int(detail.stage.startHour)) hours.")
    }
    
    // MARK: - Body
    
    private var bodySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Overview")
                .font(.system(size: 15, weight: .semibold))
            Text(detail.bodyText)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Overview: \(detail.bodyText)")
    }
    
    // MARK: - Metabolic Info
    
    private var metabolicSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
                Text("Metabolic State")
                    .font(.system(size: 15, weight: .semibold))
            }
            Text(detail.metabolicInfo)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.orange.opacity(0.06))
        )
        .shadow(color: .orange.opacity(0.1), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Metabolic state: \(detail.metabolicInfo)")
    }
    
    // MARK: - What Happens
    
    private var whatHappensSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "body.text")
                    .font(.system(size: 13))
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)
                Text("What Happens to Your Body")
                    .font(.system(size: 15, weight: .semibold))
            }
            
            ForEach(detail.whatHappens, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 5))
                        .foregroundStyle(detail.stage.color)
                        .padding(.top, 6)
                    
                    Text(item)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - Tips
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.yellow)
                    .accessibilityHidden(true)
                Text("Tips for This Stage")
                    .font(.system(size: 15, weight: .semibold))
            }
            
            ForEach(detail.tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.green)
                        .padding(.top, 1)
                    
                    Text(tip)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .yellow.opacity(0.08), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - Reference
    
    private var referenceSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text("Reference")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Text(detail.reference)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
    }
    
    // MARK: - Disclaimer
    
    private var disclaimerFooter: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 16))
                .foregroundStyle(.red.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Health Disclaimer")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("The fasting stages described are based on general research. Individual results vary. This is not medical advice — always consult your healthcare provider before starting any fasting program.")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.red.opacity(0.04))
                )
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.red.gradient)
                .frame(width: 3)
                .padding(.vertical, 6)
        }
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Health disclaimer. The fasting stages described are based on general research. This is not medical advice. Always consult your healthcare provider.")
        .accessibilityIdentifier("stageDetailDisclaimer")
    }
}

#Preview {
    NavigationStack {
        StageDetailView(detail: FastingEducation.stageDetails[2])
    }
}
