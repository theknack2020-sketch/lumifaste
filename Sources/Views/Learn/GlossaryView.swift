import SwiftUI

/// Glossary of fasting terms — autophagy, ketosis, etc.
/// Searchable, alphabetically sorted.
struct GlossaryView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var searchText = ""

    private var isRegular: Bool {
        sizeClass == .regular
    }

    private var filteredTerms: [FastingEducation.GlossaryTerm] {
        if searchText.isEmpty {
            return FastingEducation.glossary.sorted { $0.term < $1.term }
        }
        let query = searchText.lowercased()
        return FastingEducation.glossary
            .filter { $0.term.lowercased().contains(query) || $0.definition.lowercased().contains(query) }
            .sorted { $0.term < $1.term }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(Array(filteredTerms.enumerated()), id: \.element.id) { index, term in
                    GlossaryCard(term: term)
                        .padding(.horizontal, 16)
                        .staggeredAppear(index: min(index, 10))
                }

                if filteredTerms.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.adaptiveDisplay(size: 32, weight: .regular, design: .default, isRegular: isRegular))
                            .foregroundStyle(.tertiary)
                        Text("No matching terms")
                            .font(.adaptiveSubheadline(isRegular: isRegular))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .navigationTitle("Glossary")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search terms")
    }
}

// MARK: - Glossary Card

private struct GlossaryCard: View {
    let term: FastingEducation.GlossaryTerm
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var isExpanded = false

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                HapticManager.shared.lightTap()
                withAnimation(.smoothSpring) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    Text(term.term)
                        .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.adaptiveBadge(isRegular: isRegular).weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(14)
            }
            .buttonStyle(.pressable)

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()

                    Text(term.definition)
                        .font(.adaptiveDetail(isRegular: isRegular))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if !term.relatedTerms.isEmpty {
                        HStack(spacing: 6) {
                            Text("Related:")
                                .font(.adaptiveBadge(isRegular: isRegular))
                                .foregroundStyle(.tertiary)

                            ForEach(term.relatedTerms, id: \.self) { related in
                                Text(related)
                                    .font(.adaptiveBadge(isRegular: isRegular).weight(.medium))
                                    .foregroundStyle(Color.accentColor)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule().fill(Color.accentColor.opacity(0.1))
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(term.term): \(term.definition)")
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isExpanded)
    }
}

#Preview {
    NavigationStack {
        GlossaryView()
    }
}
