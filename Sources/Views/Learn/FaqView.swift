import SwiftUI

/// Frequently Asked Questions about intermittent fasting.
/// 17 questions organized by category with expandable answers.
struct FaqView: View {
    @State private var expandedIds: Set<Int> = []
    @State private var selectedCategory: String?
    
    private var categories: [String] {
        FastingEducation.faqCategories
    }
    
    private var filteredFaqs: [FastingEducation.FAQ] {
        if let cat = selectedCategory {
            return FastingEducation.faqs(for: cat)
        }
        return FastingEducation.faqs
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Category filter
                categoryFilter
                    .padding(.horizontal, 16)
                    .entranceAnimation(delay: 0.1)
                
                // FAQ items
                ForEach(Array(filteredFaqs.enumerated()), id: \.element.id) { index, faq in
                    FaqCard(
                        faq: faq,
                        isExpanded: expandedIds.contains(faq.id)
                    ) {
                        withAnimation(.smoothSpring) {
                            if expandedIds.contains(faq.id) {
                                expandedIds.remove(faq.id)
                            } else {
                                expandedIds.insert(faq.id)
                            }
                        }
                        HapticManager.shared.lightTap()
                    }
                    .padding(.horizontal, 16)
                    .staggeredAppear(index: index)
                }
                
                // Disclaimer
                disclaimerFooter
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
            }
            .padding(.top, 12)
        }
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Category Filter
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedCategory == nil) {
                    HapticManager.shared.selectionChanged()
                    withAnimation(.tapSpring) { selectedCategory = nil }
                }
                
                ForEach(categories, id: \.self) { cat in
                    FilterChip(title: cat, isSelected: selectedCategory == cat) {
                        HapticManager.shared.selectionChanged()
                        withAnimation(.tapSpring) { selectedCategory = cat }
                    }
                }
            }
        }
    }
    
    // MARK: - Disclaimer
    
    private var disclaimerFooter: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
            Text(FastingEducation.shortDisclaimer)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.bounce)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - FAQ Card

private struct FaqCard: View {
    let faq: FastingEducation.FAQ
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Question
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.accentColor)
                    
                    Text(faq.question)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.smoothSpring, value: isExpanded)
                }
                .padding(14)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(faq.question)
            .accessibilityHint(isExpanded ? "Collapse answer" : "Expand answer")
            
            // Answer
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    Text(faq.answer)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(faq.category)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .contain)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isExpanded)
    }
}

#Preview {
    NavigationStack {
        FaqView()
    }
}
