import SwiftUI

/// Browsable fasting tips organized by category.
/// Shows categorized tips with educational context.
struct TipsView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selectedCategory: FastingTips.Category?

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Daily tip highlight
                dailyTipCard
                    .padding(.horizontal, 16)
                    .entranceAnimation(delay: 0.1)

                // Category grid
                categoryGrid
                    .padding(.horizontal, 16)
                    .entranceAnimation(delay: 0.2)

                // Tips for selected category (or all)
                tipsSection
                    .padding(.horizontal, 16)
                    .entranceAnimation(delay: 0.3)

                // Disclaimer
                disclaimerFooter
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
            .padding(.top, 12)
        }
        .navigationTitle("Fasting Tips")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Daily Tip

    private var dailyTipCard: some View {
        let tip = FastingTips.dailyTip()
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.adaptiveDetail(isRegular: isRegular))
                    .foregroundStyle(.yellow)
                Text("Tip of the Day")
                    .font(.adaptiveDetail(isRegular: isRegular).weight(.bold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Text(tip.emoji)
                    .font(.adaptiveDisplay(size: 28, weight: .regular, design: .default, isRegular: isRegular))

                Text(tip.text)
                    .font(.adaptiveSubheadline(isRegular: isRegular))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(tip.category.rawValue)
                .font(.adaptiveBadge(isRegular: isRegular).weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.accentColor))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tip of the day: \(tip.text)")
    }

    // MARK: - Category Grid

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Categories")
                .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryChip(title: "All", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
                        HapticManager.shared.selectionChanged()
                        withAnimation(.tapSpring) { selectedCategory = nil }
                    }

                    ForEach(FastingTips.Category.allCases) { category in
                        CategoryChip(
                            title: category.rawValue,
                            icon: category.icon,
                            isSelected: selectedCategory == category
                        ) {
                            withAnimation(.tapSpring) {
                                HapticManager.shared.selectionChanged()
                                selectedCategory = category
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Tips List

    private var tipsSection: some View {
        let filteredTips = selectedCategory.map { FastingTips.tips(for: $0) } ?? FastingTips.tips

        return LazyVStack(spacing: 10) {
            ForEach(Array(filteredTips.enumerated()), id: \.element.id) { index, tip in
                TipCard(tip: tip)
                    .staggeredAppear(index: index)
            }
        }
    }

    // MARK: - Disclaimer

    private var disclaimerFooter: some View {
        HStack(spacing: 8) {
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

// MARK: - Category Chip

private struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.adaptiveCaption(isRegular: isRegular))
                Text(title)
                    .font(.adaptiveDetail(isRegular: isRegular).weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.bounce)
        .accessibilityLabel("\(title) category")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Tip Card

private struct TipCard: View {
    let tip: FastingTips.Tip
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(tip.emoji)
                .font(.adaptiveTitle2(isRegular: isRegular))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(tip.text)
                    .font(.adaptiveDetail(isRegular: isRegular))
                    .fixedSize(horizontal: false, vertical: true)

                Text(tip.category.rawValue)
                    .font(.adaptiveBadge(isRegular: isRegular))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tip.category.rawValue) tip: \(tip.text)")
    }
}

#Preview {
    NavigationStack {
        TipsView()
    }
}
