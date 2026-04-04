import SwiftUI

/// Beginner's guide to intermittent fasting.
/// Step-by-step walkthrough for new fasters.
struct BeginnersGuideView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Header
                headerCard
                    .padding(.horizontal, 16)
                    .entranceAnimation(delay: 0.1)

                // Guide sections
                ForEach(Array(FastingEducation.beginnersGuide.enumerated()), id: \.element.id) { index, section in
                    GuideSectionCard(section: section)
                        .padding(.horizontal, 16)
                        .staggeredAppear(index: index)
                }

                // Disclaimer
                disclaimerCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
            .padding(.top, 12)
        }
        .navigationTitle("Beginner's Guide")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "graduationcap.fill")
                .font(.adaptiveDisplay(size: 36, weight: .regular, design: .default, isRegular: isRegular))
                .foregroundStyle(
                    .linearGradient(
                        colors: [Color.accentColor, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .accessibilityHidden(true)

            Text("Your Fasting Journey Starts Here")
                .font(.adaptiveTitle3(isRegular: isRegular).weight(.bold))
                .multilineTextAlignment(.center)

            Text("Everything you need to know to start intermittent fasting safely and effectively.")
                .font(.adaptiveDetail(isRegular: isRegular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your fasting journey starts here. Everything you need to know to start intermittent fasting safely and effectively.")
    }

    // MARK: - Disclaimer

    private var disclaimerCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "heart.text.square.fill")
                .font(.adaptiveSubheadline(isRegular: isRegular))
                .foregroundStyle(.red)

            Text(FastingEducation.shortDisclaimer)
                .font(.adaptiveCaption(isRegular: isRegular))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.red.opacity(0.06))
        )
    }
}

// MARK: - Guide Section Card

private struct GuideSectionCard: View {
    let section: FastingEducation.GuideSection
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var isExpanded = true

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header — tappable
            Button {
                HapticManager.shared.lightTap()
                withAnimation(.smoothSpring) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: section.icon)
                        .font(.adaptiveTitle3(isRegular: isRegular))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 28)
                        .accessibilityHidden(true)

                    Text(section.title)
                        .font(.adaptiveSubheadline(isRegular: isRegular).weight(.bold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.adaptiveCaption(isRegular: isRegular).weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
            }
            .buttonStyle(.pressable)

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text(section.content)
                        .font(.adaptiveDetail(isRegular: isRegular))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(section.keyPoints, id: \.self) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.adaptiveDetail(isRegular: isRegular))
                                    .foregroundStyle(.green)
                                    .padding(.top, 1)

                                Text(point)
                                    .font(.adaptiveDetail(isRegular: isRegular))
                                    .foregroundStyle(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(section.title) section")
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isExpanded)
    }
}

#Preview {
    NavigationStack {
        BeginnersGuideView()
    }
}
