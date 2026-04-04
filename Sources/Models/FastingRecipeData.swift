import Foundation

/// 20 fasting-friendly recipes — static data.
/// First 10 are free, last 10 are premium.
enum FastingRecipeData {
    static let recipes: [FastingRecipe] = breakingFastRecipes + mainMealRecipes + snackRecipes + drinkRecipes

    // MARK: - Breaking Fast (5)

    private static let breakingFastRecipes: [FastingRecipe] = [
        FastingRecipe(
            title: "Bone Broth",
            emoji: "🍲",
            category: .breakingFast,
            prepTime: 5,
            calories: 45,
            protein: 9,
            description: "Warm, mineral-rich bone broth is the gentlest way to break a fast. It soothes the stomach, provides electrolytes, and eases digestion back into action.",
            ingredients: [
                "2 cups bone broth (chicken or beef)",
                "1/4 tsp sea salt",
                "1/4 tsp turmeric",
                "Pinch of black pepper",
                "Fresh parsley for garnish",
            ],
            steps: [
                "Heat bone broth in a small pot over medium heat until it begins to steam.",
                "Stir in sea salt, turmeric, and a pinch of black pepper.",
                "Pour into a mug and garnish with fresh parsley.",
            ],
            isPremium: false
        ),
        FastingRecipe(
            title: "Avocado Toast",
            emoji: "🥑",
            category: .breakingFast,
            prepTime: 8,
            calories: 320,
            protein: 10,
            description: "Creamy avocado on whole-grain toast provides healthy fats and fiber to gently wake up your digestive system. A satisfying first meal after a fast.",
            ingredients: [
                "1 slice whole-grain sourdough bread",
                "1/2 ripe avocado",
                "1/2 lemon, juiced",
                "Red pepper flakes",
                "Sea salt and black pepper",
                "1 tbsp hemp seeds",
            ],
            steps: [
                "Toast the sourdough until golden brown and crisp.",
                "Mash the avocado with lemon juice, salt, and pepper in a small bowl.",
                "Spread the mashed avocado onto the toast.",
                "Sprinkle with red pepper flakes and hemp seeds.",
            ],
            isPremium: false
        ),
        FastingRecipe(
            title: "Greek Yogurt Bowl",
            emoji: "🫐",
            category: .breakingFast,
            prepTime: 5,
            calories: 280,
            protein: 20,
            description: "Protein-packed Greek yogurt topped with berries and a drizzle of honey. The probiotics help restore gut activity after a fast.",
            ingredients: [
                "1 cup plain Greek yogurt (full-fat)",
                "1/4 cup mixed berries",
                "1 tbsp raw honey",
                "2 tbsp granola",
                "1 tbsp chia seeds",
            ],
            steps: [
                "Spoon Greek yogurt into a bowl.",
                "Arrange berries and granola on top.",
                "Drizzle with honey and sprinkle chia seeds.",
            ],
            isPremium: false
        ),
        FastingRecipe(
            title: "Scrambled Eggs",
            emoji: "🥚",
            category: .breakingFast,
            prepTime: 10,
            calories: 250,
            protein: 18,
            description: "Soft scrambled eggs cooked low and slow deliver high-quality protein without overwhelming your stomach. Perfect first solid meal.",
            ingredients: [
                "3 large eggs",
                "1 tbsp butter",
                "2 tbsp milk or cream",
                "Salt and pepper",
                "Fresh chives, chopped",
                "1 slice whole-grain toast (optional)",
            ],
            steps: [
                "Whisk eggs with milk, salt, and pepper in a bowl.",
                "Melt butter in a non-stick pan over low heat.",
                "Pour in the egg mixture and stir gently with a spatula, folding softly as curds form.",
                "Remove from heat while still slightly wet — residual heat will finish cooking.",
                "Garnish with chives and serve with toast.",
            ],
            isPremium: false
        ),
        FastingRecipe(
            title: "Smoothie Bowl",
            emoji: "🥣",
            category: .breakingFast,
            prepTime: 7,
            calories: 310,
            protein: 15,
            description: "A thick, blended bowl of frozen fruit, protein, and healthy fats. Easy to digest and packed with nutrients to replenish after fasting.",
            ingredients: [
                "1 frozen banana",
                "1/2 cup frozen mixed berries",
                "1 scoop protein powder (vanilla)",
                "1/2 cup almond milk",
                "1 tbsp almond butter",
                "Toppings: sliced banana, coconut flakes, granola",
            ],
            steps: [
                "Blend frozen banana, berries, protein powder, and almond milk until thick and smooth.",
                "Pour into a bowl — it should be thicker than a regular smoothie.",
                "Top with sliced banana, coconut flakes, granola, and a drizzle of almond butter.",
            ],
            isPremium: false
        ),
    ]

    // MARK: - Main Meal (6)

    private static let mainMealRecipes: [FastingRecipe] = [
        FastingRecipe(
            title: "Grilled Chicken Salad",
            emoji: "🥗",
            category: .meal,
            prepTime: 20,
            calories: 420,
            protein: 38,
            description: "Lean grilled chicken breast on a bed of mixed greens with a lemon vinaigrette. High protein, low carb, and deeply satisfying.",
            ingredients: [
                "150g chicken breast",
                "4 cups mixed greens",
                "1/2 avocado, sliced",
                "1/4 cup cherry tomatoes",
                "2 tbsp olive oil",
                "1 lemon, juiced",
                "Salt, pepper, garlic powder",
            ],
            steps: [
                "Season chicken with salt, pepper, and garlic powder. Grill over medium-high heat for 6 minutes per side.",
                "Let chicken rest 5 minutes, then slice.",
                "Toss greens with olive oil and lemon juice.",
                "Top with sliced chicken, avocado, and cherry tomatoes.",
            ],
            isPremium: false
        ),
        FastingRecipe(
            title: "Salmon with Roasted Veggies",
            emoji: "🐟",
            category: .meal,
            prepTime: 25,
            calories: 480,
            protein: 35,
            description: "Omega-3-rich salmon paired with roasted seasonal vegetables. A nutrient-dense meal that supports recovery after extended fasts.",
            ingredients: [
                "150g salmon fillet",
                "1 cup broccoli florets",
                "1/2 cup sweet potato, cubed",
                "1 tbsp olive oil",
                "1/2 lemon",
                "Fresh dill",
                "Salt and pepper",
            ],
            steps: [
                "Preheat oven to 400°F (200°C). Toss broccoli and sweet potato with olive oil, salt, and pepper on a sheet pan.",
                "Place salmon fillet alongside the vegetables. Squeeze lemon over the salmon.",
                "Roast for 18-20 minutes until salmon flakes easily.",
                "Garnish with fresh dill and serve.",
            ],
            isPremium: false
        ),
        FastingRecipe(
            title: "Turkey Lettuce Wraps",
            emoji: "🌮",
            category: .meal,
            prepTime: 15,
            calories: 350,
            protein: 30,
            description: "Light, fresh, and protein-packed. Ground turkey in crisp lettuce cups with Asian-inspired seasoning — low carb and delicious.",
            ingredients: [
                "200g ground turkey",
                "1 tbsp sesame oil",
                "2 tbsp soy sauce (or coconut aminos)",
                "1 tsp fresh ginger, minced",
                "1 clove garlic, minced",
                "Butter lettuce leaves",
                "Shredded carrot and cucumber for topping",
            ],
            steps: [
                "Heat sesame oil in a skillet over medium-high heat.",
                "Add garlic and ginger, sauté for 30 seconds until fragrant.",
                "Add ground turkey and cook until browned, breaking it apart.",
                "Stir in soy sauce and cook 1 more minute.",
                "Spoon the mixture into lettuce cups and top with carrot and cucumber.",
            ],
            isPremium: false
        ),
        FastingRecipe(
            title: "Quinoa Buddha Bowl",
            emoji: "🍛",
            category: .meal,
            prepTime: 25,
            calories: 450,
            protein: 22,
            description: "A colorful bowl of quinoa, roasted chickpeas, greens, and tahini dressing. Complete plant-based protein for sustained energy.",
            ingredients: [
                "1/2 cup cooked quinoa",
                "1/2 cup canned chickpeas, drained",
                "1 cup baby spinach",
                "1/4 avocado, sliced",
                "1/4 cup shredded red cabbage",
                "2 tbsp tahini",
                "1 tbsp lemon juice",
                "Olive oil, salt, paprika",
            ],
            steps: [
                "Toss chickpeas with olive oil, salt, and paprika. Roast at 400°F for 20 minutes until crispy.",
                "Arrange quinoa, spinach, cabbage, and avocado in a bowl.",
                "Top with roasted chickpeas.",
                "Mix tahini with lemon juice and a splash of water. Drizzle over the bowl.",
            ],
            isPremium: true
        ),
        FastingRecipe(
            title: "Veggie Stir-Fry",
            emoji: "🥦",
            category: .meal,
            prepTime: 15,
            calories: 380,
            protein: 25,
            description: "A quick wok-tossed medley of colorful vegetables and tofu or shrimp. High in fiber and micronutrients with a savory garlic-ginger sauce.",
            ingredients: [
                "150g tofu or shrimp",
                "1 cup broccoli florets",
                "1/2 bell pepper, sliced",
                "1/2 cup snap peas",
                "2 tbsp soy sauce",
                "1 tbsp sesame oil",
                "1 clove garlic, minced",
                "1 tsp fresh ginger, minced",
            ],
            steps: [
                "Press tofu and cut into cubes (or clean shrimp). Heat sesame oil in a wok over high heat.",
                "Stir-fry protein until golden, about 3-4 minutes. Set aside.",
                "Add garlic, ginger, and all vegetables to the wok. Stir-fry for 3 minutes.",
                "Return protein to wok, add soy sauce, and toss everything together for 1 minute.",
            ],
            isPremium: true
        ),
        FastingRecipe(
            title: "Red Lentil Soup",
            emoji: "🥣",
            category: .meal,
            prepTime: 30,
            calories: 320,
            protein: 18,
            description: "A warming, creamy lentil soup packed with plant-based protein and fiber. Perfect comfort food that's gentle on the stomach after fasting.",
            ingredients: [
                "1 cup red lentils, rinsed",
                "1 small onion, diced",
                "2 cloves garlic, minced",
                "1 tsp cumin",
                "1/2 tsp turmeric",
                "3 cups vegetable broth",
                "1 tbsp olive oil",
                "Lemon juice and cilantro for serving",
            ],
            steps: [
                "Heat olive oil in a pot. Sauté onion until soft, then add garlic, cumin, and turmeric.",
                "Add lentils and vegetable broth. Bring to a boil.",
                "Reduce heat and simmer for 20 minutes until lentils are completely soft.",
                "Blend partially for a creamy texture. Serve with a squeeze of lemon and fresh cilantro.",
            ],
            isPremium: true
        ),
    ]

    // MARK: - Snack (5)

    private static let snackRecipes: [FastingRecipe] = [
        FastingRecipe(
            title: "Almonds & Dark Chocolate",
            emoji: "🍫",
            category: .snack,
            prepTime: 2,
            calories: 210,
            protein: 6,
            description: "A handful of raw almonds paired with a few squares of dark chocolate. Healthy fats and antioxidants in one satisfying snack.",
            ingredients: [
                "1/4 cup raw almonds (about 23)",
                "20g dark chocolate (70%+ cacao)",
                "Pinch of sea salt (optional)",
            ],
            steps: [
                "Portion almonds and dark chocolate onto a small plate.",
                "Sprinkle with sea salt if desired.",
                "Enjoy slowly — let the chocolate melt on your tongue.",
            ],
            isPremium: true
        ),
        FastingRecipe(
            title: "Hummus & Veggie Sticks",
            emoji: "🥕",
            category: .snack,
            prepTime: 5,
            calories: 180,
            protein: 7,
            description: "Creamy hummus with crunchy vegetable sticks. A fiber-rich, protein-packed snack that keeps you full without the carb crash.",
            ingredients: [
                "1/4 cup hummus",
                "1 carrot, cut into sticks",
                "1/2 cucumber, cut into sticks",
                "1/2 bell pepper, sliced",
                "Paprika for garnish",
            ],
            steps: [
                "Arrange vegetable sticks on a plate.",
                "Spoon hummus into a small bowl.",
                "Dust with paprika and serve.",
            ],
            isPremium: true
        ),
        FastingRecipe(
            title: "Apple & Peanut Butter",
            emoji: "🍎",
            category: .snack,
            prepTime: 3,
            calories: 250,
            protein: 8,
            description: "Classic combination of crisp apple slices and natural peanut butter. The fiber and healthy fats create lasting satiety.",
            ingredients: [
                "1 medium apple, sliced",
                "2 tbsp natural peanut butter",
                "Cinnamon (optional)",
            ],
            steps: [
                "Slice the apple into wedges.",
                "Serve with peanut butter for dipping.",
                "Dust with cinnamon for extra flavor.",
            ],
            isPremium: true
        ),
        FastingRecipe(
            title: "Boiled Eggs",
            emoji: "🥚",
            category: .snack,
            prepTime: 12,
            calories: 140,
            protein: 12,
            description: "Two perfectly boiled eggs are the ultimate portable protein snack. Quick, satisfying, and packed with essential amino acids.",
            ingredients: [
                "2 large eggs",
                "Salt and pepper",
                "Everything bagel seasoning (optional)",
            ],
            steps: [
                "Place eggs in a pot and cover with cold water by 1 inch.",
                "Bring to a boil, then cover and remove from heat. Let sit 10 minutes for hard-boiled.",
                "Transfer to ice water for 2 minutes, then peel.",
                "Season with salt, pepper, or everything bagel seasoning.",
            ],
            isPremium: true
        ),
        FastingRecipe(
            title: "Cheese & Berry Plate",
            emoji: "🧀",
            category: .snack,
            prepTime: 3,
            calories: 220,
            protein: 14,
            description: "A mini cheese board with fresh berries. The protein from cheese combined with antioxidant-rich berries makes a premium snack.",
            ingredients: [
                "40g aged cheddar or gouda",
                "1/4 cup mixed berries",
                "5 walnuts",
                "1 tsp honey (optional)",
            ],
            steps: [
                "Slice cheese into small pieces.",
                "Arrange cheese, berries, and walnuts on a small plate.",
                "Drizzle with honey if desired.",
            ],
            isPremium: true
        ),
    ]

    // MARK: - Drink (4)

    private static let drinkRecipes: [FastingRecipe] = [
        FastingRecipe(
            title: "Green Tea",
            emoji: "🍵",
            category: .drink,
            prepTime: 4,
            calories: 2,
            protein: 0,
            description: "Rich in antioxidants and L-theanine for calm focus. Green tea can support autophagy and is safe to consume during fasting windows.",
            ingredients: [
                "1 green tea bag or 1 tsp loose-leaf green tea",
                "1 cup hot water (175°F / 80°C — not boiling)",
                "Fresh mint leaves (optional)",
            ],
            steps: [
                "Heat water to 175°F (80°C) — below boiling to avoid bitterness.",
                "Steep the tea for 2-3 minutes. Do not over-steep.",
                "Remove the tea bag and add mint leaves if desired.",
            ],
            isPremium: false
        ),
        FastingRecipe(
            title: "Black Coffee",
            emoji: "☕",
            category: .drink,
            prepTime: 5,
            calories: 5,
            protein: 0,
            description: "Pure black coffee boosts metabolism and mental clarity during fasting. No cream, sugar, or sweeteners — just the bean.",
            ingredients: [
                "2 tbsp freshly ground coffee beans",
                "1 cup filtered water",
                "Pinch of cinnamon (optional, won't break fast)",
            ],
            steps: [
                "Brew coffee using your preferred method (pour-over, French press, or drip).",
                "Serve black — no milk, cream, or sweeteners.",
                "Add a pinch of cinnamon for flavor variety.",
            ],
            isPremium: false
        ),
        FastingRecipe(
            title: "Warm Bone Broth",
            emoji: "🫕",
            category: .drink,
            prepTime: 5,
            calories: 40,
            protein: 8,
            description: "A savory, mineral-rich sip during extended fasts. Technically breaks a strict fast but provides electrolytes to keep you going.",
            ingredients: [
                "1 cup bone broth (beef or chicken)",
                "1/4 tsp Himalayan salt",
                "Squeeze of lemon",
            ],
            steps: [
                "Heat bone broth in a small pot or microwave until steaming.",
                "Stir in salt and a squeeze of lemon.",
                "Sip slowly like tea.",
            ],
            isPremium: false
        ),
        FastingRecipe(
            title: "Lemon Water",
            emoji: "🍋",
            category: .drink,
            prepTime: 2,
            calories: 5,
            protein: 0,
            description: "Simple, refreshing, and nearly zero-calorie. Lemon water aids digestion, provides vitamin C, and won't break your fast.",
            ingredients: [
                "1 cup cold or warm water",
                "Juice of 1/2 lemon",
                "Fresh mint sprig (optional)",
                "Ice cubes (for cold version)",
            ],
            steps: [
                "Squeeze fresh lemon juice into a glass of water.",
                "Add mint and ice for a refreshing cold version, or use warm water for a soothing start.",
                "Drink first thing in the morning or throughout your fast.",
            ],
            isPremium: false
        ),
    ]
}
