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
                .fill(detail.stage.color.opacity(0.08))
        )
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
    }
    
    // MARK: - Metabolic Info
    
    private var metabolicSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.orange)
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
    }
    
    // MARK: - What Happens
    
    private var whatHappensSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "body.text")
                    .font(.system(size: 13))
                    .foregroundStyle(.blue)
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
    }
    
    // MARK: - Tips
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.yellow)
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
    }
    
    // MARK: - Reference
    
    private var referenceSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
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
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
            Text(FastingEducation.shortDisclaimer)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        StageDetailView(detail: FastingEducation.stageDetails[2])
    }
}
