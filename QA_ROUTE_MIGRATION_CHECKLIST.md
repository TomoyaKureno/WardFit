# WardFit Route Migration QA Checklist

Date: 2026-04-27
Scope: Wardrobe -> Scan -> Match Result routing migration and gallery picker stability

## Checklist

- [x] Wardrobe route no longer stores `ClothingItem` in `NavigationPath`
- [x] Wardrobe detail navigation uses identifier-based route (`UUID`)
- [x] Wardrobe -> Scan entry is coordinator-driven (`coordinator.push(.scanClothes)`)
- [x] Scan flow no longer uses local `showResult` boolean navigation
- [x] Scan result navigation is coordinator route-based (`ScanClothesRoute.result(candidateID:)`)
- [x] Route payload avoids storing SwiftData model in path
- [x] `ScanClothesCoordinator` compile errors resolved and wired to app structure
- [x] Gallery picker async loading has cancellation handling
- [x] Gallery picker normalizes picked image for stable rendering
- [x] `selectedItem` is reset after pick to support repeated selections
- [x] Build compiles successfully for iOS Simulator

## Commands Run

```bash
rtk xcodebuild -project "/Users/tomoya/Desktop/Tomo's Workspace/Mobile App/WardFit/WardFit.xcodeproj" -scheme "WardFit" -destination 'generic/platform=iOS Simulator' build
```

## Result Summary

- Build status: PASS
- Critical migration targets: PASS
- Remaining checks requiring manual simulator interaction:
  - Real device/simulator pick from Photos app interaction
  - End-to-end tap flow (Wardrobe -> Check New Item -> Find Match -> Result -> back)
