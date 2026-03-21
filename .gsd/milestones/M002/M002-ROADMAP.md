# M002: Lumifaste MVP Build

**Vision:** App Store'a submit edilebilir, çalışan bir fasting tracker. Timer, planlar, stages, history, IAP, notifications — hepsi çalışır durumda.

## Success Criteria

- Kullanıcı bir oruç başlatıp bitirebilir ve geçmişte görebilir
- Fasting stages (fat burning, ketosis, autophagy) gerçek zamanlı gösterilir
- Premium abonelik satın alınabilir ve restore edilebilir (StoreKit 2)
- Bildirimler oruç milestone'larında tetiklenir
- Uygulama dark mode'da düzgün çalışır
- App icon ve temel branding Gemini ile üretilmiş
- App Review compliance: disclaimer, privacy policy, legal

## Key Risks / Unknowns

- StoreKit 2 sandbox testing güvenilirliği — gerçek cihazda test gerekebilir
- SwiftData iOS 17 vs 18 davranış farkları — iOS 18+ hedeflenebilir
- Fasting stages zamanlama doğruluğu — bilimsel kaynaklara sadık kalmalı
- App Review health app red flags — wellness tool olarak pozisyonlama kritik

## Proof Strategy

- StoreKit 2 → S02'de retire: gerçek sandbox purchase + restore çalışır
- SwiftData → S01'de retire: oruç kaydedilir, history'den okunur, app restart'ta kaybolmaz
- Fasting stages → S01'de retire: timer ilerledikçe stage doğru geçişler yapar

## Verification Classes

- Contract verification: Xcode build succeeds, preview renders, StoreKit sandbox transactions
- Integration verification: Timer + SwiftData + Notifications birlikte çalışır
- Operational verification: App background'a gidip dönünce timer state doğru
- UAT / human verification: Gerçek cihazda oruç başlat → bitir → history'de gör → IAP satın al

## Milestone Definition of Done

This milestone is complete only when all are true:

- Tüm slice'lar tamamlanmış
- Xcode'da clean build, 0 warning
- Gerçek cihazda veya simulatörde tam akış çalışıyor
- StoreKit sandbox'ta purchase + restore çalışıyor
- App icon ve branding yerinde
- Privacy policy ve disclaimer mevcut
- App Store Connect'e upload edilebilir .ipa

## Requirement Coverage

- Covers: R001 (timer), R002 (plans), R003 (history), R005 (IAP), R006 (no ads), R007 (notifications), R010 (unique name)
- Partially covers: R008 (privacy — policy + disclaimer, full GDPR later)
- Leaves for later: R004 (HealthKit → v1.1), R009 (CloudKit → v2.0)
- Orphan risks: none

## Slices

- [ ] **S01: Core Timer + Data + Fasting Stages** `risk:high` `depends:[]`
  > After this: Kullanıcı oruç başlatır, circular timer ilerler, fasting stages gösterilir, oruç bitirilir ve SwiftData'da saklanır. App restart'ta geçmiş oruçlar görünür.
- [ ] **S02: IAP + Paywall + StoreKit 2** `risk:high` `depends:[S01]`
  > After this: Premium abonelik satın alınabilir, paywall gösterilir, restore çalışır, premium/free feature gate'leri aktif. Build ile IAP paralel — ayrılmaz.
- [ ] **S03: Onboarding + Plans + Settings** `risk:medium` `depends:[S01]`
  > After this: İlk açılışta onboarding akışı, plan seçimi (16:8, 18:6, 20:4, OMAD, 5:2, custom), ayarlar ekranı çalışır.
- [ ] **S04: Notifications + History Dashboard** `risk:medium` `depends:[S01,S02]`
  > After this: Oruç milestone'larında local notification, geçmiş oruçlar listesi, streak sayacı, temel istatistikler çalışır.
- [ ] **S05: Branding + App Icon + Dark Mode + Legal** `risk:low` `depends:[S01]`
  > After this: Gemini API ile üretilmiş app icon, tutarlı renk paleti, tam dark mode, privacy policy, health disclaimer yerinde.
- [ ] **S06: Integration + Polish + App Store Ready** `risk:low` `depends:[S01,S02,S03,S04,S05]`
  > After this: Tüm parçalar birleşik, full flow çalışır, App Store Connect'e yüklenebilir, screenshots hazır.

## Boundary Map

### S01 → S02

Produces:
- `FastingSession` SwiftData @Model (startDate, endDate, planType, isCompleted)
- `FastingManager` @Observable class (startFast, endFast, currentSession, elapsedTime)
- `FastingStage` enum (fed, earlyFasting, fatBurning, ketosis, autophagy)
- `FastingPlan` enum (sixteenEight, eighteenSix, twentyFour, omad, fiveTwo, custom)

Consumes:
- nothing (first slice)

### S01 → S03

Produces:
- `FastingPlan` enum ve `FastingManager` — onboarding plan seçimini buraya bağlar
- `ModelContainer` setup — Settings model eklenecek

### S01 → S04

Produces:
- `FastingSession` model — history query'leri bunun üzerine yapılır
- `FastingManager` — notification scheduling session state'ine bağlı

### S02 → S04

Produces:
- `SubscriptionManager` — premium gate kontrolü (premium insights kilidi)
- `EntitlementManager` — feature flag'ler

### S05 → S06

Produces:
- App icon asset catalog
- Color palette (ColorTheme)
- Privacy policy URL
- Health disclaimer text
