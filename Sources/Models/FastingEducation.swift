import Foundation
import SwiftUI

// MARK: - Fasting Education Content

/// Central repository for all educational content in the app.
/// All health claims include scientific references.
/// Content is educational only — not medical advice (K004 disclaimer).
enum FastingEducation {
    // MARK: - Stage Science (detailed body info per stage)

    struct StageDetail: Identifiable {
        let id: String
        let stage: FastingStage
        let headline: String
        let bodyText: String
        let metabolicInfo: String
        let whatHappens: [String]
        let tips: [String]
        let reference: String
    }

    static let stageDetails: [StageDetail] = [
        StageDetail(
            id: "fed",
            stage: .fed,
            headline: "Digestion & Absorption",
            bodyText: "Your body is actively digesting food and absorbing nutrients. Blood sugar and insulin levels are elevated as your body processes the meal. Energy is readily available from glucose.",
            metabolicInfo: "Primary fuel: glucose from food. Insulin is elevated, signaling cells to absorb sugar. Excess glucose is stored as glycogen in liver and muscles, or converted to fat.",
            whatHappens: [
                "Stomach breaks down food mechanically and chemically",
                "Nutrients absorbed through small intestine into bloodstream",
                "Pancreas releases insulin to manage blood sugar",
                "Liver stores excess glucose as glycogen",
                "Body is in anabolic (building) mode",
            ],
            tips: [
                "Use this time to plan your next fast",
                "Eat nutrient-dense foods to prepare your body",
                "Avoid processed sugars that cause rapid insulin spikes",
            ],
            reference: "Anton SD, et al. Flipping the Metabolic Switch. Obesity. 2018;26(2):254-268."
        ),
        StageDetail(
            id: "earlyFasting",
            stage: .earlyFasting,
            headline: "Blood Sugar Stabilizing",
            bodyText: "Your body has finished digesting and begins using stored glycogen for energy. Blood sugar and insulin levels are dropping. You may start to feel mild hunger as ghrelin (the hunger hormone) peaks.",
            metabolicInfo: "Primary fuel: liver glycogen → glucose. Insulin is falling, allowing stored energy to become accessible. Blood sugar stabilizes to a healthy baseline.",
            whatHappens: [
                "Liver glycogen is converted back to glucose (glycogenolysis)",
                "Blood sugar gradually decreases to baseline",
                "Insulin levels drop significantly",
                "Ghrelin (hunger hormone) may peak then subside",
                "Body begins transitioning from fed to fasted state",
            ],
            tips: [
                "Hunger peaks are temporary — they pass in 15-20 minutes",
                "Drink water or black coffee to ease the transition",
                "Stay busy — distraction is your best tool right now",
            ],
            reference: "Patterson RE, Sears DD. Metabolic Effects of Intermittent Fasting. Annu Rev Nutr. 2017;37:371-393."
        ),
        StageDetail(
            id: "fatBurning",
            stage: .fatBurning,
            headline: "Fat Mobilization Begins",
            bodyText: "With glycogen stores depleted, your body shifts to burning fat for fuel. This metabolic switch is a key benefit of intermittent fasting. Fatty acids are released from fat cells and transported to the liver.",
            metabolicInfo: "Primary fuel: fatty acids from adipose tissue. Lipolysis accelerates — fat cells release stored triglycerides. The liver begins converting fatty acids into energy. You are now burning body fat.",
            whatHappens: [
                "Glycogen stores become depleted",
                "Fat cells release stored fatty acids (lipolysis)",
                "Liver converts fatty acids to energy",
                "Metabolic rate may increase slightly due to norepinephrine",
                "Growth hormone levels begin to rise",
                "Inflammation markers start to decrease",
            ],
            tips: [
                "Light exercise now can enhance fat burning",
                "This is when real metabolic benefits begin",
                "Stay hydrated — fat metabolism requires water",
            ],
            reference: "Mattson MP, Longo VD, Harvie M. Impact of intermittent fasting on health and disease processes. Ageing Res Rev. 2017;39:46-58."
        ),
        StageDetail(
            id: "ketosis",
            stage: .ketosis,
            headline: "Ketone Production",
            bodyText: "Your liver is now producing ketone bodies — an efficient alternative fuel. Your brain and muscles adapt to using ketones, which many people experience as heightened mental clarity and stable energy.",
            metabolicInfo: "Primary fuel: ketone bodies (beta-hydroxybutyrate, acetoacetate). The brain shifts to using ketones for up to 75% of its energy needs. Fat burning is now your dominant metabolic pathway.",
            whatHappens: [
                "Liver produces ketone bodies from fatty acids",
                "Brain begins using ketones for fuel (cleaner energy)",
                "Mental clarity often improves noticeably",
                "Growth hormone surges (up to 5x normal levels)",
                "Cellular stress resistance pathways activate",
                "BDNF (brain-derived neurotrophic factor) increases",
            ],
            tips: [
                "Many people feel a burst of clarity and focus here",
                "Electrolytes become more important — consider salt water",
                "This is an excellent time for focused mental work",
            ],
            reference: "Cahill GF Jr. Fuel metabolism in starvation. Annu Rev Nutr. 2006;26:1-22."
        ),
        StageDetail(
            id: "autophagy",
            stage: .autophagy,
            headline: "Cellular Renewal",
            bodyText: "Autophagy — your body's cellular cleanup system — is now highly active. Damaged proteins and organelles are broken down and recycled. This process is linked to longevity, cancer prevention, and neuroprotection.",
            metabolicInfo: "Primary fuel: ketones and fatty acids. Autophagy is at peak activity — cells are recycling damaged components. Stem cell regeneration pathways may activate. This is the deepest level of cellular renewal.",
            whatHappens: [
                "Autophagy ramps up — damaged cells are recycled",
                "Misfolded proteins are cleared from cells",
                "Mitochondria undergo renewal (mitophagy)",
                "Immune system cells may be regenerated",
                "Anti-aging pathways (AMPK, sirtuins) are fully active",
                "Inflammation reaches its lowest point",
            ],
            tips: [
                "You've achieved deep cellular benefits",
                "Plan your fast-breaking meal carefully — go gentle",
                "Consider bone broth or light soup to break this fast",
            ],
            reference: "Bagherniya M, et al. The effect of fasting or calorie restriction on autophagy induction. Ageing Res Rev. 2018;47:183-197."
        ),
    ]

    static func detail(for stage: FastingStage) -> StageDetail? {
        stageDetails.first { $0.stage == stage }
    }

    // MARK: - FAQ

    struct FAQ: Identifiable {
        let id: Int
        let question: String
        let answer: String
        let category: String
    }

    static let faqs: [FAQ] = [
        FAQ(id: 1, question: "Is intermittent fasting safe?",
            answer: "For most healthy adults, intermittent fasting is considered safe. However, it's not recommended for pregnant or breastfeeding women, children, people with eating disorders, or those with certain medical conditions. Always consult your doctor before starting any fasting program.",
            category: "Safety"),
        FAQ(id: 2, question: "Will I lose muscle while fasting?",
            answer: "Short-term intermittent fasting (16-24 hours) preserves muscle mass well, especially when combined with resistance training and adequate protein during eating windows. Growth hormone increases during fasting actually help protect muscle.",
            category: "Body"),
        FAQ(id: 3, question: "What can I drink during a fast?",
            answer: "Water, black coffee, plain tea (green, black, herbal), and sparkling water are generally fine. Avoid anything with calories, sugar, or artificial sweeteners, as they can trigger an insulin response and break your fast.",
            category: "Rules"),
        FAQ(id: 4, question: "Does black coffee break a fast?",
            answer: "Black coffee (no sugar, cream, or milk) does not break a fast. It contains negligible calories and can actually enhance autophagy and fat burning. Limit to 3-4 cups to avoid excess cortisol.",
            category: "Rules"),
        FAQ(id: 5, question: "Why do I feel hungry at the same time every day?",
            answer: "Ghrelin, the hunger hormone, follows your eating schedule. If you normally eat at noon, ghrelin spikes at noon. After 2-3 weeks of consistent fasting, ghrelin adapts to your new schedule and hunger at the old times fades.",
            category: "Body"),
        FAQ(id: 6, question: "What's the best fasting schedule for beginners?",
            answer: "Start with 12:12 or 14:10. These are gentle enough that most people can do them without discomfort. Once comfortable (usually 1-2 weeks), gradually extend to 16:8. Don't jump straight to extended fasts.",
            category: "Getting Started"),
        FAQ(id: 7, question: "Can I exercise while fasting?",
            answer: "Yes, moderate exercise is safe during fasting for most people. Walking, yoga, and light cardio work well. For intense workouts, consider timing them near the end of your fast or during your eating window.",
            category: "Exercise"),
        FAQ(id: 8, question: "What should I eat to break my fast?",
            answer: "Start with easily digestible foods: bone broth, soup, eggs, avocado, or a small portion of protein with vegetables. Avoid large meals, processed foods, or high-sugar items immediately after fasting.",
            category: "Nutrition"),
        FAQ(id: 9, question: "Will fasting slow down my metabolism?",
            answer: "Short-term fasting (up to 48 hours) actually increases metabolic rate by 3.6-14% due to norepinephrine release. Prolonged calorie restriction (weeks) can slow metabolism, but intermittent fasting avoids this by alternating fasting and eating.",
            category: "Body"),
        FAQ(id: 10, question: "Is it normal to feel cold while fasting?",
            answer: "Yes, feeling slightly cold during a fast is normal. Blood flow is redirected to vital organs and away from extremities. This is temporary and resolves when you eat. Dress warmly and drink warm (calorie-free) beverages.",
            category: "Body"),
        FAQ(id: 11, question: "Can I take medications during a fast?",
            answer: "This depends on the medication. Some must be taken with food. Never skip prescribed medications for a fast — always consult your doctor about how to manage medications around your fasting schedule.",
            category: "Safety"),
        FAQ(id: 12, question: "What is autophagy and why does it matter?",
            answer: "Autophagy is your body's cellular recycling system. It breaks down and removes damaged proteins, organelles, and pathogens. Enhanced autophagy is linked to reduced cancer risk, neuroprotection, and longevity. It increases significantly after 18-24 hours of fasting.",
            category: "Science"),
        FAQ(id: 13, question: "How long does it take to see results?",
            answer: "Most people notice improved energy and mental clarity within the first week. Weight changes typically appear after 2-4 weeks of consistent fasting. Metabolic improvements (insulin sensitivity, inflammation markers) may take 4-8 weeks.",
            category: "Getting Started"),
        FAQ(id: 14, question: "Can I fast every day?",
            answer: "Daily 16:8 or 18:6 fasting is practiced safely by millions of people. However, extended fasts (24+ hours) should not be done daily. Listen to your body and take breaks if you feel fatigued or unwell.",
            category: "Rules"),
        FAQ(id: 15, question: "Does fasting affect sleep?",
            answer: "It can, both positively and negatively. Many people sleep better because digestion isn't competing with rest. Some initially experience lighter sleep. Stopping eating 3+ hours before bed and maintaining consistent fasting times helps optimize sleep.",
            category: "Body"),
        FAQ(id: 16, question: "What's the difference between fasting and starving?",
            answer: "Fasting is a controlled, voluntary choice with a planned duration and adequate nutrition during eating windows. Starvation is involuntary and leads to nutrient deficiency. Your body has ample stored energy (fat) to safely fuel short-term fasts.",
            category: "Getting Started"),
        FAQ(id: 17, question: "Should I count calories during my eating window?",
            answer: "It's not strictly necessary for most people. Focus on eating nutrient-dense whole foods until satisfied. If weight loss stalls, you may benefit from tracking briefly to identify if you're over-compensating during eating windows.",
            category: "Nutrition"),
    ]

    static var faqCategories: [String] {
        Array(Set(faqs.map(\.category))).sorted()
    }

    static func faqs(for category: String) -> [FAQ] {
        faqs.filter { $0.category == category }
    }

    // MARK: - Beginner's Guide

    struct GuideSection: Identifiable {
        let id: Int
        let title: String
        let icon: String
        let content: String
        let keyPoints: [String]
    }

    static let beginnersGuide: [GuideSection] = [
        GuideSection(
            id: 1,
            title: "What is Intermittent Fasting?",
            icon: "questionmark.circle.fill",
            content: "Intermittent fasting (IF) is an eating pattern that cycles between periods of fasting and eating. It doesn't specify which foods to eat, but rather when you eat them. It's not a diet — it's a lifestyle pattern.",
            keyPoints: [
                "Focus on when you eat, not what you eat",
                "Alternate between eating and fasting windows",
                "Your body is designed to handle periods without food",
                "Humans have fasted throughout evolution",
            ]
        ),
        GuideSection(
            id: 2,
            title: "How to Start",
            icon: "play.circle.fill",
            content: "Start with a comfortable schedule and gradually extend. Most beginners succeed by simply pushing breakfast back by 1-2 hours and stopping eating earlier in the evening.",
            keyPoints: [
                "Begin with 12:12 — fast for 12 hours, eat for 12",
                "Sleep counts as fasting time (you're already doing 8 hours)",
                "Push breakfast back by 1 hour each week",
                "Within 2-3 weeks, aim for 16:8",
                "Consistency matters more than duration",
            ]
        ),
        GuideSection(
            id: 3,
            title: "What to Expect",
            icon: "chart.line.uptrend.xyaxis",
            content: "The first few days may feel challenging as your body adjusts. Hunger peaks typically subside within 15-20 minutes. By the end of the first week, most people feel noticeably better.",
            keyPoints: [
                "Days 1-3: Hunger may feel strong but passes quickly",
                "Days 4-7: Body adapts, hunger becomes manageable",
                "Week 2: Energy and focus often improve",
                "Week 3-4: Fasting feels natural and routine",
                "Month 2+: Full metabolic benefits develop",
            ]
        ),
        GuideSection(
            id: 4,
            title: "Choosing Your Plan",
            icon: "slider.horizontal.3",
            content: "Different fasting schedules suit different lifestyles. There's no single best plan — the best plan is the one you can stick to consistently.",
            keyPoints: [
                "12:12 — Gentlest entry, great for beginners",
                "14:10 — Slightly more challenging, good fat burning",
                "16:8 — Most popular, strong research support",
                "18:6 — Intermediate, enters ketosis territory",
                "20:4/OMAD — Advanced, maximum autophagy benefits",
            ]
        ),
        GuideSection(
            id: 5,
            title: "Common Mistakes",
            icon: "exclamationmark.triangle.fill",
            content: "Avoiding these common pitfalls will make your fasting journey much smoother and more sustainable.",
            keyPoints: [
                "Don't overeat during your eating window",
                "Don't skip hydration — drink water throughout",
                "Don't start with extreme fasts (20:4 or OMAD)",
                "Don't ignore hunger signals that feel wrong",
                "Don't use fasting to compensate for binge eating",
                "Don't forget electrolytes during longer fasts",
            ]
        ),
        GuideSection(
            id: 6,
            title: "When NOT to Fast",
            icon: "hand.raised.fill",
            content: "Fasting is not appropriate for everyone. Please consult a healthcare provider if any of these apply to you.",
            keyPoints: [
                "Pregnant or breastfeeding",
                "Under 18 years old",
                "History of eating disorders",
                "Type 1 diabetes or insulin-dependent",
                "Taking medications that require food",
                "BMI below 18.5 (underweight)",
                "Recovering from surgery or illness",
            ]
        ),
    ]

    // MARK: - Learn Articles

    struct Article: Identifiable {
        let id: Int
        let title: String
        let subtitle: String
        let icon: String
        let iconColor: Color
        let sections: [ArticleSection]
        let references: [String]
        let isPremium: Bool
    }

    struct ArticleSection: Identifiable {
        let id = UUID()
        let heading: String
        let body: String
    }

    static let articles: [Article] = [
        Article(
            id: 1,
            title: "The Science of Fasting",
            subtitle: "How your body adapts to periods without food",
            icon: "atom",
            iconColor: .purple,
            sections: [
                ArticleSection(heading: "Metabolic Switch", body: "When you fast, your body undergoes a metabolic switch from using glucose as its primary fuel source to using fatty acids and ketone bodies. This typically occurs 12-36 hours after your last meal, depending on activity level and glycogen stores."),
                ArticleSection(heading: "Hormonal Changes", body: "Fasting triggers significant hormonal changes. Insulin drops, enabling fat mobilization. Human growth hormone increases up to 5-fold, preserving muscle mass. Norepinephrine is released, increasing metabolic rate and alertness."),
                ArticleSection(heading: "Cellular Benefits", body: "At the cellular level, fasting activates autophagy — the body's cleanup mechanism. Damaged proteins and organelles are identified, broken down, and recycled. This process is crucial for cellular health and is linked to longevity."),
            ],
            references: [
                "de Cabo R, Mattson MP. Effects of Intermittent Fasting on Health, Aging, and Disease. N Engl J Med. 2019;381(26):2541-2551.",
                "Longo VD, Mattson MP. Fasting: Molecular Mechanisms and Clinical Applications. Cell Metab. 2014;19(2):181-192.",
            ],
            isPremium: false
        ),
        Article(
            id: 2,
            title: "Weight Loss & Fat Burning",
            subtitle: "Why fasting is effective for body composition",
            icon: "flame.fill",
            iconColor: .orange,
            sections: [
                ArticleSection(heading: "Caloric Reduction", body: "Intermittent fasting naturally reduces caloric intake by limiting the eating window. Studies show IF participants consume 10-25% fewer calories without consciously counting or restricting."),
                ArticleSection(heading: "Fat Oxidation", body: "During fasting, low insulin levels allow your body to access stored fat. The rate of fat oxidation (fat burning) increases significantly after 12-16 hours without food. This is the primary mechanism behind fasting-related weight loss."),
                ArticleSection(heading: "Preserving Muscle", body: "Unlike continuous calorie restriction, intermittent fasting helps preserve lean muscle mass. The spike in growth hormone during fasting protects muscle tissue while the body preferentially burns fat for fuel."),
            ],
            references: [
                "Varady KA. Intermittent versus daily calorie restriction: which diet regimen is more effective for weight loss? Obes Rev. 2011;12(7):e593-601.",
                "Heilbronn LK, et al. Alternate-day fasting in nonobese subjects: effects on body weight, body composition, and energy metabolism. Am J Clin Nutr. 2005;81(1):69-73.",
            ],
            isPremium: false
        ),
        Article(
            id: 3,
            title: "Brain Health & Mental Clarity",
            subtitle: "Cognitive benefits of intermittent fasting",
            icon: "brain.head.profile",
            iconColor: .blue,
            sections: [
                ArticleSection(heading: "Ketones: Premium Brain Fuel", body: "When fasting produces ketones, the brain gains access to an efficient fuel source. Ketones provide more ATP (energy) per unit of oxygen than glucose, which is why many fasters report heightened mental clarity."),
                ArticleSection(heading: "BDNF and Neuroplasticity", body: "Fasting increases Brain-Derived Neurotrophic Factor (BDNF), a protein that supports the growth of new neurons and strengthens existing neural connections. Higher BDNF is associated with better learning, memory, and mood."),
                ArticleSection(heading: "Neuroprotection", body: "Research suggests intermittent fasting may protect against neurodegenerative diseases by reducing oxidative stress, inflammation, and the accumulation of damaged proteins in the brain."),
            ],
            references: [
                "Mattson MP. Energy intake and exercise as determinants of brain health and vulnerability to injury and disease. Cell Metab. 2012;16(6):706-722.",
                "Gudden J, et al. The Effects of Intermittent Fasting on Brain and Cognitive Function. Nutrients. 2021;13(9):3166.",
            ],
            isPremium: false
        ),
        Article(
            id: 4,
            title: "Heart Health & Longevity",
            subtitle: "Cardiovascular and anti-aging benefits",
            icon: "heart.fill",
            iconColor: .red,
            sections: [
                ArticleSection(heading: "Cardiovascular Markers", body: "Studies show intermittent fasting can improve key heart health markers: reduced LDL cholesterol, lower triglycerides, decreased blood pressure, and reduced inflammatory markers like C-reactive protein."),
                ArticleSection(heading: "Cellular Aging", body: "Fasting activates sirtuins and AMPK — cellular pathways directly linked to longevity. These pathways enhance DNA repair, reduce oxidative damage, and improve mitochondrial function. They're the same pathways activated by calorie restriction, which extends lifespan in multiple species."),
                ArticleSection(heading: "Inflammation Reduction", body: "Chronic low-grade inflammation drives heart disease, diabetes, and cancer. Fasting significantly reduces inflammatory markers, giving the body time to heal and repair without the constant burden of food processing."),
            ],
            references: [
                "Malinowski B, et al. Intermittent Fasting in Cardiovascular Disorders — An Overview. Nutrients. 2019;11(3):673.",
                "Cabo R, Mattson MP. Effects of Intermittent Fasting on Health, Aging, and Disease. N Engl J Med. 2019;381(26):2541-2551.",
            ],
            isPremium: true
        ),
        Article(
            id: 5,
            title: "Autophagy Explained",
            subtitle: "Your body's built-in cellular recycling system",
            icon: "sparkles",
            iconColor: .purple,
            sections: [
                ArticleSection(heading: "What is Autophagy?", body: "Autophagy (from Greek: 'self-eating') is the body's way of cleaning out damaged cells to regenerate newer, healthier cells. Yoshinori Ohsumi won the 2016 Nobel Prize in Physiology for discovering the mechanisms of autophagy."),
                ArticleSection(heading: "When Does It Happen?", body: "Autophagy is always occurring at a low level, but it's significantly upregulated during fasting. The process accelerates after 18-24 hours without food, as the body's nutrient-sensing pathways (mTOR, AMPK) shift into cleanup mode."),
                ArticleSection(heading: "Health Implications", body: "Enhanced autophagy is associated with reduced cancer risk (clearing precancerous cells), neuroprotection (removing toxic protein aggregates), improved immune function (recycling old immune cells), and anti-aging benefits."),
            ],
            references: [
                "Bagherniya M, et al. The effect of fasting or calorie restriction on autophagy induction: A review of the literature. Ageing Res Rev. 2018;47:183-197.",
                "Ohsumi Y. Historical landmarks of autophagy research. Cell Res. 2014;24(1):9-23.",
            ],
            isPremium: true
        ),
    ]

    // MARK: - Glossary

    struct GlossaryTerm: Identifiable {
        let id: Int
        let term: String
        let definition: String
        let relatedTerms: [String]
    }

    static let glossary: [GlossaryTerm] = [
        GlossaryTerm(id: 1, term: "Autophagy", definition: "The body's cellular recycling process where damaged or dysfunctional cellular components are broken down and reused. Derived from Greek meaning 'self-eating'. Significantly enhanced during extended fasting (18+ hours).", relatedTerms: ["Mitophagy", "mTOR"]),
        GlossaryTerm(id: 2, term: "Ketosis", definition: "A metabolic state where the body primarily burns fat and produces ketone bodies for energy instead of relying on glucose. Typically begins after 18-24 hours of fasting.", relatedTerms: ["Ketone Bodies", "Fat Oxidation"]),
        GlossaryTerm(id: 3, term: "Ketone Bodies", definition: "Molecules (beta-hydroxybutyrate, acetoacetate, acetone) produced by the liver from fatty acids during fasting or carbohydrate restriction. An efficient alternative fuel for the brain and muscles.", relatedTerms: ["Ketosis", "Beta-Hydroxybutyrate"]),
        GlossaryTerm(id: 4, term: "Glycogenolysis", definition: "The breakdown of glycogen (stored glucose) in the liver and muscles back into glucose for energy. This is the body's first response to fasting before switching to fat burning.", relatedTerms: ["Glycogen", "Gluconeogenesis"]),
        GlossaryTerm(id: 5, term: "Lipolysis", definition: "The process of breaking down stored fat (triglycerides) into fatty acids and glycerol for energy. Lipolysis increases significantly after 12+ hours of fasting as insulin levels drop.", relatedTerms: ["Fat Oxidation", "Insulin"]),
        GlossaryTerm(id: 6, term: "Insulin", definition: "A hormone produced by the pancreas that regulates blood sugar. Insulin signals cells to absorb glucose and inhibits fat burning. Fasting lowers insulin levels, allowing fat mobilization.", relatedTerms: ["Insulin Resistance", "Glucose"]),
        GlossaryTerm(id: 7, term: "Ghrelin", definition: "The 'hunger hormone' produced primarily in the stomach. Ghrelin levels peak at habitual meal times but adapt to new eating schedules within 2-3 weeks of consistent fasting.", relatedTerms: ["Leptin", "Hunger"]),
        GlossaryTerm(id: 8, term: "BDNF", definition: "Brain-Derived Neurotrophic Factor — a protein that supports the growth and survival of neurons. Fasting increases BDNF levels, which is associated with improved learning, memory, and mood.", relatedTerms: ["Neuroplasticity", "Neuroprotection"]),
        GlossaryTerm(id: 9, term: "mTOR", definition: "Mechanistic Target of Rapamycin — a cellular growth pathway. When mTOR is active (fed state), cells grow and divide. When inhibited (fasting), autophagy increases. Fasting downregulates mTOR.", relatedTerms: ["Autophagy", "AMPK"]),
        GlossaryTerm(id: 10, term: "AMPK", definition: "AMP-activated Protein Kinase — a cellular energy sensor. Activated during fasting when cellular energy is low. AMPK triggers fat burning, autophagy, and mitochondrial biogenesis.", relatedTerms: ["mTOR", "Autophagy"]),
        GlossaryTerm(id: 11, term: "Circadian Rhythm", definition: "Your body's internal 24-hour clock that regulates sleep, metabolism, and hormone release. Aligning your eating window with circadian rhythms (earlier in the day) may enhance fasting benefits.", relatedTerms: ["Time-Restricted Eating"]),
        GlossaryTerm(id: 12, term: "Metabolic Flexibility", definition: "The body's ability to efficiently switch between burning glucose and burning fat for fuel. Regular fasting improves metabolic flexibility, leading to more stable energy levels.", relatedTerms: ["Fat Oxidation", "Ketosis"]),
        GlossaryTerm(id: 13, term: "Time-Restricted Eating", definition: "A form of intermittent fasting where all daily food intake is confined to a specific window (typically 4-12 hours). Examples include 16:8 and 18:6 schedules.", relatedTerms: ["Eating Window", "Circadian Rhythm"]),
        GlossaryTerm(id: 14, term: "Eating Window", definition: "The designated period during which you consume all your daily calories. In a 16:8 schedule, the eating window is 8 hours. Meals and snacks should be consumed only during this time.", relatedTerms: ["Time-Restricted Eating", "Fasting Window"]),
        GlossaryTerm(id: 15, term: "Mitophagy", definition: "A specific form of autophagy targeting damaged mitochondria (the cell's energy producers). Fasting-induced mitophagy replaces old, inefficient mitochondria with new ones, improving cellular energy production.", relatedTerms: ["Autophagy", "Mitochondria"]),
    ]

    // MARK: - Medical Disclaimer

    static let disclaimer = """
    The information provided in Lumifaste is for educational and informational purposes only \
    and is not intended as medical advice, diagnosis, or treatment. Always consult a qualified \
    healthcare professional before starting any fasting program, especially if you have existing \
    health conditions, take medications, are pregnant or breastfeeding, or have a history of \
    eating disorders. Individual results vary. If you feel unwell during a fast, stop immediately \
    and consult your doctor.
    """

    static let shortDisclaimer = "Educational content only — not medical advice. Consult your doctor before starting any fasting program."
}
