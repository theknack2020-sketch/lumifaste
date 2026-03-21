# Project

## What This Is

Lumifaste — reklamsız, şeffaf fiyatlı, kullanıcı dostu bir intermittent fasting (aralıklı oruç) takip uygulaması. iOS, SwiftUI + HealthKit. App Store'da mevcut rakiplerin "çok fazla reklam" ve "pahalı IAP" zayıflıklarını hedefleyen premium-first yaklaşım.

## Core Value

Reklamsız, güvenilir, basit bir oruç takip deneyimi. Timer başlar, timer biter, ilerleme görünür. Kullanıcı asla reklama maruz kalmaz.

## Current State

Proje başlangıç aşamasında. Market araştırması (app-idea-finder taramalarından 5 taramada tutarlı 9/10 skor) tamamlanmış. GSD altyapısı kuruluyor, devasa araştırma milestone'u başlatılıyor.

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
