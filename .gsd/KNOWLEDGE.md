# Project Knowledge

Append-only register of project-specific rules, patterns, and lessons learned.
Agents read this before every unit. Add entries when you discover something worth remembering.

## Rules

| # | Scope | Rule | Why | Added |
|---|-------|------|-----|-------|
| K001 | monetization | ASLA reklam yok — banner, interstitial, rewarded hiçbiri | Projenin varlık sebebi reklamsız olmak. Rakip zayıflığı bu. | 2026-03-22 |
| K002 | build | IAP (StoreKit 2) her zaman build ile paralel gider | Ayrı bırakılırsa entegrasyon riski ve App Review reddi riski artar | 2026-03-22 |
| K003 | naming | App Store'da isim unique olmalı — aynı isimde uygulama varsa isim değişir | Trademark/rejection riski | 2026-03-22 |
| K004 | data | Kullanıcı sağlık verisi cihazda kalır, sunucuya gitmez | Privacy-first, App Review compliance, GDPR | 2026-03-22 |
| K005 | design | Logo ve görsel asset üretimi için Google Gemini API (Nano Banana 2 modeli) kullan — bedava, yüksek kalite | ~/.env'de GEMINI_API_KEY mevcut, imagen-3.0-generate-002 veya gemini-2.0-flash ile | 2026-03-22 |
| K006 | naming | App ismi: Lumifaste (onaylandı) — lumifaste.com domain alınacak | App Store boş, trademark güçlü, .com müsait | 2026-03-22 |
| K007 | monetization | Free: TÜM preset planlarla timer, stage isimleri, son 7 oruç, notifications. Premium: stage bilimi, sınırsız history, streak, fast report, custom plan | Zero/Fasted modeli — timer cömert, premium insights'ta. Güven kazanır, ağızdan ağıza yayılır | 2026-03-22 |
| K008 | monetization | Fast completion anı en güçlü conversion moment — kullanıcı başarmış, adrenalin yüksek | FastCompleteView'da premium teaser göster | 2026-03-22 |
| K009 | legal | Privacy/support/terms sayfaları GitHub Pages üzerinden serve ediliyor (docs/ klasörü) | theknack2020-sketch.github.io/lumifaste/ pattern'ı, Rolldark ile aynı | 2026-03-22 |

## Patterns

| # | Pattern | Where | Notes |
|---|---------|-------|-------|

## Lessons Learned

| # | What Happened | Root Cause | Fix | Scope |
|---|--------------|------------|-----|-------|
