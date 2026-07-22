# Lumifaste — Pricing & Market Decision

> Freshness: **2026-07-22** (valid ≤90 days per iOS pricing law). App 6760971357, v1.3.0 refresh.
> Evidence: live `asc apps public search` / `asc apps public view` (US), 2026-07-22.

---

## 1. Market diagnosis — why traffic collapsed

Downloads: **Apr 57 → May 34 → Jun 19 → Jul (2wk) 1**. Revenue $0. 2 trial starts (May NL,
Jun DE), 0 paid conversions, 0 ratings.

### Live search evidence (2026-07-22)

Scanned 8 terms with `asc apps public search --country us`. **Lumifaste ranks in the top 8 for
ZERO terms except its own brand name** — including terms that sit in its keyword field:

| Search term | #1 result | #1 rating count | Lumifaste rank |
|---|---|---|---|
| `autophagy timer` | Fastual: **Autophagy Timer** | **0** | not in top 8 |
| `fasting stages` | **Fasting Stages** Tracker | **0** | not in top 8 |
| `omad fasting` | Zero (#2 DeepFast: **OMAD** Fasting Timer) | 1 | not in top 8 |
| `fasting timer widget` | Fastic (#2 **Fasting Timer**: Track & Widget) | 2 | not in top 8 |
| `16:8 fasting` | Leap IF Tracker (#5 IF: **16:8**) | 2649 | not in top 8 |
| `fasting stages` | Fasting Stages Tracker | 0 | not in top 8 |
| `lock screen fasting timer` | Opal | — | not in top 8 |
| `intermittent fasting` | Zero 445k / Fastic 246k / BodyFast 144k | — | not in top 8 |

### Root cause

The one property every winner shares: **the search term appears in the app name**. Brand-new,
0-rating rivals (Fastual, Fasting Stages Tracker, DeepFast OMAD Timer, Fasting Timer: Track &
Widget) rank **#1–#2** on their long-tail terms purely because the exact phrase is in their
title. Lumifaste carries those same terms (`autophagy`, `OMAD`, `ketosis`, `16:8`, `widget`) in
its **keyword field** — and ranks nowhere. Even "Stages", which is in the current subtitle, does
not rank for "fasting stages" because the subtitle reads "…Smart Timer · Stages", not the exact
two-word phrase.

**Conclusion:** For a 0-rating app in an ultra-saturated category, the keyword field buys no
ranking. Only the **exact long-tail phrase, placed in the app Name or Subtitle**, does. April's
traffic was a launch/update freshness bonus; when it faded there were no earned rankings beneath
it, so July ≈ 0 is the app's true organic floor.

### How this binds decisions

- **ASO (Faz 4):** abandon unwinnable head terms; move exact long-tail phrases into Name +
  Subtitle. New Name `Lumifaste: Fasting Stage Timer`, Subtitle `Autophagy Timer, Lock Screen` —
  both target terms where the current #1 has 0 ratings, i.e. *winnable by title match alone*.
- **Ratings flywheel:** 0 ratings is both a ranking anchor and a conversion drag. Ship the honest
  review pre-prompt (Faz 2) so the first organic installs start the ratings flow.
- **Signature feature (4.3(a) differentiation):** Live Activity + Dynamic Island is a genuine
  moat — **no top-15 competitor mentions Live Activity / Dynamic Island / widget in its
  description** (verified: Zero's description has none of those tokens). Push it to Name/Subtitle,
  onboarding, and screenshot panel 1.

### Trial 0/2 verdict

n=2 is statistically meaningless — this is a **traffic** problem, not a price problem. The two
structural trial defects (paywall fires at onboarding end before value is delivered; SoftPaywall
promised "Start 7-Day Free Trial" regardless of eligibility) are fixed in Faz 2 regardless.

---

## 1b. Job classification

**Job: recurring habit/tracking companion** (daily-use lifestyle tracker), not a one-shot
utility or a professional instrument. The four-job frame → this is the *habit* archetype: value
compounds with continued use (streaks, history, stage science over time), which is exactly why
the whole category monetizes on **subscription**, not a one-time unlock. That classification
drives the structure below (weekly/monthly/yearly recurring access), and rules out lifetime/
one-time as the primary model.

---

## 2. Competitor pricing scan (live, 2026-07-22)

| App | Base price | Rating | Ratings | Model |
|---|---|---|---|---|
| Zero: Fasting & Food Tracker | Free | 4.82 | 445,286 | Freemium subscription |
| Simple: AI Weight Loss Coach | Free | 4.69 | 388,176 | Freemium subscription |
| Fastic Weight Loss & Fasting | Free | 4.80 | 246,126 | Freemium subscription |
| BodyFast: Intermittent Fasting | Free | 4.71 | 144,648 | Freemium subscription |
| FastEasy: Intermittent Fasting | Free | 4.65 | 78,879 | Freemium subscription |

Every category leader is **Free base + subscription** — identical to Lumifaste. Exact IAP prices
are not exposed by the public App Store API, but the well-documented market band for these apps'
annual plans is roughly **$60–$100/yr** (Zero Plus ~$70/yr, Fastic ~$90/yr, Simple ~$60/yr).
Lumifaste's $29.99/yr sits **well below** the leaders — already an aggressive value position, not
a barrier.

---

## 3. Pricing decision — v1.3.0

**KEEP the current structure.** No change.

| Product | ID | Price | Trial | State |
|---|---|---|---|---|
| Monthly Premium | 6760971120 | $3.99/mo | 7-day free | APPROVED |
| Yearly Premium | 6760971401 | $29.99/yr (save 37%) | 7-day free | APPROVED |

**Why these two tiers, and not the others:** monthly + yearly is the market-standard recurring
pair for the habit archetype (every named leader runs exactly this). **No weekly** — the leaders
that push weekly ($2.99–$4.99/wk burst pricing: FastEasy-style funnels) are funded UA machines
recouping ad spend fast; an indie honest-brand app pricing weekly reads as predatory and churns.
**No lifetime / one-time** — value compounds with continued use (job classification above), so a
one-time unlock underprices the ongoing product and is off-archetype for the category. **No
3/6-month** — redundant between monthly and yearly, adds paywall clutter with no evidence of
demand. The 7-day trial is the category default and lowers first-purchase friction.

**Rationale for the levels:**
1. Zero conversions are caused by **zero traffic**, not price — fixing price cannot help an app
   nobody sees.
2. $29.99/yr already undercuts every category leader ($60–$100/yr) by 2–3×; there is no room or
   reason to cut further, and raising it would weaken the honest-value positioning that is the
   brand's differentiator.
3. Both products are APPROVED and healthy — churning prices would force re-review with no upside.

## 4. Monitoring thresholds (derived, not copied)

Baseline = this app's own funnel, currently ~0 (no traffic). Triggers, keyed to Lumifaste's
funnel + the category's rating velocity:
- **Step-back (price too high / value unclear):** trial→paid conversion **< 5% over 4 weeks**
  once trial volume is real (n ≥ 20 starts) → run a PPO paywall/price experiment one rung down.
- **Step-up (underpriced):** **≥ 25 ratings at ≥ 4.5★** AND yearly attach > 60% of purchases →
  evaluate $34.99/yr. (Non-consumable-style price changes never affect existing subscribers'
  locked rate; repricing is low-risk.)
- **Do nothing until there is a funnel.** n = 2 trials today is noise; the ASO fix must restore
  traffic first (re-scan the 8 diagnostic terms in ~2–3 weeks).

## 5. Apply checklist

- [x] Territory availability — both products live in 175 territories (unchanged this release).
- [x] Price-point equalization — existing APPROVED schedules retained; no new price schedule.
- [x] `.storekit` sync — `Products.storekit` matches ASC product IDs (monthly/yearly), no drift.
- [x] Hardcoded-price grep — description + paywall show "$3.99/mo · $29.99/yr"; verified against
      ASC (`subscriptions_list`). No stray hardcoded prices elsewhere (`grep 3.99|29.99`).
- [x] Submit completeness — both subscriptions APPROVED (not pending); paywall ↔ product 1:1;
      this is an app-version update, not a version-only-with-unsubmitted-products submit.

---

## 6. Sources
- `asc apps public search --term "<t>" --country us` (8 terms), 2026-07-22
- `asc apps public view --app <id> --country us` (Zero, Fastic, BodyFast, FastEasy, Simple,
  Lumifaste), 2026-07-22
