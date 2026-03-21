# S01: Core Timer + Data + Fasting Stages

**Goal:** Çalışan bir fasting timer: oruç başlat, circular progress ile izle, fasting stages gör, bitir, SwiftData'da sakla. App restart'ta state korunsun.
**Demo:** Kullanıcı oruç başlatır → circular timer count-up ile ilerler → fasting stage gösterilir (fed → early fasting → fat burning → ketosis → autophagy) → oruç bitirilir → history listesinde görünür → app kapatılıp açılınca aktif oruç ve geçmiş oruçlar kaybolmaz.

## Must-Haves

- Xcode projesi (XcodeGen + project.yml)
- Timestamp-based timer (persist startDate/endDate, compute from Date.now)
- SwiftData @Model: FastingSession
- FastingManager @Observable class
- Circular timer view (SwiftUI)
- Fasting stages enum + stage progression logic
- History list view
- Tab-based navigation (Timer, History)
- Dark mode ready (semantic colors)

## Proof Level

- This slice proves: integration (timer + data + UI birlikte çalışır)
- Real runtime required: yes (Simulator)
- Human/UAT required: yes (timer akışı görsel doğrulama)

## Verification

- `cd /Users/ufuk/IOS/Lumifaste && xcodegen generate && xcodebuild -scheme Lumifaste -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5` → BUILD SUCCEEDED
- Simulator'da: oruç başlat → timer ilerler → stage değişir → bitir → history'de görünür

## Tasks

- [ ] **T01: Xcode project scaffold + project.yml** `est:30m`
  - Why: XcodeGen ile proje yapısı — tüm dosyalar buraya bağlı
  - Files: `project.yml`, `Sources/App/LumifasteApp.swift`, `Sources/Resources/Info.plist`, `Sources/Resources/Assets.xcassets`
  - Do: project.yml oluştur (iOS 17+, SwiftUI, bundle id com.theknack.lumifaste), App entry point, Info.plist, Assets catalog. Sleepella pattern'ını takip et.
  - Verify: `xcodegen generate` başarılı
  - Done when: `Lumifaste.xcodeproj` oluşur ve Xcode'da açılabilir

- [ ] **T02: Data models + FastingManager** `est:45m`
  - Why: Timer state ve persistence — S01'in temeli
  - Files: `Sources/Models/FastingSession.swift`, `Sources/Models/FastingPlan.swift`, `Sources/Models/FastingStage.swift`, `Sources/Services/FastingManager.swift`
  - Do: FastingSession (@Model: id, startDate, endDate, planType, isCompleted, actualDuration), FastingPlan enum (sixteenEight, eighteenSix, twentyFour, omad, fiveTwo, custom), FastingStage enum (fed, earlyFasting, fatBurning, ketosis, autophagy) with hour thresholds, FastingManager @Observable (startFast, endFast, currentSession, elapsedTime, currentStage, fastHistory). Timestamp-based — asla tick counter kullanma.
  - Verify: Build succeeds, model compile eder
  - Done when: FastingManager oruç başlatıp bitirebilir, SwiftData'ya kaydeder

- [ ] **T03: Circular timer view** `est:45m`
  - Why: Ana ekran — kullanıcının gördüğü ilk şey
  - Files: `Sources/Views/Timer/TimerView.swift`, `Sources/Views/Timer/CircularProgressView.swift`, `Sources/Views/Timer/FastingStageView.swift`
  - Do: Circular progress ring (SwiftUI Canvas veya Circle + trim), ortada elapsed time (HH:MM:SS), altında current fasting stage badge, start/stop button. TimelineView ile 1 saniye güncelleme. Count-up timer (count-down değil — araştırma bunu öneriyor). Stage renkleri: fed=gray, earlyFasting=yellow, fatBurning=orange, ketosis=blue, autophagy=purple.
  - Verify: Preview render eder, timer tıklanınca başlar
  - Done when: Circular timer görsel olarak çalışır, stage geçişleri renk değişimi ile gösterilir

- [ ] **T04: History view + Tab navigation** `est:30m`
  - Why: Geçmiş oruçları göster, tab navigation ile timer/history arası geçiş
  - Files: `Sources/Views/History/HistoryView.swift`, `Sources/Views/History/FastingSessionRow.swift`, `Sources/Views/ContentView.swift`
  - Do: ContentView — TabView (Timer, History). HistoryView — SwiftData @Query ile geçmiş oruçlar, tarih sıralı. FastingSessionRow — tarih, süre, plan type, stage reached. Boş state mesajı.
  - Verify: Build succeeds, tab navigation çalışır
  - Done when: History'de tamamlanmış oruçlar listelenir, tab geçişi çalışır

- [ ] **T05: Theme + Colors + Polish** `est:20m`
  - Why: Semantic colors, tutarlı görünüm, dark mode hazırlık
  - Files: `Sources/Extensions/Color+Theme.swift`, `Sources/Resources/Assets.xcassets`
  - Do: Color+Theme extension ile semantic renkler (primary, secondary, timerBackground, stageColors), AccentColor asset, SF Symbols kullanımı. Dark mode'da düzgün görünüm.
  - Verify: Dark mode preview'da renkler okunabilir
  - Done when: Light ve dark mode'da tutarlı, okunabilir UI

- [ ] **T06: Build verification + clean compile** `est:15m`
  - Why: S01 tamamlandı — clean build + 0 warning
  - Files: tüm dosyalar
  - Do: xcodegen generate, xcodebuild clean build, warning'leri temizle, preview'ları test et
  - Verify: `xcodebuild -scheme Lumifaste -destination 'platform=iOS Simulator,name=iPhone 16' build` → BUILD SUCCEEDED
  - Done when: Clean build, 0 warning, timer akışı çalışır

## Files Likely Touched

- `project.yml`
- `Sources/App/LumifasteApp.swift`
- `Sources/Models/FastingSession.swift`
- `Sources/Models/FastingPlan.swift`
- `Sources/Models/FastingStage.swift`
- `Sources/Services/FastingManager.swift`
- `Sources/Views/Timer/TimerView.swift`
- `Sources/Views/Timer/CircularProgressView.swift`
- `Sources/Views/Timer/FastingStageView.swift`
- `Sources/Views/History/HistoryView.swift`
- `Sources/Views/History/FastingSessionRow.swift`
- `Sources/Views/ContentView.swift`
- `Sources/Extensions/Color+Theme.swift`
- `Sources/Resources/Info.plist`
- `Sources/Resources/Assets.xcassets`
