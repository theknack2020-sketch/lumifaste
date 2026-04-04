import SwiftUI

/// Detailed educational view for a specific fasting stage.
/// Shows what happens to the body, metabolic info, tips, and scientific references.
struct StageDetailView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

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
                .font(.adaptiveDisplay(size: 36, weight: .regular, design: .default, isRegular: isRegular))
                .foregroundStyle(detail.stage.color)
                .accessibilityLabel("\(detail.stage.rawValue) stage icon")

            Text(detail.headline)
                .font(.adaptiveTitle3(isRegular: isRegular).weight(.bold))

            HStack(spacing: 6) {
                Text("Starts at \(Int(detail.stage.startHour))h")
                    .font(.adaptiveDetail(isRegular: isRegular).weight(.medium))
                    .foregroundStyle(detail.stage.color)

                if let next = detail.stage.next {
                    Text("→")
                        .font(.adaptiveDetail(isRegular: isRegular))
                        .foregroundStyle(.tertiary)
                    Text("\(next.rawValue) at \(Int(next.startHour))h")
                        .font(.adaptiveDetail(isRegular: isRegular))
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
                .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))
            Text(detail.bodyText)
                .font(.adaptiveDetail(isRegular: isRegular))
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
                    .font(.adaptiveDetail(isRegular: isRegular))
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
                Text("Metabolic State")
                    .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))
            }
            Text(detail.metabolicInfo)
                .font(.adaptiveDetail(isRegular: isRegular))
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
                    .font(.adaptiveDetail(isRegular: isRegular))
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)
                Text("What Happens to Your Body")
                    .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))
            }

            ForEach(detail.whatHappens, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.adaptiveCaption2(isRegular: isRegular))
                        .foregroundStyle(detail.stage.color)
                        .padding(.top, 6)

                    Text(item)
                        .font(.adaptiveDetail(isRegular: isRegular))
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
                    .font(.adaptiveDetail(isRegular: isRegular))
                    .foregroundStyle(.yellow)
                    .accessibilityHidden(true)
                Text("Tips for This Stage")
                    .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))
            }

            ForEach(detail.tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.adaptiveDetail(isRegular: isRegular))
                        .foregroundStyle(.green)
                        .padding(.top, 1)

                    Text(tip)
                        .font(.adaptiveDetail(isRegular: isRegular))
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
                    .font(.adaptiveCaption(isRegular: isRegular))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text("Reference")
                    .font(.adaptiveCaption(isRegular: isRegular).weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text(detail.reference)
                .font(.adaptiveBadge(isRegular: isRegular))
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
                .font(.adaptiveSubheadline(isRegular: isRegular))
                .foregroundStyle(.red.opacity(0.7))

            VStack(alignment: .leading, spacing: 4) {
                Text("Health Disclaimer")
                    .font(.adaptiveDetail(isRegular: isRegular).weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("The fasting stages described are based on general research. Individual results vary. This is not medical advice — always consult your healthcare provider before starting any fasting program.")
                    .font(.adaptiveCaption(isRegular: isRegular))
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
