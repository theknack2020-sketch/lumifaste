# Apple App Store Review Guidelines — Fasting & Health Tracking Apps

> Research compiled: March 22, 2026
> Sources: Apple Developer Review Guidelines (last updated Feb 6, 2026), Apple Health & Fitness developer portal, supplementary App Store compliance guides.

---

## Summary

Apple's App Store Review Guidelines impose strict requirements on health, fitness, and medical apps across safety, privacy, data handling, monetization, and medical claims. Fasting and health-tracking apps must navigate Guideline 1.4 (Physical Harm), 2.5.1 (HealthKit intended use), 5.1.2 (Data Use), 5.1.3 (Health and Health Research), subscription rules under 3.1.2, and the broader privacy framework. This document consolidates every applicable section with specific callouts for fasting/health-tracker apps.

---

## 1. Section 1.4 — Physical Harm (Health & Wellness)

Apple's primary health-specific safety guideline is **1.4 Physical Harm**, not a "Section 27" — the guidelines are organized into 5 sections (Safety, Performance, Business, Design, Legal), not 27+ sections. The relevant rules:

### 1.4.1 — Medical Apps

> *"Medical apps that could provide inaccurate data or information, or that could be used for diagnosing or treating patients may be reviewed with greater scrutiny."*

- **Accuracy claims**: Apps must clearly disclose data and methodology to support accuracy claims relating to health measurements. If the level of accuracy or methodology cannot be validated, Apple **will reject** the app.
- **Sensor-only claims prohibited**: Apps that claim to measure blood pressure, body temperature, blood glucose levels, or blood oxygen levels using only the device's sensors are **not permitted**.
- **Doctor disclaimer required**: Apps should remind users to check with a doctor in addition to using the app and before making medical decisions.
- **Regulatory clearance**: If your medical app has received regulatory clearance (e.g., FDA), submit a link to that documentation with your app.

### 1.4.2 — Drug Dosage Calculators

Must come from drug manufacturers, hospitals, universities, health insurance companies, pharmacies, or other approved entities, or receive FDA/equivalent approval.

### 1.4.3 — Substance Consumption

Apps must not encourage consumption of tobacco, vape products, illegal drugs, or excessive alcohol. **For fasting apps**: be careful with any content that could be interpreted as encouraging unhealthy restriction or extreme fasting patterns.

### 1.4.5 — Risky Activities

Apps should not urge customers to participate in activities that risk physical harm. **For fasting apps**: extended or extreme fasting challenges could trigger this guideline.

---

## 2. Common Rejection Reasons for Fasting Apps

Based on documented rejections and expert analysis, these are the most likely rejection triggers for fasting/health-tracker apps:

### High-Risk Rejection Areas

1. **Health data permission without explanation** — Requesting access to HealthKit data without clearly explaining why in the purpose string. Reviewers reject instantly if they see silent permission requests for health data.

2. **Unsubstantiated health claims** — Claiming the app can help users "burn fat," "enter ketosis," "autophagy activation," or "reverse aging" without scientific backing. Any claim that implies medical diagnosis or treatment outcomes will be flagged.

3. **Missing disclaimers** — Not including a disclaimer that the app does not provide medical advice and users should consult healthcare professionals.

4. **Metadata/pricing mismatch** — Subscription price shown in App Store metadata not matching the actual in-app price. This has caused documented rejections.

5. **Incomplete functionality** — Placeholder content, broken HealthKit integrations, or features described in metadata that don't actually work.

6. **Privacy policy gaps** — Vague or incomplete privacy policy, especially around health data collection, storage, and sharing.

7. **Background activity without justification** — Using background location, motion, or health monitoring without clear user-facing justification.

8. **Subscription dark patterns** — Presenting subscription offers in ways that trick or confuse users about pricing, renewal, or cancellation.

9. **Age rating miscategorization** — Health/wellness content may push the age rating to 13+ or 16+ under Apple's 2025 updated rating system. Failure to answer the medical/wellness content question correctly in the age rating questionnaire causes delays.

10. **Missing account deletion** — All apps with account creation must offer account deletion within the app (Guideline 5.1.1(v)).

---

## 3. Required Disclaimers for Health Apps

### Mandatory

- **Medical advice disclaimer**: Apps should remind users to "check with a doctor in addition to using the app and before making medical decisions" (Guideline 1.4.1).
- **Not a medical device** (unless it is): If the app is not a regulated medical device, state this clearly. Starting **spring 2026**, apps in the Medical or Health & Fitness category can indicate regulatory status in certain regions.
- **Data accuracy disclaimer**: If the app displays health metrics (weight trends, calorie estimates, fasting phase indicators), disclose the methodology and limitations.

### Strongly Recommended

- **"For informational purposes only"** — Clarify that fasting timers, phase indicators (e.g., "fat burning zone," "autophagy"), and health insights are educational/informational, not medical guidance.
- **"Consult your healthcare provider before starting any fasting program"** — Especially important for apps that suggest specific fasting protocols.
- **Eating disorder sensitivity disclaimer** — Consider including a note that the app is not appropriate for individuals with a history of eating disorders, or provide resources (e.g., NEDA helpline).
- **Pregnancy/medical conditions warning** — Warn that fasting may not be appropriate for pregnant or breastfeeding individuals, children, or those with specific medical conditions.

### Where to Place Disclaimers

- **App Store description** — Include key disclaimers in the app's metadata.
- **Onboarding flow** — Present health disclaimers during first-time setup.
- **Settings/About screen** — Accessible in-app at all times.
- **Before any "health insight" content** — Contextual disclaimers near fasting phase info, health tips, or personalized recommendations.

---

## 4. HealthKit Usage Guidelines & Review Requirements

### Guideline 2.5.1 — Intended Use

> *"HealthKit should be used for health and fitness purposes and integrate with the Health app."*

- HealthKit must be used **only for its intended purpose** — health and fitness.
- The integration must be described in the app description.
- Do not use HealthKit APIs for purposes unrelated to health/fitness functionality.

### Guideline 5.1.2(vi) — Data Use Restrictions

> *"Data gathered from the HealthKit API... may not be used for marketing, advertising or use-based data mining, including by third parties."*

This is **absolute**. No exceptions. Health data from HealthKit cannot be:
- Used for targeted advertising
- Sold or shared with ad networks
- Used to build marketing profiles
- Shared with third-party AI services for advertising purposes

### Guideline 5.1.3 — Health and Health Research

**(i) Data Use Restriction:**
> *"Apps may not use or disclose to third parties data gathered in the health, fitness, and medical research context—including from the Clinical Health Records API, HealthKit API, Motion and Fitness, MovementDisorder APIs, or health-related human subject research—for advertising, marketing, or other use-based data mining purposes other than improving health management, or for the purpose of health research, and then only with permission."*

- Health data can only be used for: **improving health management** or **health research** (with permission).
- You **must disclose the specific health data** you are collecting from the device.
- Data can be used to provide a direct benefit to the user (e.g., personalized insights), but cannot be shared with third parties for non-health purposes.

**(ii) Data Accuracy & Storage:**
> *"Apps must not write false or inaccurate data into HealthKit or any other medical research or health management apps, and may not store personal health information in iCloud."*

- **No false data**: Do not write fabricated or inaccurate entries to HealthKit.
- **No iCloud storage**: Personal health information must **not** be stored in iCloud.
- All HealthKit data stays on-device by default; there is no backend API for remote access.

**(iii) Research Consent** (if applicable):
If your app conducts health-related research (e.g., studying fasting outcomes), you must obtain informed consent covering: nature/purpose/duration, procedures/risks/benefits, confidentiality, contact info, withdrawal process.

**(iv) Ethics Board:**
Health-related human subject research requires approval from an independent ethics review board.

### HealthKit Technical Requirements

- **Native iOS app required** — HealthKit does not work in web apps or cross-platform wrappers that don't use native APIs.
- **Explicit per-type consent** — Users must grant permission for each specific data type (weight, heart rate, etc.) individually.
- **On-device first** — All HealthKit data stays on-device. You must build mobile-first architecture.
- **Purpose strings** — Every HealthKit data type you request must have a clear, specific purpose string explaining why you need it.

### Advertising Restrictions (Guideline 2.5.18)

> *"Ads displayed in an app... may not engage in targeted or behavioral advertising based on sensitive user data such as health/medical data (e.g. from the HealthKit APIs)."*

Even if your app shows ads, those ads **cannot be targeted** using any health data.

---

## 5. Subscription & In-App Purchase Review Requirements

### Guideline 3.1.1 — In-App Purchase Required

All premium features (fasting plans, advanced analytics, custom protocols, AI insights) must use Apple's in-app purchase system. No external payment mechanisms for digital content/features.

### Guideline 3.1.2 — Subscription Rules

**(a) Ongoing value requirement:**
- Auto-renewable subscriptions must provide **ongoing value** to the customer.
- Subscription period must last **at least 7 days**.
- Must be available across **all of the user's devices**.
- Users must get what they paid for **without additional tasks** (no "post to social media to unlock").

**(b) Upgrades/downgrades:**
- Users should have a seamless upgrade/downgrade experience.
- Users should not inadvertently subscribe to multiple variations.

**(c) Subscription information — CRITICAL:**
> *"Before asking a customer to subscribe, you should clearly describe what the user will get for the price."*

You **must** communicate:
- What the user gets (features, content, access)
- How many/how much (e.g., "unlimited fasting plans")
- Pricing and renewal terms
- Full details per Schedule 2 of the Apple Developer Program License Agreement

### Subscription Anti-Scam Rules

> *"Apps that attempt to scam users will be removed from the App Store. This includes apps that attempt to trick users into purchasing a subscription under false pretenses or engage in bait-and-switch and scam practices."*

**For fasting apps specifically:**
- Don't gate basic timer functionality behind a paywall if your free version is essentially useless.
- Don't show a "free trial" that auto-converts to a high-priced subscription without clear disclosure.
- Don't use confusing button placement that tricks users into subscribing.
- Pricing shown in metadata must match in-app pricing exactly.

### Pricing Fairness

> *"We won't distribute apps and in-app purchase items that are clear rip-offs. We'll reject expensive apps that try to cheat users with irrationally high prices."*

---

## 6. Privacy & Data Handling Requirements for Health Data

### 5.1.1 — Data Collection and Storage

**(i) Privacy policy required:**
- Must be linked in App Store Connect metadata **and** accessible within the app.
- Must clearly identify: what data is collected, how it's collected, all uses of that data.
- Must confirm third parties sharing data will provide equal protection.
- Must explain data retention/deletion policies and how users can revoke consent/request deletion.

**(ii) User consent:**
- Must secure user consent for any data collection, even "anonymous" data.
- Paid features **must not** require users to grant data access.
- Must provide an easily accessible way to withdraw consent.
- Purpose strings must clearly and completely describe data use.

**(iii) Data minimization:**
- Only request access to data relevant to core functionality.
- Only collect/use data required for the relevant task.

**(v) Account requirements:**
- If not providing significant account-based features, let people use the app without login.
- If you offer account creation, you **must** offer account deletion.

### 5.1.2 — Data Use and Sharing

**(i)** Cannot use, transmit, or share personal data without explicit permission. Must clearly disclose third-party sharing **including with third-party AI**. Must use App Tracking Transparency APIs for tracking.

**(ii)** Data collected for one purpose cannot be repurposed without further consent.

**(vi)** HealthKit data specifically **cannot** be used for marketing, advertising, or use-based data mining — including by third parties.

### Health Data Specific Rules (5.1.3)

- Health/fitness/medical data: **advertising and marketing use prohibited**
- Cannot share with third parties except for health management or health research (with permission)
- Cannot write false data into HealthKit
- Cannot store personal health info in iCloud
- Must disclose specific health data being collected

### App Privacy Labels

- All collected data must be listed in App Privacy labels on the App Store page.
- If the app uses third-party SDKs that collect user data, that must be declared.
- Labels must match actual app behavior — mismatches cause rejection.

### AI/ML Transparency (2025-2026 updates)

- If your app uses AI (e.g., AI calorie scanner, personalized fasting recommendations), you must explain how it works.
- Users must know when content is generated automatically.
- Explicit consent required before sharing personal data with third-party AI services.

---

## 7. Recent Policy Changes Affecting Health Apps (2025–2026)

### Spring 2026 — Medical Device Declaration
Starting spring 2026, apps in the **Medical or Health & Fitness** category can declare their regulatory status as a medical device in certain regions. This is a new metadata field in App Store Connect, not a mandatory classification — but fasting apps should be aware of it.

### April 2026 — SDK Requirement
All new submissions must use the **iOS 26 SDK** and be built with **Xcode 26** or later.

### July 2025 — New Age Rating System
Apple introduced new age rating categories: **13+, 16+, and 18+** (previously 4+, 9+, 12+, 17+). The updated questionnaire includes a specific question about **"Medical or Wellness Content."** Fitness/wellness content may push the rating to 13+ or 16+ if it includes medical advice. Developers must complete the updated questionnaire by **January 31, 2026**.

### November 2025 — AI Transparency Guidelines
Apple enforced updated AI transparency rules. Apps must:
- Clearly inform users if personal data is shared with third-party AI services.
- Secure explicit consent before sharing.
- Disclose when content is AI-generated.

### February 2026 — Latest Guideline Update
The most recent guideline update (Feb 6, 2026) moved advertising rules to 2.5.18, reinforcing that health/medical data from HealthKit cannot be used for targeted/behavioral advertising. Apps with ads must include the ability for users to report inappropriate ads.

### Late 2025 — Declared Age Range API
Apple introduced the Declared Age Range API to help developers implement age restrictions, particularly relevant for health apps that might not be appropriate for younger users.

### Ongoing — Stricter Privacy Enforcement
- Clearer privacy disclosures required in App Privacy labels.
- Stronger checks on automated/AI features.
- Transparent pricing and subscriptions enforced more rigorously.
- Repeated violations now face closer scrutiny on future submissions.

---

## 8. Medical Claims That Are NOT Allowed

### Prohibited Claims

Based on Guidelines 1.4.1, 1.1.6, and 2.3.1, the following types of claims are **not permitted**:

#### Diagnostic Claims
- ❌ "This app can diagnose [any medical condition]"
- ❌ "Detect diabetes/pre-diabetes through fasting patterns"
- ❌ "Identify metabolic disorders"
- ❌ Claims that the app can replace medical testing or lab work

#### Treatment/Cure Claims
- ❌ "Fasting cures/treats [disease]"
- ❌ "Reverse type 2 diabetes through intermittent fasting"
- ❌ "Cure inflammation/cancer/Alzheimer's through fasting"
- ❌ "Heal your gut" or any claim implying therapeutic outcomes
- ❌ "Clinically proven to [health outcome]" without verified clinical evidence

#### Measurement Claims Without Validation
- ❌ Claiming to measure blood glucose, blood pressure, blood oxygen, or body temperature using only device sensors
- ❌ "Accurate body composition analysis" from phone camera alone
- ❌ "Metabolic rate measurement" without validated methodology
- ❌ Any health measurement claim where methodology cannot be validated

#### False/Misleading Claims (Guideline 1.1.6)
- ❌ "Guaranteed weight loss"
- ❌ "Lose X pounds in Y days"
- ❌ Specific numerical health outcome guarantees
- ❌ Before/after claims implying guaranteed results
- ❌ Claims about "autophagy activation" presented as medical fact rather than research context

#### Unauthorized Medical Device Claims
- ❌ Presenting the app as a medical device without regulatory clearance
- ❌ Drug dosage recommendations (unless from approved entity per 1.4.2)
- ❌ Any claim that implies FDA (or equivalent) approval without actual clearance

### What IS Allowed (With Appropriate Framing)

- ✅ "Track your fasting hours" (tracking, not treatment)
- ✅ "Learn about intermittent fasting" (educational)
- ✅ "Research suggests..." (citing studies, clearly attributed)
- ✅ "Monitor your weight trends" (observation, not diagnosis)
- ✅ "Set and track health goals" (goal-setting tool)
- ✅ "Sync with Apple Health" (data integration)
- ✅ "Get personalized fasting schedules based on your preferences" (personalization, not medical prescription)
- ✅ "Fasting phase indicators based on general research" (with disclaimer that these are approximate and educational)

### Key Framing Principle

The line is between **tool/tracker/educational resource** and **medical device/diagnostic/treatment**. A fasting app should position itself as a wellness tool that helps users track and learn, not as a medical intervention that diagnoses or treats conditions. Every health-related statement should be framed as informational/educational, not prescriptive/therapeutic.

---

## Compliance Checklist for Fasting App Submission

### Pre-Submission

- [ ] Privacy policy accessible via URL in App Store Connect AND within the app
- [ ] Privacy policy explicitly covers: health data collected, how it's used, third-party sharing, retention/deletion, consent withdrawal
- [ ] App Privacy labels accurately reflect all data collection
- [ ] All HealthKit purpose strings are specific and descriptive
- [ ] HealthKit data requested only for types actually needed (data minimization)
- [ ] No health data used for advertising, marketing, or data mining
- [ ] No personal health data stored in iCloud
- [ ] Medical disclaimer present in onboarding, settings, and near health content
- [ ] "Consult a healthcare professional" reminder present
- [ ] No unsubstantiated medical/diagnostic/treatment claims in app or metadata
- [ ] Age rating questionnaire completed with medical/wellness content question answered correctly
- [ ] Account deletion offered if account creation exists
- [ ] Subscription pricing matches between metadata and in-app
- [ ] Subscription terms (renewal, cancellation, what's included) clearly presented before purchase
- [ ] Free trial terms clearly disclosed (duration, what happens after, charges)
- [ ] Demo account or demo mode provided for App Review
- [ ] Backend services live and accessible during review
- [ ] App tested on-device for crashes and stability
- [ ] All features described in metadata actually work in the app
- [ ] Screenshots show actual app in use (not just splash screens)
- [ ] Built with current Xcode/iOS SDK (iOS 26 SDK required from April 2026)
- [ ] AI features (if any) clearly disclosed with user consent for data sharing
- [ ] No HealthKit data used for ad targeting (Guideline 2.5.18)
- [ ] Review Notes explain HealthKit usage, subscription model, and any non-obvious features

---

## Sources

1. [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) — Last updated February 6, 2026
2. [Apple Health and Fitness Apps Developer Portal](https://developer.apple.com/health-fitness/)
3. [Apple HealthKit Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/healthkit)
4. [App Store Review Guideline Updates (Feb 2026)](https://developer.apple.com/news/?id=d75yllv4)
5. [iOS App Store Review Guidelines 2026 — The App Launchpad](https://theapplaunchpad.com/blog/app-store-review-guidelines)
6. [App Store Review Checklist 2025 — AppInstitute](https://appinstitute.com/app-store-review-checklist/)
7. [iOS App Store Requirements for Health Apps — Dash Solutions](https://blog.dashsdk.com/app-store-requirements-for-health-apps/)
8. [What You Can and Can't Do with HealthKit Data — The Momentum](https://www.themomentum.ai/blog/what-you-can-and-cant-do-with-apple-healthkit-data)
9. [App Store Rejection Reasons — AppFollow](https://appfollow.io/blog/app-store-review-guidelines)
10. [Apple Age Rating Update — ASO World](https://asoworld.com/blog/apple-app-store-age-rating-update-developer-guide/)
11. [Apple App Review Guidelines PDF (June 2025)](https://developer-mdn.apple.com/support/downloads/terms/app-review-guidelines/App-Review-Guidelines-20250609-English-UK.pdf)
