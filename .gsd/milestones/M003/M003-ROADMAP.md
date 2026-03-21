# M003: Polish & Launch

**Vision:** Lumifaste'i App Store'a yüklenmeye hazır hale getir — UI polish, simulatörde tam test, App Store metadata, ve submission.

## Success Criteria

- Uygulama simulatörde tam akışla çalışır (onboarding → timer → complete → history)
- App icon kusursuz (padding sorunu çözülmüş)
- App Store description, keywords, screenshots hazır
- Privacy policy sayfası hazır
- Build archive oluşturulabilir

## Key Risks / Unknowns

- App icon'da arka plan padding sorunu — saf kare icon gerekli
- App Store screenshot'ları simulatörden almanız gerekiyor
- Privacy policy URL gerekli (lumifaste.com henüz yok)

## Slices

- [ ] **S01: UI Polish + Bug Fixes** `risk:medium` `depends:[]`
  > After this: Tüm ekranlar görsel olarak polish edilmiş, animasyonlar smooth, edge case'ler handle edilmiş
- [x] **S02: App Store Metadata + ASO** `risk:low` `depends:[S01]`
  > After this: App Store description, keywords, subtitle, kategori hazır. Submission yapılabilir.
- [ ] **S03: Final Build + Archive** `risk:low` `depends:[S01,S02]`
  > After this: Clean archive build, App Store Connect'e upload edilmeye hazır
