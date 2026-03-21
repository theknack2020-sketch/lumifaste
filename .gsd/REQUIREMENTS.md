# Requirements

This file is the explicit capability and coverage contract for the project.

## Active

### R001 — Core Fasting Timer
- Class: primary-user-loop
- Status: active
- Description: Kullanıcı oruç başlatıp bitirebilmeli, kalan süreyi görebilmeli
- Why it matters: Uygulamanın temel işlevi
- Source: user
- Primary owning slice: none yet
- Validation: unmapped

### R002 — Fasting Plans
- Class: core-capability
- Status: active
- Description: 16:8, 18:6, 20:4, OMAD, custom plan desteği
- Why it matters: Farklı oruç protokollerini desteklemek kullanıcı tabanını genişletir
- Source: research
- Primary owning slice: none yet
- Validation: unmapped

### R003 — Progress Tracking & History
- Class: primary-user-loop
- Status: active
- Description: Geçmiş oruçlar, streak, istatistikler görünür olmalı
- Why it matters: Kullanıcı motivasyonu ve retention
- Source: research
- Primary owning slice: none yet
- Validation: unmapped

### R004 — HealthKit Integration
- Class: integration
- Status: active
- Description: Kilo, activity verileri HealthKit'ten okunup gösterilmeli
- Why it matters: Apple ekosistem entegrasyonu, rakiplerden fark
- Source: inferred
- Primary owning slice: none yet
- Validation: unmapped

### R005 — IAP / Premium Subscription
- Class: core-capability
- Status: active
- Description: StoreKit 2 ile tek şeffaf abonelik, build ile paralel implemente
- Why it matters: Gelir modeli. Ayrı bırakılamaz.
- Source: user
- Primary owning slice: none yet
- Validation: unmapped

### R006 — No Ads Ever
- Class: constraint
- Status: active
- Description: Hiçbir reklam formatı (banner, interstitial, rewarded) olmayacak
- Why it matters: Projenin varlık sebebi ve rakiplerden temel fark
- Source: user
- Primary owning slice: none yet
- Validation: unmapped

### R007 — Push Notifications
- Class: core-capability
- Status: active
- Description: Oruç başlangıç/bitiş hatırlatmaları, motivasyon bildirimleri
- Why it matters: Engagement ve retention
- Source: research
- Primary owning slice: none yet
- Validation: unmapped

### R008 — Privacy-First Data
- Class: compliance/security
- Status: active
- Description: Sağlık verileri cihazda kalır, sunucuya gönderilmez
- Why it matters: GDPR, App Review, kullanıcı güveni
- Source: inferred
- Primary owning slice: none yet
- Validation: unmapped

### R009 — CloudKit Sync
- Class: continuity
- Status: active
- Description: Oruç geçmişi ve ayarlar iCloud ile cihazlar arası senkron
- Why it matters: Multi-device deneyim
- Source: inferred
- Primary owning slice: none yet
- Validation: unmapped

### R010 — Unique App Store Name
- Class: launchability
- Status: active
- Description: App Store'da aynı isimde uygulama olmayan benzersiz isim
- Why it matters: Trademark reddi ve App Review rejection riski
- Source: user
- Primary owning slice: M001
- Validation: unmapped
- Notes: M001 araştırma milestone'unda doğrulanacak

## Validated

(none yet)

## Deferred

(none yet)

## Out of Scope

### R030 — Social Features
- Class: anti-feature
- Status: out-of-scope
- Description: Arkadaş ekleme, liderboard, sosyal paylaşım
- Why it matters: MVP scope'u daraltır, sonra eklenebilir
- Source: inferred
- Validation: n/a

### R031 — Meal/Calorie Tracking
- Class: anti-feature
- Status: out-of-scope
- Description: Yemek/kalori takibi
- Why it matters: Fasting tracker, calorie tracker değil. Scope creep riski.
- Source: inferred
- Validation: n/a

## Traceability

| ID | Class | Status | Primary owner | Supporting | Proof |
|---|---|---|---|---|---|
| R001 | primary-user-loop | active | none yet | none | unmapped |
| R002 | core-capability | active | none yet | none | unmapped |
| R003 | primary-user-loop | active | none yet | none | unmapped |
| R004 | integration | active | none yet | none | unmapped |
| R005 | core-capability | active | none yet | none | unmapped |
| R006 | constraint | active | none yet | none | unmapped |
| R007 | core-capability | active | none yet | none | unmapped |
| R008 | compliance/security | active | none yet | none | unmapped |
| R009 | continuity | active | none yet | none | unmapped |
| R010 | launchability | active | M001 | none | unmapped |
| R030 | anti-feature | out-of-scope | none | none | n/a |
| R031 | anti-feature | out-of-scope | none | none | n/a |

## Coverage Summary

- Active requirements: 10
- Mapped to slices: 1
- Validated: 0
- Unmapped active requirements: 9
