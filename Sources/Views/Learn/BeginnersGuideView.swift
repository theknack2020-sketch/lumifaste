import SwiftUI

/// Beginner's guide to intermittent fasting.
/// Step-by-step walkthrough for new fasters.
struct BeginnersGuideView: View {
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
                .font(.system(size: 36))
                .foregroundStyle(
                    .linearGradient(
                        colors: [Color.accentColor, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Your Fasting Journey Starts Here")
                .font(.system(size: 20, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("Everything you need to know to start intermittent fasting safely and effectively.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Disclaimer
    
    private var disclaimerCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 16))
                .foregroundStyle(.red)
            
            Text(FastingEducation.shortDisclaimer)
                .font(.system(size: 12))
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
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header — tappable
            Button {
                withAnimation(.smoothSpring) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: section.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 28)
                    
                    Text(section.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text(section.content)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(section.keyPoints, id: \.self) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.green)
                                    .padding(.top, 1)
                                
                                Text(point)
                                    .font(.system(size: 13))
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
    }
}

#Preview {
    NavigationStack {
        BeginnersGuideView()
    }
}
