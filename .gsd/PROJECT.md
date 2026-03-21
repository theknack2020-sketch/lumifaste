# Project

## What This Is

Lumifaste — reklamsız, şeffaf fiyatlı, kullanıcı dostu bir intermittent fasting (aralıklı oruç) takip uygulaması. iOS, SwiftUI + HealthKit. App Store'da mevcut rakiplerin "çok fazla reklam" ve "pahalı IAP" zayıflıklarını hedefleyen premium-first yaklaşım.

## Core Value

Reklamsız, güvenilir, basit bir oruç takip deneyimi. Timer başlar, timer biter, ilerleme görünür. Kullanıcı asla reklama maruz kalmaz.

## Current State

MVP tamamlanmış, App Store submission hazırlığı devam ediyor. Çalışan özellikler:
- Circular timer (count-up, timestamp-based)
- 6 fasting plan (12:12 → OMAD)
- Fasting stages görselleştirme (5 aşama)
- Progress history + streaks
- StoreKit 2 IAP (monthly $3.99, yearly $29.99)
- Paywall + restore purchases
- 4-sayfa onboarding
- Local notifications (milestone alerts)
- Settings + health disclaimer
- App icon (SF Symbol leaf.fill'den render)
- Dark mode ready
- Simulatörde çalışır durumda (iOS 18.2, iPhone 16)

## Architecture / Key Patterns

- **Platform:** iOS 17+
- **UI:** SwiftUI
- **Data:** SwiftData + CloudKit sync
- **Health:** HealthKit entegrasyonu (kilo, activity)
- **Monetization:** Freemium — cömert ücretsiz katman + tek şeffaf premium abonelik
- **IAP:** StoreKit 2 — build ile aynı anda gider, ayrı bırakılmaz
- **Analytics:** TelemetryDeck (privacy-first)
- **Ads:** YOK. Asla. Bu projenin varlık sebebi reklamsız olmak.

## Capability Contract

See `.gsd/REQUIREMENTS.md` for the explicit capability contract, requirement status, and coverage mapping.

## Milestone Sequence

- [x] M001: Devasa Araştırma — 20 agent ile pazar, teknik, tasarım, yasal, monetizasyon araştırması
- [ ] M002: MVP Build — Core timer, fasting planları, temel UI, HealthKit, IAP
- [ ] M003: Polish & Launch — ASO, App Store hazırlık, beta test, submit
