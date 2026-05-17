# WardFit — Codex Master Context

> **Dokumen ini berisi context lengkap tentang project WardFit.**
> Copy-paste bagian yang relevan ke setiap Codex task, atau gunakan sebagai referensi utama.

---

## Project Overview

**WardFit** adalah aplikasi iOS standalone/offline yang membantu user mencocokkan warna outfit (atasan ↔ bawahan). App menggunakan **Apple-only frameworks** tanpa third-party dependency.

### Tech Stack
- **UI**: SwiftUI
- **Data**: SwiftData (migrasi dari mock data)
- **Image**: Core Image, PhotosUI, AVFoundation
- **Target**: iOS 17+
- **Language**: Swift
- **Architecture**: MVVM

---

## Prinsip & Batasan WAJIB

1. **Full offline** — TIDAK ADA network call, API, atau internet dependency
2. **No third-party library** — hanya Apple frameworks
3. **No image classification** — TIDAK menggunakan ML/AI untuk deteksi objek
4. **No skin tone / undertone** — fokus HANYA pada warna pakaian
5. **ISCC–NBS hanya untuk penamaan warna** — BUKAN untuk scoring/matching
6. **Scoring pakai HSB numerik** — Hue (0-360), Saturation (0-1), Brightness (0-1)
7. **Rekomendasi dari database** — matching hanya terhadap pakaian yang sudah disimpan user
8. **Pairs dihitung saat save** — setiap kali item disimpan, otomatis hitung pasangan terbaik dan persist ke database (bi-directional)

---

## Current Project Structure

```
WardFit/
├── WardFit.xcodeproj/
├── Prompt/
│   ├── prompt.md                    # Konsep & requirements
│   └── codex_context.md             # File ini
├── WardFit/
│   ├── WardFitApp.swift             # App entry point
│   ├── ContentView.swift            # Root TabView (Wardrobe, Saved Later, Search)
│   ├── Models/
│   │   └── MockModels.swift         # OutfitItem struct, MockData, ClothingCategory enum
│   ├── ViewModels/
│   │   ├── WardrobeAppViewModel.swift      # Main app state (mock arrays)
│   │   ├── WardrobeScreenViewModel.swift   # Filter, search, sheet state
│   │   ├── AddItemSheetViewModel.swift     # Add item form state (dummy photo)
│   │   ├── CheckItemViewModel.swift        # Check flow state (dummy photo)
│   │   └── MatchResultViewModel.swift      # Match results (mock matching)
│   ├── Screens/
│   │   ├── WardrobeScreen.swift            # Main wardrobe grid + stats
│   │   ├── AddItemSheet.swift              # Add item sheet (name, category, dummy photo)
│   │   ├── CheckItemScreen.swift           # Check new item flow
│   │   ├── MatchResultScreen.swift         # Match results display
│   │   ├── WardrobeItemDetailScreen.swift  # Item detail (has empty "Recommended Matches")
│   │   ├── SavedLaterScreen.swift          # Saved for later items
│   │   └── WardrobeSearchScreen.swift      # Search/browse wardrobe
│   ├── Components/
│   │   ├── ClothingCardView.swift          # WFWardrobeGridTile
│   │   ├── EmptyStateView.swift            # WFEmptyState
│   │   ├── WFCategorySelector.swift        # Top/Bottom selector
│   │   ├── WFPrimaryButton.swift           # Primary action button
│   │   ├── WFSecondaryButton.swift         # Secondary action button
│   │   └── WFSectionCard.swift             # Card container
│   ├── Theme/
│   │   └── WFTokens.swift                  # Design tokens (colors, spacing, typography)
│   └── Assets.xcassets/                    # Image assets (imageTShirt, imagePants)
```

---

## Current Data Model (MockModels.swift)

```swift
enum ClothingCategory: String, CaseIterable, Identifiable {
    case top = "Top"
    case bottom = "Bottom"
    
    var opposite: ClothingCategory {
        switch self {
        case .top: return .bottom
        case .bottom: return .top
        }
    }
}

struct OutfitItem: Identifiable {
    var id: UUID
    var itemName: String
    var itemImage: String          // asset name or system image
    var itemColor: Color           // SwiftUI Color
    var itemColorName: String      // hardcoded string like "Navy"
    var itemCategory: String       // "Top" or "Bottom"
    var itemDescription: String?
    var itemPairWith: [OutfitItem]? // currently always nil/empty
    var createdAt: Date
}
```

### Target Data Model (SwiftData)

```swift
@Model
final class ClothingItem {
    var id: UUID
    var itemName: String
    var category: String              // "Top" / "Bottom"
    var imageData: Data?              // compressed JPEG dari foto
    var itemDescription: String?
    
    // Warna numerik (untuk harmony scoring)
    var hue: Double                   // 0...360
    var saturation: Double            // 0...1
    var brightness: Double            // 0...1
    
    // Penamaan warna (untuk display)
    var isccNbsName: String           // e.g. "Vivid Blue", "Dark Olive"
    
    var createdAt: Date
    
    // Pre-computed pairs (bi-directional)
    var pairedItemIDs: [UUID]
}
```

---

## Design System (WFTokens.swift)

### Colors
```swift
enum WFColor {
    static let bg                // #F7F2EA — warm cream background
    static let bgAlt             // #EFE5D8 — subtle background
    static let surface           // #E7D8C7 — card surface
    static let surfaceAlt        // #DDCAB5 — secondary surface
    static let surfaceNested     // #D2BCA5 — input fields, nested cards
    static let textPrimary       // #35291F — dark brown
    static let textSecondary     // #695544 — medium brown
    static let textOnBrand       // #FAF5EF — light text on accent
    static let accentRose        // #7F644D — brand primary
    static let accentDenimSoft   // #7F644D — same as brand primary
    static let borderSoft        // #D7C3AE
    static let borderStrong      // #B79D84
    static let highlightWarm     // #AE8B6F
    static let highlightSoft     // #C2A88F
}
```

### Spacing
```swift
enum WFSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}
```

### Radius
```swift
enum WFRadius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 18
    static let pill: CGFloat = 999
}
```

### Typography
```swift
enum WFType {
    static let hero = Font.largeTitle.weight(.bold)
    static let title = Font.title3.weight(.semibold)
    static let body = Font.body
    static let bodyMedium = Font.body.weight(.medium)
    static let caption = Font.caption
}
```

---

## Current ViewModel Patterns

### WardrobeAppViewModel (main state holder)
```swift
final class WardrobeAppViewModel: ObservableObject {
    @Published var wardrobeItems: [MockWardrobeItem]
    @Published var savedLaterItems: [MockWardrobeItem]
    
    func addWardrobeItem(name: String, category: ClothingCategory)
    func addWardrobeItem(_ item: MockWardrobeItem)
    func saveLater(_ item: MockWardrobeItem)
}
```

### Screen ViewModels use @StateObject, AppViewModel passed as @ObservedObject
```swift
struct WardrobeScreen: View {
    @ObservedObject var appViewModel: WardrobeAppViewModel
    @StateObject private var viewModel = WardrobeScreenViewModel()
}
```

---

## Color Harmony Rules (5 Types)

Semua harmony dihitung berdasarkan **Hue** (0-360 derajat), dengan penalti dari **Saturation** dan **Brightness** difference.

| Harmony | Hue Relationship | Tolerance |
|---------|-----------------|-----------|
| **Monochromatic** | Same hue, vary sat/brightness | ±10° hue |
| **Analogous** | Adjacent hues | ±30° hue |
| **Complementary** | Opposite hue | 180° ± 15° |
| **Split Complementary** | Two adjacent to complement | 150° & 210° ± 15° |
| **Triadic** | Three evenly spaced | 120° & 240° ± 15° |

### Scoring Formula
```
hueDiff = minimum angular distance between source and candidate hue
hueScore = 1.0 - (hueDiff / toleranceMax)
satPenalty = abs(sourceSat - candidateSat) * 0.3
briPenalty = abs(sourceBri - candidateBri) * 0.2

rawScore = max(0, hueScore - satPenalty - briPenalty)
percentage = Int(rawScore * 100)
```

### Score Labels
```
80-100% → "Best Match"
60-79%  → "Good Match"
40-59%  → "Recommended"
0-39%   → "Possible" (not stored in pairs)
```

---

## ISCC–NBS Color Naming

ISCC–NBS (Inter-Society Color Council – National Bureau of Standards) adalah sistem penamaan warna standar dengan ~267 nama warna.

### Penggunaan
- Input: HSB values (hue, saturation, brightness)
- Output: nama warna string (e.g. "Vivid Blue", "Dark Olive Green", "Light Grayish Brown")
- HANYA untuk display/label — BUKAN untuk scoring

### Implementasi
- Buat lookup table dari HSB ranges ke nama ISCC-NBS
- Untuk setiap input HSB, cari entry terdekat
- Return nama warna sebagai String

---

## Save-Time Pair Computation Flow

Setiap kali item baru disimpan (dari Add Item ATAU Check New Item → Save):

```
1. Insert item baru ke SwiftData
2. Fetch semua item dari KATEGORI LAWAN
   - Jika item baru = Top → fetch semua Bottom
   - Jika item baru = Bottom → fetch semua Top
3. Untuk setiap kandidat, hitung harmony score via ColorHarmonyEngine
4. Filter: hanya simpan yang score >= 40%
5. Simpan UUID kandidat ke newItem.pairedItemIDs
6. BI-DIRECTIONAL: tambahkan newItem.id ke setiap kandidat.pairedItemIDs
7. Save ModelContext
```

### Delete Flow
```
1. Ambil deletedItem.pairedItemIDs
2. Untuk setiap paired item: hapus deletedItem.id dari pairedItemIDs mereka
3. Delete item dari database
4. Save ModelContext
```

### Edit Flow (jika warna berubah)
```
1. Hapus item lama dari semua paired items' pairedItemIDs
2. Kosongkan item.pairedItemIDs
3. Update warna baru (HSB + ISCC-NBS name)
4. Re-run pair computation (sama seperti Save flow step 2-7)
```

---

## Color Extraction Approach

### Interactive Preview
Setelah user mengambil foto dan memilih kategori, app menampilkan **interactive preview**:
- **Clothing silhouette overlay** — siluet pakaian (T-shirt atau celana) sesuai kategori, area luar di-dim
- **Drag & pinch-to-zoom** — user bisa reposisi dan zoom foto agar pakaian masuk ke scope
- **Auto extraction** — warna otomatis di-extract dari area scope (BUKAN tombol manual)
- **Debounce 500ms** — setelah user berhenti drag/zoom, warna di-re-extract otomatis

### K-Means Dominant Color (bukan averaging)
Warna dominan diambil dengan **k-means clustering** (k=3, 10 iterasi):
1. Crop image ke scope area
2. Downscale ke 40x40 (1600 pixels)
3. Cluster pixels ke 3 grup warna
4. Ambil cluster **terbesar** sebagai dominant color
5. Convert ke HSB

Ini menghindari blending warna berbeda — hasilnya selalu **single dominant color**.

---

## Files to Create (New)

| File | Path | Purpose |
|------|------|---------|
| `ClothingItem.swift` | `WardFit/Models/` | SwiftData @Model |
| `ColorHarmonyEngine.swift` | `WardFit/Engine/` | 5 harmony types + scoring |
| `ISCCNBSColorNamer.swift` | `WardFit/Engine/` | HSB → color name mapping |
| `ColorExtractor.swift` | `WardFit/Engine/` | K-means dominant color from image region |
| `PhotoPickerView.swift` | `WardFit/Components/` | PHPicker + Camera wrapper |
| `ClothingScopeOverlay.swift` | `WardFit/Components/` | Clothing silhouette overlay (top/bottom) |
| `InteractiveImagePreview.swift` | `WardFit/Components/` | Drag+zoom preview with auto color extraction |
| `EditItemSheet.swift` | `WardFit/Screens/` | Edit existing item |

## Files to Modify

| File | Changes |
|------|---------|
| `WardFitApp.swift` | Add `.modelContainer(for: ClothingItem.self)` |
| `WardrobeAppViewModel.swift` | SwiftData integration, call ColorHarmonyEngine on save, bi-directional pairs |
| `AddItemSheetViewModel.swift` | Real photo picker, auto color extraction via InteractiveImagePreview binding |
| `CheckItemViewModel.swift` | Real photo picker, auto color extraction via InteractiveImagePreview binding |
| `MatchResultViewModel.swift` | Use ColorHarmonyEngine instead of MockData |
| `AddItemSheet.swift` | Real photo, InteractiveImagePreview with clothing scope, live color swatch |
| `CheckItemScreen.swift` | Real camera/gallery, InteractiveImagePreview with clothing scope |
| `MatchResultScreen.swift` | Show harmony type, score label, percentage |
| `WardrobeItemDetailScreen.swift` | Edit/Delete buttons, show pre-computed recommended matches, real photo |
| `ClothingCardView.swift` | Real image thumbnail, color swatch, ISCC-NBS subtitle |
