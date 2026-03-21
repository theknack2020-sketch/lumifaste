# M002 — MVP Build — Context

**Scope:** Lumifaste'in App Store'a submit edilebilir MVP'sini build etmek.

## Goals
- Çalışan fasting timer (circular, count-up, timestamp-based)
- 6 fasting plan desteği (16:8, 18:6, 20:4, OMAD, 5:2, custom)
- Fasting stages görselleştirmesi (bilimsel kaynaklara dayalı)
- Progress history ve streaks
- StoreKit 2 IAP (build ile paralel, asla ayrı)
- Local notifications (milestone + reminder)
- Onboarding akışı
- Dark mode
- App icon (Gemini API ile üretilecek)
- Privacy policy + health disclaimer
- TelemetryDeck analytics foundation

## Constraints
- iOS 17+ minimum (SwiftData stability)
- No ads — EVER
- IAP must ship with first build, not as separate task
- Health wellness tool positioning (not medical device)
- Gemini API (Nano Banana 2) for logo/icon generation
- On-device data only (no backend server)

## Key Technical Decisions (from M001 research)
- Timer: timestamp-based (persist start/end, compute from Date.now)
- Background: iOS izin vermiyor — notification + Live Activity (v2)
- SwiftData for persistence
- StoreKit 2 native (no RevenueCat for MVP)
- TelemetryDeck for analytics
- $39.99/yıl pricing, 7-day free trial
