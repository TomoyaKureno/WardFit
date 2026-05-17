# QA Checklist: Coordinator Migration

Date: 2026-04-27
Role: QA subagent
Scope: Wardrobe coordinator migration, ScanClothes flow routing, image picker/camera behavior, route payload safety.

## Build

- [x] `xcodebuild` completed for iOS Simulator using `WardFit` scheme and Debug configuration.
- [x] Build produced no blocking compiler errors.
- [x] Build produced only non-blocking asset catalog notices for legacy app icon slots.

Command used:

```bash
rtk xcodebuild -project WardFit.xcodeproj -scheme WardFit -configuration Debug -destination "generic/platform=iOS Simulator" build
```

## Wardrobe Flow

- [x] Wardrobe tab loads through `RootView` and receives the app-level `WardrobeCoordinator`.
- [x] `WardrobeView` owns a coordinator-backed `NavigationStack(path:)`.
- [x] Wardrobe item taps push `WardrobeRoute.wardrobeDetail(itemID:)` instead of passing a model through the route.
- [x] `WardrobeCoordinator` resolves detail items by `UUID` through `WardrobeAppViewModel`.
- [x] Recommended item taps inside detail push another `wardrobeDetail(itemID:)` route.
- [x] Wardrobe item detail hides the tab bar when pushed.

## Scan Entry And Flow

- [x] `Check New Item` pushes `WardrobeRoute.scanClothes` through `WardrobeCoordinator`.
- [x] `WardrobeCoordinator` builds scan entry through the app-owned `ScanClothesCoordinator`.
- [x] `ScanClothesFlowView` owns a nested `NavigationStack(path:)` for scan-specific routes.
- [x] `Find Match` builds a candidate and calls `ScanClothesCoordinator.showResult(for:)`.
- [x] Result navigation pushes `ScanClothesRoute.result(candidateID:)`.
- [x] `ScanClothesCoordinator` keeps the candidate object outside the `NavigationPath` and resolves it by ID for the result screen.
- [x] Scan capture and match result screens hide the tab bar when pushed.

## Saved Later Reuse

- [x] `RootView` creates one app-level `ScanClothesCoordinator`.
- [x] The same `ScanClothesCoordinator` is passed into `WardrobeCoordinator` and `SavedForLaterView`.
- [x] Saved Later `Back to Check` opens the scan flow through `scanCoordinator.makeRootView(...)`.

## Image Picker And Camera

- [x] Gallery picker is independent from camera availability and has no `.disabled(!cameraAvailable)` modifier.
- [x] Camera button is disabled only when `UIImagePickerController.isSourceTypeAvailable(.camera)` is false.
- [x] Gallery images are normalized with `normalizedForPreview(maxDimension: 2048)`.
- [x] Camera images are normalized with the same `normalizedForPreview(maxDimension: 2048)` path.
- [x] Picking an image updates `selectedImage`.
- [x] `ScanClothesViewModel` updates `selectedImageRenderID` whenever a non-nil selected image is set.
- [x] Scan preview applies `.id(viewModel.selectedImageRenderID)` so interactive preview state resets between picks.

## Route Payload Safety

- [x] `WardrobeRoute` uses only lightweight route payloads: `UUID` and route cases.
- [x] `ScanClothesRoute` uses only lightweight route payloads: `UUID` and route cases.
- [x] No `ClothingItem` SwiftData `@Model` object is stored in the coordinator-backed `NavigationPath` routes for Wardrobe detail or Scan result.

## Bugs

- [x] No blocking or functional bugs found in the requested QA scope.

## Residual Notes

- Manual QA was performed through static code-path inspection plus simulator build verification. No interactive simulator/photo-library session was run in this pass.
- Build logs include non-blocking asset catalog notices for older app icon idioms; these are outside the coordinator migration scope.
