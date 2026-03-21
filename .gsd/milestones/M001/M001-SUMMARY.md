# M001 — Devasa Araştırma — Summary

**Status:** Complete
**Date:** 2026-03-22
**Method:** 20 parallel research agents in 3 waves (8+8+4)

## Key Findings

### İsim Kararı
- **"Lumifaste" KULLANILMAYACAK** — Zen namespace App Store'da aşırı kalabalık
- **ÖNERİLEN: "Lumifaste"** — App Store'da boş, .com domain müsait, güçlü trademark potansiyeli
- Backup: Solfast, Fastique
- App Store Title: `Lumifaste — Fasting Tracker` (28 char)
- Subtitle: `Intermittent Fast Timer & Log` (30 char)

### Pazar
- IF app pazarı ~$0.43B (2024), $1B+ by 2033 (%8.4 CAGR)
- ABD pazar payı ~%40 → ~$120-200M
- Türkiye: $10-25M, Ramazan spike'ı ile dual-demand
- Sezonluk: Ocak (resolution), Nisan (Ramazan), Yaz (body)
- Kullanıcıların %50+'sı ABD'de IF denemiş

### Rakip Zayıflıkları (Top 3)
1. **Simple** — dark pattern subscription traps, sahte kilo kaybı vaatleri
2. **Zero** — $69.99/yıl price shock, bozuk free tier, upsell popup'lar oruç sırasında
3. **DoFasting** — iptal kabusları, zombie charges, yıllarca sonra fatura

### Kullanıcı Şikayetleri (#1-3)
1. "Çok fazla reklam" (dominant signal)
2. "Pahalı ve şeffaf olmayan abonelik"
3. "Basit timer istiyorum, bloated app değil"

### Monetizasyon Stratejisi
- Sweet spot: $39.99-49.99/yıl (Zero'nun yarısı)
- Cömert free tier (timer + basit history + stages temel)
- Premium: gelişmiş insights, HealthKit correlation, trends
- 7 gün free trial
- Conversion benchmark: %5-8 trial→paid

### Teknik Mimari Kararları
- Timer: Timestamp-based (persist startDate/endDate, compute from Date.now)
- Background: iOS background execution YOK — notification + Live Activity
- HealthKit: Fasting type yok, kendi verimizi SwiftData'da tut, HealthKit'ten weight/steps oku
- SwiftData + CloudKit: Otomatik sync, offline-first, last-writer-wins
- StoreKit 2: Native, RevenueCat'e gerek yok MVP için
- Analytics: TelemetryDeck (privacy-first, GDPR-safe, ATT gerektirmez)
- Live Activity: Text(timerInterval:) ile uygulamayı uyandırmadan countdown

### MVP Feature Set (11 özellik)
1. Core Fasting Timer (circular, count-up)
2. Fasting Plans (16:8, 18:6, 20:4, OMAD, 5:2, custom)
3. Fasting Stages Visualization
4. Progress History & Streaks
5. Onboarding Flow
6. **IAP / StoreKit 2** (build ile paralel, ASLA ayrı)
7. Push Notifications
8. Settings
9. Dark Mode
10. Privacy Policy & Legal
11. Basic Analytics (TelemetryDeck)

### MVP'de OLMAYACAKLAR (v1.1)
- HealthKit (v1.1)
- Widgets (v1.1)
- CloudKit Sync (v2.0)
- Educational Content (v1.1)
- Apple Watch (v2.0)

### App Review Compliance
- Wellness tracking tool olarak pozisyonla, tıbbi müdahale DEĞİL
- "Bu uygulama tıbbi tavsiye sağlamaz" disclaimer zorunlu
- HealthKit usage strings çok spesifik olmalı
- 30 maddelik compliance checklist hazır

### Privacy
- On-device SwiftData + CloudKit private DB = minimum compliance surface
- TelemetryDeck = ATT gerektirmez, GDPR consent gerektirmez
- App Privacy Label: minimal (Health & Fitness + Device ID analytics)
- HIPAA uygulanmaz (direct-to-consumer)

## Research Files (20)

| # | File | Topic |
|---|------|-------|
| 1 | competitor-matrix.md | Top 20 fasting app analizi |
| 2 | name-research.md | İsim araştırması ilk tarama |
| 3 | user-complaints.md | Kullanıcı şikayet analizi |
| 4 | market-size.md | Pazar büyüklüğü ve trendler |
| 5 | aso-research.md | App Store Optimization |
| 6 | monetization-research.md | Monetizasyon stratejisi |
| 7 | review-guidelines.md | App Review uyum |
| 8 | fasting-science.md | IF bilimi ve protokoller |
| 9 | timer-tech.md | SwiftUI timer mimarisi |
| 10 | healthkit-research.md | HealthKit entegrasyonu |
| 11 | storekit-research.md | StoreKit 2 implementasyon |
| 12 | data-sync-research.md | SwiftData + CloudKit |
| 13 | notification-research.md | Bildirim stratejisi |
| 14 | ux-benchmark.md | UI/UX benchmark |
| 15 | widget-research.md | Widget & Live Activity |
| 16 | privacy-research.md | Privacy & GDPR |
| 17 | feature-priority.md | Feature önceliklendirme |
| 18 | launch-strategy.md | Lansman stratejisi |
| 19 | opportunity-synthesis.md | Fırsat sentezi |
| 20 | final-naming.md | Final isim kararı |
