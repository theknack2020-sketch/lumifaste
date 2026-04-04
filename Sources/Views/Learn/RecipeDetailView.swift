import SwiftUI

/// Full recipe detail — hero emoji, nutrition badges, ingredients with toggles, numbered steps, and log-this-meal CTA.
struct RecipeDetailView: View {
    let recipe: FastingRecipe
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    @State private var checkedIngredients: Set<String> = []
    @State private var showMealLog = false
    @State private var contentAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section
                    heroSection
                        .entranceAnimation(delay: 0.1)

                    // Description
                    descriptionSection
                        .entranceAnimation(delay: 0.15)

                    // Nutrition badges
                    nutritionBadges
                        .entranceAnimation(delay: 0.2)

                    // Ingredients
                    ingredientsSection
                        .entranceAnimation(delay: 0.25)

                    // Steps
                    stepsSection
                        .entranceAnimation(delay: 0.3)

                    // Log this meal
                    logMealButton
                        .entranceAnimation(delay: 0.35)
                }
                .padding(20)
                .opacity(contentAppeared ? 1 : 0)
            }
            .background(Color(.systemBackground))
            .navigationTitle(recipe.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Close")
                }
            }
            .sheet(isPresented: $showMealLog) {
                MealLogView(
                    prefillTitle: recipe.title,
                    prefillEmoji: recipe.emoji,
                    prefillMealType: recipe.category == .snack ? "Snack"
                        : recipe.category == .breakingFast ? "Breakfast"
                        : recipe.category == .drink ? "Snack"
                        : "Lunch"
                )
            }
            .onAppear {
                withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                    contentAppeared = true
                }
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        let accent = themeManager.selectedTheme.accent
        return VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accent.opacity(0.2), accent.opacity(0.04), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Text(recipe.emoji)
                    .font(.adaptiveDisplay(size: 72, weight: .regular, design: .default, isRegular: isRegular))
            }

            // Category pill
            HStack(spacing: 6) {
                Image(systemName: recipe.category.icon)
                    .font(.adaptiveBadge(isRegular: isRegular).weight(.semibold))
                Text(recipe.category.rawValue)
                    .font(.adaptiveCaption(isRegular: isRegular).weight(.semibold))
            }
            .foregroundStyle(accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(accent.opacity(0.1))
            )
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        Text(recipe.description)
            .font(.adaptiveSubheadline(isRegular: isRegular))
            .foregroundStyle(.secondary)
            .lineSpacing(4)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 8)
    }

    // MARK: - Nutrition Badges

    private var nutritionBadges: some View {
        HStack(spacing: 0) {
            NutritionBadge(icon: "clock.fill", value: "\(recipe.prepTime) min", label: "Prep", color: .blue)
            NutritionBadge(icon: "flame.fill", value: "\(recipe.calories)", label: "Calories", color: .orange)
            NutritionBadge(icon: "bolt.fill", value: "\(recipe.protein)g", label: "Protein", color: .green)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    // MARK: - Ingredients

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "basket.fill")
                    .font(.adaptiveDetail(isRegular: isRegular))
                    .foregroundStyle(themeManager.selectedTheme.accent)
                Text("Ingredients")
                    .font(.adaptiveSubheadline(isRegular: isRegular).weight(.bold))
            }

            VStack(spacing: 2) {
                ForEach(recipe.ingredients, id: \.self) { ingredient in
                    Button {
                        HapticManager.shared.lightTap()
                        withAnimation(.tapSpring) {
                            if checkedIngredients.contains(ingredient) {
                                checkedIngredients.remove(ingredient)
                            } else {
                                checkedIngredients.insert(ingredient)
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: checkedIngredients.contains(ingredient) ? "checkmark.circle.fill" : "circle")
                                .font(.adaptiveHeadline(isRegular: isRegular))
                                .foregroundStyle(checkedIngredients.contains(ingredient)
                                    ? themeManager.selectedTheme.accent
                                    : .secondary)
                                .contentTransition(.symbolEffect(.replace))

                            Text(ingredient)
                                .font(.adaptiveDetail(isRegular: isRegular))
                                .foregroundStyle(checkedIngredients.contains(ingredient) ? .secondary : .primary)
                                .strikethrough(checkedIngredients.contains(ingredient), color: .secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(ingredient)\(checkedIngredients.contains(ingredient) ? ", checked" : "")")
                    .accessibilityAddTraits(checkedIngredients.contains(ingredient) ? .isSelected : [])
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.tertiarySystemBackground))
            )
        }
    }

    // MARK: - Steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "list.number")
                    .font(.adaptiveDetail(isRegular: isRegular))
                    .foregroundStyle(themeManager.selectedTheme.accent)
                Text("Steps")
                    .font(.adaptiveSubheadline(isRegular: isRegular).weight(.bold))
            }

            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        // Step number
                        ZStack {
                            Circle()
                                .fill(themeManager.selectedTheme.accent.opacity(0.12))
                                .frame(width: 28, height: 28)
                            Text("\(index + 1)")
                                .font(.adaptiveDetail(isRegular: isRegular).weight(.bold))
                                .foregroundStyle(themeManager.selectedTheme.accent)
                        }

                        Text(step)
                            .font(.adaptiveDetail(isRegular: isRegular))
                            .foregroundStyle(.primary.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(3)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.tertiarySystemBackground))
            )
        }
    }

    // MARK: - Log This Meal

    private var logMealButton: some View {
        Button {
            HapticManager.shared.mediumTap()
            showMealLog = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))
                Text("Log This Meal")
                    .font(.adaptiveBody(isRegular: isRegular).weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(themeManager.selectedTheme.accentGradient)
            )
            .shadow(color: themeManager.selectedTheme.accent.opacity(0.4), radius: 16, y: 6)
            .shadow(color: themeManager.selectedTheme.accent.opacity(0.2), radius: 6, y: 2)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("Log this meal")
        .accessibilityHint("Opens meal log pre-filled with this recipe")
    }
}

// MARK: - Nutrition Badge

private struct NutritionBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.adaptiveSubheadline(isRegular: isRegular))
                .foregroundStyle(color)
            Text(value)
                .font(.adaptiveSubheadline(isRegular: isRegular).weight(.bold))
                .monospacedDigit()
            Text(label)
                .font(.adaptiveBadge(isRegular: isRegular))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview {
    RecipeDetailView(recipe: FastingRecipeData.recipes[0])
        .environment(ThemeManager())
}
