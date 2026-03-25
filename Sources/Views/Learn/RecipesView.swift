import SwiftUI

/// Browse fasting-friendly recipes with category filtering and premium gating.
struct RecipesView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(ThemeManager.self) private var themeManager
    @State private var selectedCategory: FastingRecipe.RecipeCategory?
    @State private var selectedRecipe: FastingRecipe?
    @State private var showPaywall = false
    @State private var contentAppeared = false

    private var filteredRecipes: [FastingRecipe] {
        guard let category = selectedCategory else {
            return FastingRecipeData.recipes
        }
        return FastingRecipeData.recipes.filter { $0.category == category }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Category filter
                categoryFilter
                    .entranceAnimation(delay: 0.1)

                // Recipe grid
                recipeGrid
                    .entranceAnimation(delay: 0.2)
            }
            .padding(.top, 8)
            .opacity(contentAppeared ? 1 : 0)
        }
        .navigationTitle("Recipes")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedRecipe) { recipe in
            RecipeDetailView(recipe: recipe)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                contentAppeared = true
            }
        }
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // All category
                CategoryChip(
                    title: "All",
                    icon: "square.grid.2x2.fill",
                    isSelected: selectedCategory == nil,
                    accent: themeManager.selectedTheme.accent
                ) {
                    HapticManager.shared.selectionChanged()
                    withAnimation(.tapSpring) {
                        selectedCategory = nil
                    }
                }

                ForEach(FastingRecipe.RecipeCategory.allCases) { category in
                    CategoryChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category,
                        accent: themeManager.selectedTheme.accent
                    ) {
                        HapticManager.shared.selectionChanged()
                        withAnimation(.tapSpring) {
                            selectedCategory = (selectedCategory == category) ? nil : category
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Recipe Grid

    private var recipeGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(Array(filteredRecipes.enumerated()), id: \.element.id) { index, recipe in
                let isLocked = recipe.isPremium && !subscriptionManager.isSubscribed
                RecipeCard(recipe: recipe, isLocked: isLocked, accent: themeManager.selectedTheme.accent) {
                    if isLocked {
                        HapticManager.shared.warning()
                        showPaywall = true
                    } else {
                        HapticManager.shared.lightTap()
                        selectedRecipe = recipe
                    }
                }
                .staggeredAppear(index: index)
            }
        }
        .padding(.horizontal, 16)
        .animation(.smoothSpring, value: selectedCategory)
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? accent.opacity(0.18) : Color(.tertiarySystemBackground))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? accent.opacity(0.4) : Color.clear, lineWidth: 1)
            )
            .foregroundStyle(isSelected ? accent : .primary)
        }
        .buttonStyle(.bounce)
        .accessibilityLabel("\(title) category")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Recipe Card

private struct RecipeCard: View {
    let recipe: FastingRecipe
    let isLocked: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Emoji hero
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [accent.opacity(0.15), accent.opacity(0.03)],
                                center: .center,
                                startRadius: 4,
                                endRadius: 30
                            )
                        )
                        .frame(width: 56, height: 56)

                    Text(recipe.emoji)
                        .font(.system(size: 32))

                    if isLocked {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 56, height: 56)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                // Title
                Text(recipe.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(isLocked ? .secondary : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                // Badges
                HStack(spacing: 6) {
                    BadgePill(icon: "clock", text: "\(recipe.prepTime)m", color: .blue)
                    BadgePill(icon: "flame", text: "\(recipe.calories)", color: .orange)
                }

                // Protein
                HStack(spacing: 3) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.green)
                    Text("\(recipe.protein)g protein")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(.separator).opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            .shadow(color: accent.opacity(0.06), radius: 6, y: 2)
            .opacity(isLocked ? 0.65 : 1.0)
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.title), \(recipe.prepTime) minutes, \(recipe.calories) calories, \(recipe.protein) grams protein\(isLocked ? ", Premium, locked" : "")")
        .accessibilityHint(isLocked ? "Upgrade to Premium to view this recipe" : "Tap to view recipe details")
    }
}

// MARK: - Badge Pill

private struct BadgePill: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(color.opacity(0.08))
        )
    }
}

#Preview {
    NavigationStack {
        RecipesView()
    }
    .environment(SubscriptionManager())
    .environment(ThemeManager())
}
