# Decisions Register

<!-- Append-only. Never edit or remove existing rows.
     To reverse a decision, add a new row that supersedes it.
     Read this file at the start of any planning or research phase. -->

| # | When | Scope | Decision | Choice | Rationale | Revisable? |
|---|------|-------|----------|--------|-----------|------------|
| D001 | 2026-03-22 | architecture | UI Framework | SwiftUI | Modern, declarative, iOS 17+ yeterli | No |
| D002 | 2026-03-22 | architecture | Data persistence | SwiftData + CloudKit | Native Apple stack, sync ücretsiz | Yes |
| D003 | 2026-03-22 | monetization | Revenue model | Freemium (no ads ever) + single subscription | Rakiplerin ana zayıflığı reklam — biz reklamsız gidiyoruz | No |
| D004 | 2026-03-22 | process | IAP timing | IAP build ile aynı anda | IAP ayrı bırakılırsa sonra entegre etmek zor ve riskli | No |
| D005 | 2026-03-22 | naming | App name | Lumifaste | App Store boş, .com müsait, güçlü trademark, lumi(light)+faste(fasting) | No |
| D006 | 2026-03-22 | design | Logo/asset generation tool | Google Gemini API — Nano Banana 2 (imagen-3.0) | Bedava, yüksek kalite image generation, API key mevcut | No |
