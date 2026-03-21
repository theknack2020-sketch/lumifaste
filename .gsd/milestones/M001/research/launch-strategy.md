# Fasting/Health iOS App — Launch Strategy

> Comprehensive 4-phase playbook from pre-launch through 6-month growth.
> Based on current (2025–2026) App Store landscape, ASO best practices, and fasting app market data.

---

## Market Context

The intermittent fasting app market was valued at approximately **$0.43B in 2024** and is projected to reach **$1.03B by 2033** (CAGR ~8.4%). Nearly **50% of American adults** have tried some form of intermittent fasting. The market is **highly fragmented** — established players include Zero, Simple, Fastic, DoFasting, BodyFast, and FastHabit, but there is significant room for differentiated entrants.

**Key competitors to study:**
| App | Positioning | Monetization |
|-----|------------|-------------|
| **Zero** | Science-backed, minimalist timer + education | Freemium, $69.99/yr premium |
| **Simple** | AI-powered coaching, personalization quiz | Freemium, ~$0.33/day subscription |
| **Fastic** | Community + meal planning + coaching | Subscription |
| **DoFasting** | Meals + workouts + fasting combined | Subscription |
| **BodyFast** | AI-driven fasting plans | Subscription |

**Your differentiation angle matters.** The market doesn't need another timer — it needs something that addresses gaps: Apple Watch depth, HealthKit integration, privacy-first on-device processing, Ramadan/religious fasting support, community accountability, or clinical-grade tracking.

---

## Phase 1 — Pre-Launch (Weeks -4 to -1)

### 1.1 TestFlight Beta Strategy

**Target: 200–500 external testers over 3–4 weeks.**

TestFlight supports up to 10,000 external testers. You won't need that many — quality feedback from a focused group beats volume.

**Where to recruit testers:**
- **Reddit communities** — r/intermittentfasting (1.5M+), r/fasting (400K+), r/loseit. Post genuinely: "Building a fasting app, looking for beta testers who'll give honest feedback." Do NOT be promotional.
- **Twitter/X** — #buildinpublic, iOS dev community. Share screenshots, ask for testers.
- **Discord servers** — Fasting/health communities, indie dev servers (iOS Dev Happy Hour, etc.)
- **Facebook Groups** — Intermittent fasting groups (some have 500K+ members)
- **Personal network** — Friends/family who fast, colleagues
- **Indie Hackers** — Post in the community forum

**Beta feedback collection:**
- Use a **private Discord channel** or **TestFlight's built-in feedback** (screenshot + annotation)
- Create a short Google Form for structured feedback (5 questions max)
- Do **5–10 one-on-one calls** with engaged testers — these yield 10x the insight
- Ask beta testers for testimonial quotes you can use on your App Store listing and landing page

**Beta milestones:**
- Week 1: Core flow validation (start fast → track → end fast → view history)
- Week 2: Edge cases, crash reports, onboarding friction
- Week 3: Polish based on feedback, test premium flow
- Week 4: Final build, collect testimonials, prep for submission

### 1.2 App Store Connect Preparation

**Screenshots (most critical conversion asset):**

The first two screenshots determine whether users explore or bounce. Treat them as conversion assets, not decoration.

- **Optimal count:** 5–8 screenshots
- **Frame 1:** Main benefit / hero value proposition ("Track Your Fasting Journey")
- **Frame 2:** Unique selling point / differentiator
- **Frame 3:** Social proof or key stat
- **Frames 4–6:** Core feature scenarios (timer, stats, meal window, HealthKit sync)
- **Frames 7–8:** Premium features or innovative additions
- Use **high-contrast text**, clear hierarchy, device frames
- Export all required sizes (6.7", 6.5", 5.5" for iPhone; 12.9" for iPad if supported)
- Test screenshots with beta users and on social media before submission

**App Preview Video (optional but high-impact):**
- 15–30 seconds, must show only in-app content (Apple requirement)
- Focus on the "aha moment" — starting a fast, watching the timer, seeing progress
- No external footage, no talking heads

**Description:**
- Strong first paragraph (only ~3 lines visible before "more")
- Lead with benefits, not features
- Use bullet points for scanability
- Note: App Store description is **NOT indexed** for search on iOS — it's purely for conversion

**What's New text:**
- Keep it specific and user-focused for each release
- Avoid "bug fixes and performance improvements" — lost opportunity for engagement

### 1.3 ASO Optimization

ASO is foundational — 70% of App Store visitors use search to find apps, and 65% of downloads come from organic search.

**Title (30 characters max — highest keyword weight):**
```
FastTrack: Intermittent Fasting
```
- Brand name + primary keyword
- Pattern follows top performers: "Calm: Sleep & Meditation", "Zero: Fasting Tracker"

**Subtitle (30 characters max — second highest weight):**
```
Timer, Weight Loss & Health
```
- Secondary keywords that complement the title
- Don't repeat words from the title

**Keyword Field (100 characters — hidden, comma-separated, no spaces):**
```
fasting,tracker,16:8,weight,diet,health,meal,plan,timer,autophagy,keto,IF,wellness,habit,schedule
```

**Keyword strategy principles:**
- No spaces after commas (wastes characters)
- Don't duplicate words already in title or subtitle (Apple indexes them automatically)
- Don't include "app" or "the" (indexed automatically)
- Mix high-traffic terms with long-tail/low-competition keywords
- Use singular forms (Apple matches plurals automatically)
- Include competitor-adjacent terms where relevant
- Target **long-tail queries** — "fasting timer 16:8" has less competition than "fasting"

**Category:** Health & Fitness (primary), Lifestyle (secondary)

**Tools for keyword research:**
- Astro (tryastro.app) — affordable, indie-friendly
- App Radar — comprehensive with AI-driven suggestions
- Sensor Tower / MobileAction — enterprise-grade
- App Store auto-suggestions — free, type keywords and see what Apple suggests

### 1.4 Social Media Presence

**Priority platforms (pick 2–3, do them well):**

| Platform | Why | Content Type |
|----------|-----|-------------|
| **Twitter/X** | #buildinpublic community, iOS dev network | Dev journey, screenshots, polls, beta invites |
| **Instagram** | Health/wellness audience lives here | Fasting tips, app screenshots, Reels with results |
| **TikTok** | Viral potential, health content performs well | Short demos, "day in the life" fasting content, before/after |
| **Reddit** | Fasting communities are massive and engaged | Genuine participation, AMA-style, not promotional |

**Content calendar (4 weeks pre-launch):**
- **Week -4:** Announce you're building the app. Share the "why" story.
- **Week -3:** Show design decisions, share a screenshot. Ask for input.
- **Week -2:** Beta results, user testimonials, feature highlight.
- **Week -1:** Countdown content. Landing page live. "Launching next Tuesday."

**Content principles:**
- Lead with value (fasting tips, health insights), not self-promotion
- Build in public — share the journey authentically
- Engage in existing communities before promoting anything
- One channel done consistently beats three done sporadically

### 1.5 Landing Page / Website

**Minimum viable landing page (launch before beta):**
- Hero: App name, one-sentence value prop, App Store badge (pre-order or "Coming Soon")
- 3–4 feature highlights with screenshots
- Social proof (beta tester quotes, metrics if available)
- Email capture for launch notification
- Link to press kit
- Privacy policy (required by Apple)
- Support/contact email

**Tools:** Carrd ($19/yr), Framer, or a simple Next.js/Hugo site.

**Domain:** Secure a clean domain early. `[appname].app` or `[appname]health.com`.

### 1.6 Press Kit Preparation

Create a `/press` page or downloadable ZIP containing:
- **App icon** (high-res, 1024×1024 PNG)
- **Screenshots** (full resolution, with and without device frames)
- **App preview video** (MP4)
- **Founder photo and bio** (1–2 paragraphs)
- **App description** (short: 1 paragraph; long: 3–4 paragraphs)
- **Key facts** (launch date, pricing, platforms, unique features)
- **Brand assets** (logo variations, color palette)
- **Contact email** for press inquiries

### 1.7 App Review Submission Strategy

As of 2026, approximately 90% of App Store submissions are reviewed within 24 hours. Standard review takes 24–48 hours.

**Submission timing:**
- Submit **5–7 days before** your target launch date
- Set the release to **"Manual Release"** — this lets you control exact launch timing after approval
- If approved early, you hold the release until your coordinated launch day
- **Avoid submitting** during Apple's holiday shutdown (late December) or immediately after major iOS releases (review queue spikes)

**Maximizing approval odds:**
- Include **clear review notes** explaining any unique functionality (fasting timer, health data access, HealthKit integration)
- Provide **demo account credentials** if the app requires login
- Ensure **privacy policy** is live and linked
- Include **account deletion** option (required since 2022)
- Build with the **latest Xcode/SDK** version
- Test on physical devices, not just simulator
- If using HealthKit: explain clearly what data you read/write and why

**Pre-order option:**
Consider enabling App Store pre-orders — users sign up and the app auto-downloads on release day. This builds initial download velocity, which signals the algorithm.

---

## Phase 2 — Launch Week

### 2.1 Day-by-Day Launch Plan

#### Day -1 (Sunday): Final Prep
- Verify app is approved and set to manual release
- Pre-write all social posts, emails, and community posts
- Brief any supporters (friends, beta testers, colleagues) — ask them to download and leave a review on Day 1
- Test App Store listing one more time (screenshots, description, links)
- Queue the Product Hunt launch (if launching there)

#### Day 0 (Monday/Tuesday — optimal launch days): LAUNCH
- **Morning (6–8 AM local):** Release the app on the App Store
- **Immediately:** Post on Twitter/X, Instagram, LinkedIn with App Store link
- **Morning:** Send launch email to your waitlist / beta testers
- **Mid-morning:** Post on Reddit (see strategy below)
- **Afternoon:** Engage with every comment, reply, and review
- **Evening:** Share first-day metrics on social (downloads, reactions)
- Monitor for crashes via Xcode Organizer and any analytics tool

#### Day 1: Sustain Momentum
- Follow up on Reddit threads, reply to comments
- Post on Indie Hackers, Hacker News (Show HN) if appropriate
- DM health/fitness micro-influencers with the app link
- Respond to every App Store review (positive and negative)

#### Day 2: Product Hunt Launch
- Launch on Product Hunt (see detailed strategy below)
- All-day engagement with PH comments
- Cross-promote the PH launch on Twitter/X and LinkedIn

#### Days 3–4: Press & Outreach
- Email press contacts with press kit
- Reach out to health/tech bloggers
- Share any early results (download numbers, user feedback)
- Post "behind the scenes" content

#### Days 5–7: Analyze & Adapt
- Review App Store Connect analytics (impressions, page views, conversion rate)
- Identify top-performing keywords
- Read all reviews and categorize feedback
- Plan first update based on real user data

### 2.2 Reddit Strategy

Reddit can be your highest-quality traffic source if done right. The fasting community there is massive and engaged.

**Target subreddits:**

| Subreddit | Size | Approach |
|-----------|------|----------|
| r/intermittentfasting | 1.5M+ | Share your fasting journey, mention the app naturally |
| r/fasting | 400K+ | Engage in discussions, offer the app as a helpful tool |
| r/loseit | 3M+ | Weight loss context, app as one tool in the toolkit |
| r/iOSapps | 100K+ | Direct app showcase, technical details welcome |
| r/iOSProgramming | 100K+ | Dev story, technical decisions, build-in-public |
| r/SideProject | 100K+ | Launch story, what you learned |

**Critical rules:**
- **DO NOT** spam links. Reddit will destroy you.
- **Start participating** 2–3 weeks before launch. Comment helpfully. Be a real community member.
- When you post about your app, frame it as **your story**: "I built this because I struggled with X..."
- Include screenshots/video. Show, don't tell.
- Respond to every comment within the first 2 hours
- r/iOSapps allows direct promotion — use it. Other subs require subtlety.
- Offer **promo codes** for premium features — Reddit loves free stuff and will reward you with genuine feedback

### 2.3 Product Hunt Launch

Product Hunt's team manually decides which products make the homepage, and filtering has gotten selective in 2025–2026. Products are evaluated on: Useful, Well-made, Interesting, and Unique.

**Preparation (2–3 weeks before):**
- Create your Product Hunt profile, complete with photo and bio
- Engage with the community — upvote and comment on other products
- Optionally connect with a **Hunter** (established PH user) to launch your product — they provide external perspective on your messaging
- Prepare assets: icon, screenshots, GIF demo, 30-second video
- Write your tagline (short, catchy, one sentence)
- Draft the description using this structure:
  1. One-line value prop
  2. Problem (1–2 sentences)
  3. Solution (1–2 sentences)
  4. 3–5 key features
  5. Who it's for
  6. What makes it different

**Launch day execution:**
- Launch at **12:01 AM PT** (Product Hunt's day resets at midnight Pacific)
- Notify your network: email, Twitter/X, LinkedIn — ask for upvotes + comments (not just upvotes)
- **Engage with every comment** within the first 2 hours — the first hour sets the tone
- Post a "Maker's Comment" with your personal story
- Share the PH link everywhere but **don't ask for upvotes directly** (against PH guidelines in spirit)
- Be present all day — responses show you're committed

**Post-launch:**
- Top products appear in daily and weekly PH newsletters — additional visibility
- Use feedback from comments to refine messaging and features
- Add "Featured on Product Hunt" badge to your website

### 2.4 App Store Featuring Request

Apple provides a **Featuring Nominations** form in App Store Connect for developers to pitch their apps to the editorial team.

**How to submit:**
1. Log in to App Store Connect
2. On the home page, go to Featured → Nominations
3. Complete every field — don't leave anything blank
4. Include: app description, uniqueness, key features, alignment with Apple values
5. Specify target countries/regions
6. Add supplemental materials (video, banners, presentations)

**Timing:** Apple recommends submitting **at least 2–3 weeks before** your launch date. For wider consideration, submit up to 3 months in advance.

**What Apple looks for:**
- UI design quality and adherence to Human Interface Guidelines
- User experience — cohesive, efficient, valuable
- Innovation — solves a unique problem or uses new Apple technologies
- Privacy and security — user data protection is a core Apple value
- Accessibility — VoiceOver, Dynamic Type, Dark Mode support
- Localization — multi-language support increases chances
- Use of latest Apple technologies (HealthKit, widgets, Apple Watch, Live Activities)

**Pro tips:**
- Align your launch with **seasonal moments** Apple cares about (New Year health, Wellness Day)
- If you support Apple Watch, mention it prominently — Apple loves multi-platform apps
- The review process for featuring can take up to 30 days — don't expect instant results
- Even if not featured at launch, resubmit with each significant update

### 2.5 Review/Rating Prompt Strategy

Apple's `SKStoreReviewController` allows up to **3 review prompts per 365-day period** per user. Use them wisely.

**When to prompt (trigger on positive moments):**
- After completing their **3rd or 5th fast** (user has proven engagement)
- After viewing their **weekly summary** showing progress
- After reaching a **milestone** (7-day streak, first 100 hours fasted)

**When NOT to prompt:**
- During onboarding / first session
- After a crash or error
- When the user is mid-fast (interrupts the experience)
- Immediately after a paywall decline

**Implementation:**
```swift
// Trigger after a positive milestone
if completedFasts >= 5 && !hasRequestedReview {
    SKStoreReviewController.requestReview()
    hasRequestedReview = true
}
```

**Response strategy:**
- Reply to **every** App Store review — both positive and negative
- For negative reviews: acknowledge, empathize, explain what you're fixing
- For positive reviews: thank them genuinely, it encourages others

### 2.6 Influencer Outreach

**Target micro-influencers (5K–50K followers) over macro-influencers.** They have higher engagement rates, are more affordable, and their audiences trust them more.

**Who to target:**
- Health/wellness content creators on Instagram and TikTok
- Intermittent fasting YouTubers (search "intermittent fasting results")
- Fitness podcasters (offer to be a guest, discuss app building journey)
- Nutritionists/dietitians with social media presence
- iOS/tech reviewers who cover health apps

**Outreach template:**
> Hi [Name], I've been following your [fasting/health] content and love [specific thing]. I just launched [App Name], a fasting tracker that [unique angle]. I'd love to offer you free premium access — no strings attached. If you find it useful, I'd be grateful for a mention, but no pressure. Here's the link: [...]

**Budget-conscious approach:**
- Offer free premium lifetime access (costs you nothing)
- Send 20–30 personalized outreach messages
- Expect 5–10% response rate (1–3 collaborations)
- Even 1 micro-influencer post can drive 100–500 downloads

---

## Phase 3 — Post-Launch (Weeks 2–8)

### 3.1 User Feedback Collection & Response

**Channels to monitor:**
- App Store reviews (daily)
- TestFlight feedback (if still running beta alongside production)
- Social media mentions and DMs
- Reddit threads you posted in
- Support email
- In-app feedback mechanism (add a simple "Send Feedback" button in settings)

**Feedback triage system:**
| Priority | Category | Action |
|----------|----------|--------|
| P0 | Crashes, data loss | Hotfix within 24–48 hours |
| P1 | Broken core features | Fix in next update (1 week) |
| P2 | UX friction, confusing flows | Queue for v1.1 |
| P3 | Feature requests | Log, analyze frequency, prioritize |

**Review response cadence:** Reply to every new review within 48 hours. This signals to Apple and users that you're an active, responsive developer.

### 3.2 First Update Priorities (v1.1 — target 2–3 weeks post-launch)

Your first update is critical — it shows users and Apple you're committed.

**Typical v1.1 should address:**
1. **Top 3 bug fixes** from real user reports
2. **#1 UX improvement** based on feedback (e.g., confusing onboarding step)
3. **1 small feature** users are asking for most (e.g., custom fasting schedules)
4. Updated ASO metadata based on initial keyword performance data

**Strategic considerations:**
- Updating the app lets you **update metadata** (keywords, screenshots) — you can only change ASO metadata with a new app version
- Include a meaningful "What's New" note that references user feedback: "You asked for custom schedules — here they are!"
- This update is another opportunity to **re-submit for featuring**

### 3.3 ASO Iteration Based on Real Data

After 2–4 weeks with live data from App Store Connect Analytics, optimize:

**Metrics to track:**
- **Impressions** — how often your app appears in search
- **Product Page Views** — users who clicked through
- **Conversion Rate** — views → downloads (benchmark: 25–35% for Health & Fitness)
- **Keyword rankings** — use an ASO tool to track positions

**Iteration cycle (every 2–4 weeks with each update):**
1. Identify keywords where you rank #5–15 (potential to improve)
2. Drop keywords where you rank #50+ with no movement
3. Add new keywords from auto-suggest and competitor analysis
4. A/B test screenshots using Product Page Optimization (Apple's built-in tool)
5. Test different subtitle variations

**Common first-iteration wins:**
- Swap a low-traffic keyword for a long-tail variant that's less competitive
- Reorder screenshots — put the highest-converting frame first
- Adjust subtitle to include an emerging keyword

### 3.4 Retention Analysis & Optimization

Retention is where fasting apps live or die. The App Store algorithm considers uninstall rate, engagement depth, and return frequency.

**Key retention metrics:**
| Metric | Target | How to Measure |
|--------|--------|---------------|
| Day 1 retention | >40% | Firebase / Mixpanel / Amplitude |
| Day 7 retention | >20% | Same |
| Day 30 retention | >10% | Same |
| Session frequency | 1–2x/day | Analytics |
| Fast completion rate | >70% | Custom event tracking |

**Retention levers for a fasting app:**
- **Push notifications** — gentle reminders to start/end fasts, streak alerts
- **Streaks** — "You've fasted 7 days in a row!" (powerful psychological hook)
- **Weekly summaries** — email or in-app digest of progress
- **Widgets** — iOS home screen widget showing current fast status (keeps app visible)
- **Apple Watch complication** — glanceable fast timer on wrist
- **HealthKit integration** — sync weight, creating a holistic health picture
- **Onboarding quality** — a confused user churns. Aim for <60 seconds to first fast start.
- **Personalization** — different fasting schedules (16:8, 18:6, OMAD, 5:2, custom)

### 3.5 Conversion Optimization for Premium

**Freemium model (recommended for fasting apps):**

| Free Tier | Premium Tier ($4.99–9.99/mo or $39.99–69.99/yr) |
|-----------|--------------------------------------------------|
| Basic timer | Advanced analytics & trends |
| 1–2 fasting schedules | All fasting schedules + custom |
| Basic stats | Detailed insights (autophagy zones, etc.) |
| Core HealthKit sync | Full health data integration |
| — | Meal logging / nutrition tips |
| — | Priority support |

**Conversion tactics:**
- **Soft paywall** after 5–7 days of use (user has experienced value)
- Show **locked premium features** with a preview — let users see what they're missing
- Offer a **7-day free trial** of premium (Apple supports this natively)
- **Annual plan discount** — show monthly vs. annual pricing, highlight savings
- Never gate core functionality (timer, basic tracking) — it kills retention
- Use **In-App Events** on the App Store to promote challenges or premium trials

**Pricing benchmarks (fasting app category):**
- Zero Plus: $69.99/year
- Simple: ~$120/year ($0.33/day)
- Fastic: ~$59.99/year
- Sweet spot for a new entrant: **$39.99–49.99/year** or **$4.99–6.99/month**

---

## Phase 4 — Growth (Months 2–6)

### 4.1 Content Marketing

Content marketing builds organic discoverability outside the App Store.

**Blog / SEO strategy:**
- Publish 2–4 articles/month on your website targeting fasting-related keywords
- Topics: "Beginner's Guide to 16:8 Fasting", "Intermittent Fasting and Coffee", "How Autophagy Works", "Fasting for Women", "Fasting During Ramadan"
- Each article should naturally link to your app as a tool
- Target long-tail keywords with moderate search volume

**YouTube:**
- Short tutorials: "How to Track Your Fast with [App Name]"
- Fasting education: "What Happens to Your Body at 16 Hours of Fasting"
- User stories: Before/after results (with permission)

**Email marketing:**
- Collect emails from website, onboarding, and in-app prompts
- Weekly fasting tips newsletter
- New feature announcements
- Re-engagement emails for churned users

### 4.2 Localization Priorities

Localization dramatically increases your addressable market and improves featuring chances with Apple.

**Phase 1 (Months 2–3) — Metadata only (title, subtitle, keywords, screenshots):**
1. **Spanish** — large US Hispanic market + Latin America
2. **German** — strong health/wellness market, high iOS adoption
3. **French** — France + Canada francophone
4. **Portuguese (Brazil)** — massive mobile market, growing health awareness
5. **Arabic** — for Ramadan fasting audience (huge and underserved)

**Phase 2 (Months 4–6) — Full in-app localization:**
- Prioritize based on download data from Phase 1
- Japanese, Korean, Turkish — high iOS markets with fasting interest

**iOS bonus:** Apple App Store supports extra locales beyond the device language. You can add keywords in additional locales to capture more search traffic at zero translation cost.

### 4.3 Feature Expansion Based on Data

Don't build features in a vacuum — let user data and feedback drive priorities.

**Month 2–3 (based on feedback patterns):**
- **Apple Watch app** — glanceable timer, complications (huge for daily-use health apps)
- **Widgets** — home screen and Lock Screen widgets
- **Shortcuts/Siri integration** — "Hey Siri, start my fast"
- **Social sharing** — share fasting streaks and milestones

**Month 3–4 (based on retention data):**
- **Meal logging** — light food tracking, photo-based
- **Water tracking** — frequently requested in fasting communities
- **Weight tracking** with trend graphs
- **Fasting education** — in-app articles on autophagy, metabolic switching

**Month 5–6 (based on conversion data):**
- **AI coaching** — personalized fasting recommendations based on history
- **Community features** — challenges, leaderboards, groups
- **Advanced analytics** — correlate fasting with weight, mood, energy
- **iPad app** — larger canvas for detailed charts and history

### 4.4 Seasonal Campaigns

Fasting apps have natural seasonal spikes. Plan content, features, and marketing around them.

| Season | Timing | Campaign |
|--------|--------|----------|
| **New Year** | Dec 26 – Jan 15 | "New Year, New You" fasting challenge. Run Apple Search Ads. Submit for App Store featuring. |
| **Ramadan** | Varies (Feb–Apr typically) | Ramadan fasting mode, Islamic calendar integration, localized for Arabic/Turkish/Malay. Submit for featuring 3 months early. |
| **Spring/Summer** | Mar – May | "Summer Body" campaign. Beach-ready content. Partner with fitness influencers. |
| **Back to School** | Aug – Sep | "Reset your routine" campaign. Focus on habit building. |
| **Wellness months** | Various | Align with National Nutrition Month (March), Mental Health Awareness Month (May), etc. |

**For each seasonal campaign:**
- Update App Store screenshots with seasonal messaging
- Create an **In-App Event** in App Store Connect (appears on your product page and in search)
- Run targeted **Apple Search Ads** campaigns (increase budget 2–3x during peak)
- Push notification campaign to re-engage lapsed users
- Submit a **featuring nomination** tied to the seasonal moment — Apple's editorial team curates themed collections

### 4.5 Paid Acquisition (When Organic Stalls)

Don't start paid ads until you've optimized your organic funnel (conversion rate, retention, paywall).

**Apple Search Ads (highest intent, App Store native):**
- Start with **Search Match** to discover which queries drive installs
- Budget: $10–20/day to start, scale what works
- Target competitor brand keywords (e.g., "Zero fasting app")
- Target category keywords (e.g., "intermittent fasting tracker")
- Use **Custom Product Pages** for different ad audiences

**Meta (Instagram/Facebook) Ads:**
- Target: Health & Wellness interests, fasting-related pages, 25–45 age range
- Creative: Short video showing app in use, before/after stats
- Campaign: App install objective with 7-day click attribution

**TikTok Ads:**
- Target: Health/fitness community, 18–35
- Creative: UGC-style, "I used this app for 30 days" format
- Lower CPIs than Meta for health apps in many markets

---

## Key Metrics Dashboard

Track these from Day 1:

| Metric | Tool | Frequency |
|--------|------|-----------|
| Downloads & impressions | App Store Connect | Daily |
| Keyword rankings | Astro / App Radar | Weekly |
| Day 1/7/30 retention | Firebase / Mixpanel | Weekly |
| Conversion rate (free → trial → paid) | RevenueCat / App Store Connect | Weekly |
| Crash rate | Xcode Organizer | Daily |
| App Store rating | App Store Connect | Daily |
| Revenue (MRR) | RevenueCat | Weekly |
| Session frequency & duration | Analytics platform | Weekly |

---

## Timeline Summary

```
Week -4  │ Start beta, social accounts, landing page, press kit
Week -3  │ Beta feedback, ASO research, content calendar begins
Week -2  │ Final beta build, screenshots, featuring nomination submitted
Week -1  │ Submit to App Review, pre-write all launch content
─────────┼──────────────────────────────────────────────────────
Week 0   │ 🚀 LAUNCH — Reddit, social, email, Product Hunt, influencers
Week 1   │ Monitor, respond to reviews, collect feedback
Week 2–3 │ Ship v1.1 (bug fixes + top request), iterate ASO
Week 4–6 │ Retention analysis, conversion optimization, Apple Watch/widgets
Week 7–8 │ Content marketing ramp, localization Phase 1
─────────┼──────────────────────────────────────────────────────
Month 3  │ Feature expansion based on data, seasonal campaign prep
Month 4  │ Full localization for top markets, community features
Month 5  │ Paid acquisition testing (Apple Search Ads first)
Month 6  │ AI features, advanced analytics, scale what works
```

---

## Sources

1. Moburst — "The Ultimate App Launch Strategy for 2026" (moburst.com)
2. Foresight Mobile — "iOS App Distribution Guide 2026" (foresightmobile.com)
3. ASOMobile — "ASO in 2025: Complete Guide" (asomobile.net)
4. App Radar — "ASO in the App Store 2025" (appradar.com)
5. Business Research Insights — "Intermittent Fasting App Market Report" (businessresearchinsights.com)
6. Fortune — "Best Intermittent Fasting Apps 2026" (fortune.com)
7. MobileAction — "Pre-Launch Marketing Strategy" (mobileaction.co)
8. Apple Developer — "Getting Featured on the App Store" (developer.apple.com)
9. Radaso — "Apple App Store Featuring Guide" (radaso.com)
10. CalmOps — "Product Hunt Launch Guide 2026" (calmops.com)
11. AppLaunchFlow — "App Launch Checklist 2026" (applaunchflow.com)
12. Semrush — "Complete Guide to ASO" (semrush.com)
13. Udonis — "ASO Complete 2025 Guide" (blog.udonis.co)
14. Hackmamba — "Product Hunt Launch 2026" (hackmamba.io)
