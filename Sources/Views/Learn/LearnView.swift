import SwiftUI

/// Learn tab — educational hub with articles, FAQ, tips, glossary, beginner's guide, and stage science.
/// Mix of free and premium content.
struct LearnView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var showPaywall = false
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        Spacer()
                        
                        ProgressView()
                            .controlSize(.large)
                        
                        Text("Loading articles…")
                            .font(.system(size: 15, weight: .medium))
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
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear {
                // Brief loading state for smooth entrance
                if isLoading {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.easeOut(duration: 0.3)) {
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
            LazyVStack(spacing: 20) {
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Explore")
                .font(.system(size: 15, weight: .semibold))
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                NavigationLink {
                    BeginnersGuideView()
                } label: {
                    QuickLinkCard(
                        title: "Beginner's Guide",
                        icon: "graduationcap.fill",
                        color: .green
                    )
                }
                .buttonStyle(.bounce)
                
                NavigationLink {
                    TipsView()
                } label: {
                    QuickLinkCard(
                        title: "Fasting Tips",
                        icon: "lightbulb.fill",
                        color: .yellow
                    )
                }
                .buttonStyle(.bounce)
                
                NavigationLink {
                    FaqView()
                } label: {
                    QuickLinkCard(
                        title: "FAQ",
                        icon: "questionmark.circle.fill",
                        color: .blue
                    )
                }
                .buttonStyle(.bounce)
                
                NavigationLink {
                    GlossaryView()
                } label: {
                    QuickLinkCard(
                        title: "Glossary",
                        icon: "text.book.closed.fill",
                        color: .purple
                    )
                }
                .buttonStyle(.bounce)
            }
        }
    }
    
    // MARK: - Fasting Stages
    
    private var stagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.xaxis.ascending")
                    .font(.system(size: 14))
                    .foregroundStyle(.orange)
                Text("Fasting Stages")
                    .font(.system(size: 15, weight: .semibold))
            }
            
            Text("Understand what happens to your body at each stage of fasting.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            
            ForEach(FastingEducation.stageDetails) { detail in
                NavigationLink {
                    StageDetailView(detail: detail)
                } label: {
                    StageCard(detail: detail)
                }
                .buttonStyle(.bounce)
            }
        }
    }
    
    // MARK: - Articles
    
    private var articlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 14))
                    .foregroundStyle(.blue)
                Text("Articles")
                    .font(.system(size: 15, weight: .semibold))
            }
            
            ForEach(FastingEducation.articles) { article in
                if article.isPremium && !subscriptionManager.isSubscribed {
                    Button {
                        HapticManager.shared.lightTap()
                        showPaywall = true
                    } label: {
                        ArticleCard(article: article, isLocked: true)
                    }
                    .buttonStyle(.bounce)
                } else {
                    NavigationLink {
                        ArticleDetailView(article: article)
                    } label: {
                        ArticleCard(article: article, isLocked: false)
                    }
                    .buttonStyle(.bounce)
                }
            }
        }
    }
    
    // MARK: - Disclaimer
    
    private var disclaimerBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 18))
                .foregroundStyle(.red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Health Disclaimer")
                    .font(.system(size: 13, weight: .semibold))
                Text(FastingEducation.shortDisclaimer)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.red.opacity(0.06))
        )
    }
}

// MARK: - Quick Link Card

private struct QuickLinkCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

// MARK: - Stage Card

private struct StageCard: View {
    let detail: FastingEducation.StageDetail
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: detail.stage.icon)
                .font(.system(size: 18))
                .foregroundStyle(detail.stage.color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(detail.stage.rawValue)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(detail.headline)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(detail.stage.startHour))h+")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(detail.stage.color)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(detail.stage.rawValue) stage, starts at \(Int(detail.stage.startHour)) hours. \(detail.headline)")
    }
}

// MARK: - Article Card

private struct ArticleCard: View {
    let article: FastingEducation.Article
    let isLocked: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: article.icon)
                .font(.system(size: 20))
                .foregroundStyle(isLocked ? .secondary : article.iconColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(article.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text(article.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .opacity(isLocked ? 0.7 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isLocked ? "\(article.title), Premium content, locked" : article.title)
        .accessibilityHint(isLocked ? "Upgrade to Premium to read this article" : "")
    }
}

#Preview {
    LearnView()
        .environment(SubscriptionManager())
}
