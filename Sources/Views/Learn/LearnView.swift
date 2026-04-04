import SwiftUI

/// Learn tab — educational hub with articles, FAQ, tips, glossary, beginner's guide, and stage science.
/// Mix of free and premium content.
struct LearnView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    @State private var showPaywall = false
    @State private var isLoading = true

    // MARK: - Dynamic Type Support

    @ScaledMetric(relativeTo: .body) private var cardPadding: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var sectionSpacing: CGFloat = 20

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        Spacer()

                        ProgressView()
                            .controlSize(.large)

                        Text("Loading articles…")
                            .font(.adaptiveSubheadline(isRegular: isRegular).weight(.medium))
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
                } else {
                    learnContent
                }
            }
            .navigationTitle("Learn")
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear {
                // Brief loading state for smooth entrance
                if isLoading {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                            isLoading = false
                        }
                    }
                }
            }
        }
    }

    // MARK: - Learn Content

    private var learnContent: some View {
        ScrollView {
            LazyVStack(spacing: sectionSpacing) {
                // Brand header
                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.adaptiveDetail(isRegular: isRegular))
                        .scaleEffect(x: -1)
                        .foregroundStyle(themeManager.selectedTheme.accent)
                    Text("Lumifaste Learn")
                        .font(.adaptiveDetail(isRegular: isRegular).weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

                // Quick links
                quickLinks
                    .padding(.horizontal, 16)
                    .entranceAnimation(delay: 0.1)

                // Fasting stages science
                stagesSection
                    .padding(.horizontal, 16)
                    .entranceAnimation(delay: 0.2)

                // Articles
                articlesSection
                    .padding(.horizontal, 16)
                    .entranceAnimation(delay: 0.3)

                // Disclaimer
                disclaimerBanner
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
            .padding(.top, 12)
        }
    }

    // MARK: - Quick Links

    private var quickLinks: some View {
        let accent = themeManager.selectedTheme.accent
        return VStack(alignment: .leading, spacing: 12) {
            Text("Explore")
                .font(.system(.headline, design: .rounded))

            LazyVGrid(columns: .adaptive(compact: 2, regular: 3, spacing: 10, isRegular: isRegular), spacing: 10) {
                NavigationLink {
                    BeginnersGuideView()
                } label: {
                    QuickLinkCard(
                        title: "Beginner's Guide",
                        icon: "graduationcap.fill",
                        color: .green,
                        accentColor: accent
                    )
                }
                .buttonStyle(.pressable)

                NavigationLink {
                    TipsView()
                } label: {
                    QuickLinkCard(
                        title: "Fasting Tips",
                        icon: "lightbulb.fill",
                        color: .yellow,
                        accentColor: accent
                    )
                }
                .buttonStyle(.pressable)

                NavigationLink {
                    FaqView()
                } label: {
                    QuickLinkCard(
                        title: "FAQ",
                        icon: "questionmark.circle.fill",
                        color: .blue,
                        accentColor: accent
                    )
                }
                .buttonStyle(.pressable)

                NavigationLink {
                    GlossaryView()
                } label: {
                    QuickLinkCard(
                        title: "Glossary",
                        icon: "text.book.closed.fill",
                        color: .purple,
                        accentColor: accent
                    )
                }
                .buttonStyle(.pressable)

                NavigationLink {
                    RecipesView()
                } label: {
                    QuickLinkCard(
                        title: "Recipes",
                        icon: "fork.knife",
                        color: .orange,
                        accentColor: accent
                    )
                }
                .buttonStyle(.pressable)
            }
        }
    }

    // MARK: - Fasting Stages

    private var stagesSection: some View {
        let accent = themeManager.selectedTheme.accent
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.xaxis.ascending")
                    .font(.adaptiveDetail(isRegular: isRegular))
                    .foregroundStyle(accent)
                Text("Fasting Stages")
                    .font(.system(.headline, design: .rounded))
            }

            Text("Understand what happens to your body at each stage of fasting.")
                .font(.adaptiveDetail(isRegular: isRegular))
                .foregroundStyle(.secondary)

            // Contextual science disclaimer
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.adaptiveCaption(isRegular: isRegular))
                    .foregroundStyle(.blue.opacity(0.7))
                Text("Stages are based on general research. Individual results vary — this is educational content, not medical advice.")
                    .font(.adaptiveBadge(isRegular: isRegular))
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.blue.opacity(0.06))
            )
            .accessibilityLabel("Disclaimer: Stages are based on general research. Individual results vary.")
            .accessibilityIdentifier("stagesScienceDisclaimer")

            ForEach(Array(FastingEducation.stageDetails.enumerated()), id: \.element.id) { index, detail in
                NavigationLink {
                    StageDetailView(detail: detail)
                } label: {
                    StageCard(detail: detail)
                }
                .buttonStyle(.pressable)
                .staggeredAppear(index: index)
            }
        }
    }

    // MARK: - Articles

    private var articlesSection: some View {
        let accent = themeManager.selectedTheme.accent
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "doc.richtext")
                    .font(.adaptiveDetail(isRegular: isRegular))
                    .foregroundStyle(accent)
                Text("Articles")
                    .font(.system(.headline, design: .rounded))
            }

            ForEach(Array(FastingEducation.articles.enumerated()), id: \.element.id) { index, article in
                if article.isPremium, !subscriptionManager.isSubscribed {
                    Button {
                        HapticManager.shared.lightTap()
                        showPaywall = true
                    } label: {
                        ArticleCard(article: article, isLocked: true)
                    }
                    .buttonStyle(.pressable)
                    .staggeredAppear(index: index)
                } else {
                    NavigationLink {
                        ArticleDetailView(article: article)
                    } label: {
                        ArticleCard(article: article, isLocked: false)
                    }
                    .buttonStyle(.pressable)
                    .staggeredAppear(index: index)
                }
            }
        }
    }

    // MARK: - Disclaimer

    private var disclaimerBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "heart.text.square.fill")
                .font(.adaptiveHeadline(isRegular: isRegular))
                .foregroundStyle(.red)

            VStack(alignment: .leading, spacing: 4) {
                Text("Health Disclaimer")
                    .font(.system(.headline, design: .rounded))
                Text(FastingEducation.shortDisclaimer)
                    .font(.adaptiveCaption(isRegular: isRegular))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.red.opacity(0.06))
                )
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.red.gradient)
                .frame(width: 3)
                .padding(.vertical, 8)
        }
        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
    }
}

// MARK: - Quick Link Card

private struct QuickLinkCard: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    let title: String
    let icon: String
    let color: Color
    var accentColor: Color = .blue

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.adaptiveTitle3(isRegular: isRegular))
                .foregroundStyle(color)

            Text(title)
                .font(.adaptiveDetail(isRegular: isRegular).weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.08), color.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .shadow(color: color.opacity(0.1), radius: 6, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

// MARK: - Stage Card

private struct StageCard: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    let detail: FastingEducation.StageDetail

    var body: some View {
        HStack(spacing: 12) {
            // Accent left bar
            RoundedRectangle(cornerRadius: 1.5)
                .fill(detail.stage.color.gradient)
                .frame(width: 3, height: 40)

            Image(systemName: detail.stage.icon)
                .font(.adaptiveHeadline(isRegular: isRegular))
                .foregroundStyle(detail.stage.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(detail.stage.rawValue)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.primary)
                Text(detail.headline)
                    .font(.adaptiveCaption(isRegular: isRegular))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(detail.stage.startHour))h+")
                    .font(.adaptiveCaption(isRegular: isRegular).weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(detail.stage.color)
            }

            Image(systemName: "chevron.right")
                .font(.adaptiveBadge(isRegular: isRegular))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .shadow(color: detail.stage.color.opacity(0.12), radius: 6, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(detail.stage.rawValue) stage, starts at \(Int(detail.stage.startHour)) hours. \(detail.headline)")
    }
}

// MARK: - Article Card

private struct ArticleCard: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    let article: FastingEducation.Article
    let isLocked: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Accent left bar
            RoundedRectangle(cornerRadius: 1.5)
                .fill(isLocked ? Color.gray.gradient : article.iconColor.gradient)
                .frame(width: 3, height: 40)

            Image(systemName: article.icon)
                .font(.adaptiveTitle3(isRegular: isRegular))
                .foregroundStyle(isLocked ? .secondary : article.iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(article.title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.primary)

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.adaptiveCaption(isRegular: isRegular))
                            .foregroundStyle(.secondary)
                            .padding(4)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                            )
                    }
                }

                Text(article.subtitle)
                    .font(.adaptiveCaption(isRegular: isRegular))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.adaptiveBadge(isRegular: isRegular))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .shadow(color: (isLocked ? Color.gray : article.iconColor).opacity(0.08), radius: 6, y: 2)
        .opacity(isLocked ? 0.7 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isLocked ? "\(article.title), Premium content, locked" : article.title)
        .accessibilityHint(isLocked ? "Upgrade to Premium to read this article" : "")
    }
}

#Preview {
    LearnView()
        .environment(SubscriptionManager())
        .environment(ThemeManager())
}
