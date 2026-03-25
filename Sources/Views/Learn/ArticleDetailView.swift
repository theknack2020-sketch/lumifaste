import SwiftUI

/// Article detail view — shows full educational content with scientific references.
struct ArticleDetailView: View {
    let article: FastingEducation.Article
    
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
                .font(.system(size: 36))
                .foregroundStyle(article.iconColor)
                .accessibilityHidden(true)
            
            Text(article.title)
                .font(.system(size: 22, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text(article.subtitle)
                .font(.system(size: 15))
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
                .font(.system(size: 17, weight: .bold))
            
            Text(section.body)
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
        .accessibilityLabel("\(section.heading): \(section.body)")
    }
    
    // MARK: - References
    
    private var referencesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Text("Scientific References")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            
            ForEach(Array(article.references.enumerated()), id: \.offset) { _, ref in
                Text(ref)
                    .font(.system(size: 11))
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
        ArticleDetailView(article: FastingEducation.articles[0])
    }
}
