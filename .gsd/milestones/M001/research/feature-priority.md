# ZenFast — Feature Prioritization Matrix

> **Last updated:** 2026-03-22
> **Based on:** Competitive analysis of Zero, Simple, Fasted, BodyFast, DoFasting, FastHabit, LIFE Fasting Tracker, and Fastic. Market research from Fortune, Business Research Insights, Verified Market Reports, and App Store review data.

## Market Context

The intermittent fasting app market was valued at ~$0.43B in 2024, projected to reach ~$1B by 2033 at ~8.4% CAGR. Zero is the market leader (~10M+ completed fasts logged). The top apps all monetize via auto-renewable subscriptions ($60–$70/year). Key competitive differentiators in 2026: timer reliability, schedule flexibility, fasting stage visualization, HealthKit/wearable integration, and educational content. Users churn when apps feel bloated or over-gate basic features behind paywalls.

**ZenFast positioning:** Clean, focused fasting tracker — does the core things exceptionally well without bloat. Premium tier unlocks advanced insights, not basic functionality.

---

## Tier 1 — MVP (v1.0 — Must Ship for App Store Launch)

These features are non-negotiable for a credible App Store launch. Without any one of them, ZenFast either fails App Review, looks incomplete versus competitors, or can't generate revenue.

| # | Feature | Why It's MVP | Complexity | Requirement |
|---|---------|-------------|------------|-------------|
| 1 | **Core Fasting Timer** (circular, count-up with elapsed time, start/stop/end fast) | The entire product is a fasting tracker. Every competitor has this. Zero lets you "start a fast with a single tap." If this isn't rock-solid and delightful, nothing else matters. Count-up preferred — users report it as more motivating than watching a countdown. | **Medium** | R-TIMER |
| 2 | **Fasting Plans** (16:8, 18:6, 20:4, OMAD, 5:2, Custom) | All top competitors (Zero, Simple, Fasted, BodyFast) offer multiple built-in schedules plus custom. Fasted specifically highlights "multiple built-in schedules" as a core differentiator. Users need plan variety from day one — 16:8 alone won't retain anyone beyond beginners. | **Low** | R-PLANS |
| 3 | **Fasting Stages Visualization** (fed → catabolic → fat burning → ketosis → autophagy) | Zero gates this behind their $69.99/year "Zero Plus" tier as "Fasting Zones." It's one of the top reasons users subscribe. For ZenFast, showing basic stages free (with deeper insights as premium) is a competitive advantage and a key retention hook. Users report fasting stages as "fascinating and motivating." | **Medium** | R-STAGES |
| 4 | **Progress History & Streaks** | Every fasting app has history/streaks. Zero prominently features "streak tracking, badges, etc." as motivation tools. Fasted highlights "detailed stats and streak tracking." Without history, there's no reason to keep using the app after day one. Streaks drive daily opens. | **Medium** | R-HISTORY |
| 5 | **Onboarding Flow** (goal selection, plan recommendation, permission requests) | App Store reviewers test the first-run experience. Simple and Zero both use onboarding quizzes for personalization. A clean onboarding that recommends a plan based on experience level and goals dramatically improves activation. Apple also expects permission explanations during onboarding. | **Medium** | R-ONBOARD |
| 6 | **IAP / Subscription (StoreKit 2)** — Paywall, Restore Purchases, subscription management | **Apple requires StoreKit** for digital goods. "Restore Purchases" button is mandatory for auto-renewable subscriptions per App Review Guideline 3.1.1. Zero charges $69.99/year; Simple charges $10–$20/month. Without a working subscription system at launch, there is zero revenue and likely App Review rejection. Must include: free trial offer, clear pricing display, restore mechanism. | **High** | R-IAP |
| 7 | **Push Notifications** (fast start/end reminders, milestone alerts) | Every competitor offers fasting reminders. Simple's "accountability aspect comes from the app's reminder system." Without notifications, users forget to start/end fasts and churn. Milestone notifications ("You've been fasting 16 hours!") are the #1 re-engagement mechanism. | **Low** | R-NOTIF |
| 8 | **Settings** (notification preferences, units kg/lb, time format, plan defaults) | Apple expects user control over notifications and data. Basic settings are table stakes — imperial/metric toggle, notification scheduling, plan defaults. Without this, the app feels half-built. | **Low** | R-SETTINGS |
| 9 | **Dark Mode** | iOS has system-wide dark mode. Apple's HIG strongly recommends supporting both appearances. Most health/fasting apps default to dark themes — users check fasting timers at night or early morning. Not supporting dark mode in 2026 looks amateurish. | **Low** | R-DARKMODE |
| 10 | **Privacy Policy & Legal** (in-app link, App Store metadata, terms of use) | Apple App Store mandates a privacy policy link both in App Store Connect metadata and accessible within the app. Health apps face extra scrutiny — "Apple's being extra cautious about apps that access health info." Missing privacy policy = automatic rejection. | **Low** | R-LEGAL |
| 11 | **Basic Analytics / Tracking Foundation** | Not user-facing per se, but you need event tracking from day one to understand activation, paywall conversion, and churn. Needed to make data-informed decisions for v1.1. Wire up at minimum: onboarding completion rate, fast start/complete rate, paywall view → subscribe conversion. | **Low** | R-ANALYTICS |

### MVP Complexity Summary
- **Low:** 5 features (Plans, Notifications, Settings, Dark Mode, Legal, Analytics)
- **Medium:** 4 features (Timer, Stages, History, Onboarding)
- **High:** 1 feature (IAP/StoreKit 2)

### What's Deliberately NOT in MVP

These are the hardest cuts. Each was considered for MVP but deferred because they aren't launch-blocking:

- **HealthKit** — Valuable but not required to track fasts. Adds App Review complexity (health data permissions). Deferred to v1.1.
- **Widgets** — Zero's homescreen widget is cited as a "true homescreen hero," but the app is fully functional without them. High-impact retention feature for v1.1.
- **CloudKit Sync** — Users don't switch devices in week one. Sync matters for retention at month 2+.
- **Educational Content** — Zero's educational articles are praised, but writing/curating quality content takes time. Better to ship a great timer and add content post-launch.

---

## Tier 2 — v1.1 (First Major Update — Weeks 2–4 Post-Launch)

These features increase retention, conversion, and daily engagement. They're the features that turn a "downloaded once" app into a daily habit. Prioritized by expected impact on 7-day and 30-day retention.

| # | Feature | Why v1.1 | Impact | Complexity | Requirement |
|---|---------|---------|--------|------------|-------------|
| 1 | **Home Screen Widget** (current fast status, elapsed time, next eating window) | Zero's widget is repeatedly cited as its killer feature — "a true homescreen hero" that serves as "a countdown until I can eat" and "a motivator just to keep going a little longer." Widgets drive daily passive engagement without opening the app. | **Very High** — drives daily glanceability | **Medium** | R-WIDGET-HOME |
| 2 | **Lock Screen Widget** (compact fast status) | iOS 16+ lock screen widgets are prime real estate. A glanceable "14h 23m fasted" on the lock screen is the single lowest-friction engagement surface on iOS. | **High** — zero-tap visibility | **Low** | R-WIDGET-LOCK |
| 3 | **HealthKit Integration** (read: weight, steps; write: fasting hours) | Zero syncs with Apple Health, Google Fit, Fitbit, and Oura. DoFasting integrates with "Apple Watch, Fitbit, Google Fit." HealthKit lets users see fasting alongside weight trends — the correlation is the insight that justifies the subscription. | **High** — unlocks weight+fasting correlation charts | **Medium** | R-HEALTHKIT |
| 4 | **Educational Content** (fasting science articles, stage explanations, beginner guides) | Zero has an "ever-growing content library" and is praised for "science-backed" articles authored by Dr. Peter Attia. Simple offers "easy-to-read articles written by a dietitian." Content builds trust, justifies premium pricing, and improves SEO/ASO. Start with 10–15 well-written articles. | **Medium** — builds trust, supports premium | **Medium** | R-EDUCATION |
| 5 | **Enhanced Stats & Insights** (weekly/monthly trends, average fast duration, best streak, fasting consistency score) | Fasted differentiates on "detailed stats" and "real stats without the bloat." Advanced analytics are a natural premium gate — free users see basic history, subscribers get trend analysis and insights. | **Medium** — justifies subscription | **Medium** | R-INSIGHTS |
| 6 | **Paywall Optimization** (A/B test pricing, add weekly/monthly/annual tiers, introductory offers) | Zero offers monthly ($9.99) and annual ($69.99). Simple ranges $10–$20/month. StoreKit 2 supports introductory offers and promotional pricing. By v1.1 you'll have conversion data to optimize. | **High** — directly impacts revenue | **Low** | R-PAYWALL |

### v1.1 Success Metrics
- 7-day retention ≥ 40% (industry benchmark for health apps)
- Widget adoption ≥ 25% of active users
- Trial-to-paid conversion ≥ 8%

---

## Tier 3 — v2.0 (Future — Month 2+)

Differentiators, expansion features, and nice-to-haves. These build competitive moats and expand the addressable market, but each is a significant engineering investment.

| # | Feature | Why v2.0 | Impact | Complexity | Requirement |
|---|---------|---------|--------|------------|-------------|
| 1 | **Live Activity / Dynamic Island** (real-time fast progress on lock screen and Dynamic Island) | A persistent, glanceable fasting timer on the Dynamic Island is a killer differentiator — most fasting apps haven't shipped this yet. However, it requires ActivityKit, has device restrictions (iPhone 14 Pro+), and adds ongoing maintenance. Ship after widgets prove the glanceability thesis. | **High** — premium differentiator | **High** | R-LIVEACTIVITY |
| 2 | **Apple Watch App** (companion app with timer, complications, haptic milestones) | FastHabit is positioned as "Best for Apple Watch users." Zero and DoFasting both have Watch support. The Watch is the ultimate glanceable device for fasting — wrist tap at 16 hours is powerful. But it's essentially a second app to build and maintain. | **High** — new surface, new audience | **Very High** | R-WATCH |
| 3 | **CloudKit Sync** (cross-device data sync, backup/restore) | Users who stay past month 1 start caring about data portability. Multi-device users (iPhone + iPad) expect sync. CloudKit is free for reasonable usage and handles conflict resolution. Also serves as implicit backup — users won't lose streaks if they get a new phone. | **Medium** — retention for power users | **High** | R-CLOUDSYNC |
| 4 | **Data Export** (CSV/JSON export of fasting history, weight log) | Power users and quantified-self crowd want to export data to spreadsheets or other tools. Also a trust signal — "we don't hold your data hostage." Low effort, high goodwill. | **Low** — trust & goodwill | **Low** | R-EXPORT |
| 5 | **Social / Community Features** (group fasts, friend challenges, leaderboards) | LIFE Fasting Tracker is "Best for social accountability and group fasting." Zero has "Challenges" and seasonal group fasts. Community features drive viral growth and accountability — but they require moderation tooling (Apple requires "Report" and "Block" for UGC), backend infrastructure, and ongoing community management. Not worth the complexity until the core product is proven. | **Medium** — viral growth, accountability | **Very High** | R-SOCIAL |
| 6 | **AI-Powered Insights** (personalized fasting recommendations, pattern detection) | Simple has "invested heavily in AI coaching." Modern IF apps increasingly use "AI and machine learning algorithms to provide personalized fasting plans." This is the emerging competitive frontier — but requires significant data collection first. v1.0 and v1.1 build the data foundation; v2.0 can leverage it. | **Medium** — emerging differentiator | **High** | R-AI |
| 7 | **Meal Logging / Nutrition Tracking** (photo-based or text meal log, basic calorie awareness) | Zero recently added meal logging ("Snap a photo or type in a description"). Yazio combines fasting with calorie tracking. This expands ZenFast from a fasting timer into a holistic health tool — but risks bloat. Only pursue if retention data shows users wanting this. | **Medium** — market expansion | **High** | R-MEALS |
| 8 | **Hydration Tracking** (daily water goal, tap-to-log) | Zero provides "a personalized daily water goal and simple visual tracking with just a tap." Hydration supports fasting success and is low-friction to log. Good candidate for a free feature that increases daily opens. | **Low** — daily engagement | **Low** | R-HYDRATION |
| 9 | **Mood / Journal** (post-fast reflection, mood tracking, energy levels) | Zero has a "Journal" feature — "Reflect on how you feel during your fasts. We'll graph your moods." Journaling adds qualitative data to complement quantitative fasting stats. Lightweight implementation, but value is unclear until validated. | **Low** — qualitative data | **Low** | R-JOURNAL |
| 10 | **iPad App** (optimized layout, split view) | Expands device coverage. Low incremental effort if built with SwiftUI adaptive layouts from the start. But iPad usage for a fasting timer is minimal — this is an "easy win" not a priority. | **Low** — device coverage | **Low** | R-IPAD |
| 11 | **Localization** (multi-language support) | Required for international expansion. The IF app market is growing fastest in Asia-Pacific. Start with English, Spanish, German, French, Japanese — cover the top App Store markets. | **Medium** — TAM expansion | **Medium** | R-L10N |
| 12 | **Siri Shortcuts / App Intents** ("Hey Siri, start my fast") | Convenience feature for hands-free fast management. Low complexity with App Intents framework. Nice differentiator but not a retention driver. | **Low** — convenience | **Low** | R-SIRI |

---

## Dependency Map

```
v1.0 MVP
├── Core Timer ──────────────┐
├── Fasting Plans ───────────┤
├── Fasting Stages ──────────┤
├── Progress History ────────┤
├── Onboarding ──────────────┤
├── IAP / StoreKit 2 ────────┤
├── Push Notifications ──────┤
├── Settings ────────────────┤
├── Dark Mode ───────────────┤
├── Privacy/Legal ───────────┤
└── Analytics Foundation ────┘
        │
        ▼
v1.1 (Weeks 2–4)
├── Home Screen Widget ←── requires Timer state
├── Lock Screen Widget ←── requires Timer state
├── HealthKit ←── requires History (for correlation)
├── Educational Content ←── requires Stages (references)
├── Enhanced Stats ←── requires History + Analytics data
└── Paywall Optimization ←── requires IAP + Analytics data
        │
        ▼
v2.0 (Month 2+)
├── Live Activity ←── requires Timer + Widget patterns
├── Apple Watch ←── requires Timer + CloudKit (sync)
├── CloudKit Sync ←── requires History (data model stable)
├── Data Export ←── requires History
├── Social Features ←── requires CloudKit + moderation
├── AI Insights ←── requires History + HealthKit + Analytics
├── Meal Logging ←── requires HealthKit
├── Hydration ←── independent
├── Mood/Journal ←── requires History
├── iPad App ←── requires adaptive layouts (plan from v1.0)
├── Localization ←── independent (but easier with stable UI)
└── Siri Shortcuts ←── requires Timer
```

---

## Competitive Feature Matrix (Reference)

How ZenFast's planned features compare to top competitors at each tier:

| Feature | Zero | Simple | Fasted | BodyFast | ZenFast MVP | ZenFast v1.1 | ZenFast v2.0 |
|---------|------|--------|--------|----------|-------------|-------------|-------------|
| Fasting Timer | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Multiple Plans | ✅ | ✅ | ✅ | ✅ (30+) | ✅ | ✅ | ✅ |
| Fasting Stages | 💰 | ✅ | ❌ | ❌ | ✅ (basic free) | ✅ | ✅ |
| Streaks/History | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Home Widget | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ |
| Lock Screen Widget | ✅ | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ |
| HealthKit | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ |
| Educational Content | ✅ (extensive) | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Live Activity | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ |
| Apple Watch | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ |
| CloudKit Sync | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |
| AI Coaching | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ✅ |
| Social/Community | 💰 | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Meal Logging | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ |

✅ = included, 💰 = premium only, ❌ = not available

---

## Monetization Strategy (Across Tiers)

### Free Tier (must be generous — this is how you beat Zero)
- Full fasting timer with all plans
- Basic fasting stages (show stage names + entry times)
- 7-day history view
- Current streak
- Push notification reminders
- Widgets (v1.1 — free)

### Premium Tier ($49.99/year or $6.99/month — undercut Zero's $69.99)
- **v1.0:** Unlimited history, detailed stage insights, advanced streak analytics
- **v1.1:** HealthKit correlation charts, weekly/monthly trend reports, educational library
- **v2.0:** AI insights, data export, mood journal, extended fasting plans

### Pricing Rationale
Zero charges $69.99/year. Fasted and FastHabit charge ~$59.99/year. Undercutting at $49.99/year while offering fasting stages for free (Zero's premium-only feature) creates a strong value proposition. The free tier must be genuinely useful — aggressive paywalling is the #1 complaint in fasting app reviews.

---

## Sources

1. Fortune — "The Best Intermittent Fasting Apps (2026)" — https://fortune.com/article/best-intermittent-fasting-apps/
2. Business Research Insights — "Intermittent Fasting App Market" — https://www.businessresearchinsights.com/market-reports/intermittent-fasting-app-market-114025
3. Verified Market Reports — "Intermittent Fasting App Market Size" — https://www.verifiedmarketreports.com/product/intermittent-fasting-app-market/
4. Fasted — "Best Intermittent Fasting App in 2026" — https://getfasted.app/articles/comparisons/compare-best-app
5. Zero Longevity — https://zerolongevity.com
6. Zero (App Store) — https://apps.apple.com/us/app/zero-fasting-food-tracker/id1168348542
7. Zero (Google Play) — https://play.google.com/store/apps/details?id=com.zerofasting.zero
8. TechRadar — "Homescreen Heroes: Zero" — https://www.techradar.com/computing/websites-apps/homescreen-heroes-zero-app
9. MetaPress — "Best Intermittent Fasting Apps of 2026" — https://metapress.com/best-intermittent-fasting-apps-of-2026-for-a-healthier-you/
10. AppInstitute — "App Store Review Checklist 2025" — https://appinstitute.com/app-store-review-checklist/
11. Apple — "Auto-renewable Subscriptions" — https://developer.apple.com/app-store/subscriptions/
12. Apple — "App Review Guidelines" — https://developer.apple.com/app-store/review/guidelines/
13. DEV Community — "StoreKit 2 Updates" — https://dev.to/arshtechpro/wwdc-2025-whats-new-in-storekit-and-in-app-purchase-31if
