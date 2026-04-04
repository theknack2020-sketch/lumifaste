import SwiftUI

/// Article detail view — shows full educational content with scientific references.
struct ArticleDetailView: View {
    let article: FastingEducation.Article
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection
                    .entranceAnimation(delay: 0.1)

                // Article sections
                ForEach(Array(article.sections.enumerated()), id: \.element.id) { index, section in
                    sectionView(section)
                        .staggeredAppear(index: index)
                }

                // References
                referencesSection
                    .entranceAnimation(delay: 0.3)

                // Disclaimer
                disclaimerSection
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 14) {
            Image(systemName: article.icon)
                .font(.adaptiveDisplay(size: 36, weight: .regular, design: .default, isRegular: isRegular))
                .foregroundStyle(article.iconColor)
                .accessibilityHidden(true)

            Text(article.title)
                .font(.adaptiveTitle2(isRegular: isRegular).weight(.bold))
                .multilineTextAlignment(.center)

            Text(article.subtitle)
                .font(.adaptiveSubheadline(isRegular: isRegular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(article.title). \(article.subtitle)")
    }

    // MARK: - Section

    private func sectionView(_ section: FastingEducation.ArticleSection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.heading)
                .font(.adaptiveBody(isRegular: isRegular).weight(.bold))

            Text(section.body)
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
        .accessibilityLabel("\(section.heading): \(section.body)")
    }

    // MARK: - References

    private var referencesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "book.closed.fill")
                    .font(.adaptiveDetail(isRegular: isRegular))
                    .foregroundStyle(.secondary)
                Text("Scientific References")
                    .font(.adaptiveDetail(isRegular: isRegular).weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(article.references.enumerated()), id: \.offset) { _, ref in
                Text(ref)
                    .font(.adaptiveBadge(isRegular: isRegular))
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
    }

    // MARK: - Disclaimer

    private var disclaimerSection: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.adaptiveCaption(isRegular: isRegular))
                .foregroundStyle(.tertiary)
            Text(FastingEducation.shortDisclaimer)
                .font(.adaptiveBadge(isRegular: isRegular))
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(article: FastingEducation.articles[0])
    }
}
