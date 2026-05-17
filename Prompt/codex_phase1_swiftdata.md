# Codex Task: Phase 1 — SwiftData Migration

> **Prerequisite**: Baca `Prompt/codex_context.md` untuk full project context.

---

## Objective

Migrasi data layer dari mock in-memory structs ke **SwiftData** persistent storage. Setelah phase ini selesai, semua data pakaian tersimpan di local database dan survive app restart.

---

## Tasks

### 1.1 — Buat `ClothingItem.swift` di `WardFit/Models/`

```swift
import SwiftData
import SwiftUI

@Model
final class ClothingItem {
    var id: UUID
    var itemName: String
    var category: String              // "Top" / "Bottom"
    var imageData: Data?              // compressed JPEG
    var itemDescription: String?
    
    // Warna numerik (untuk scoring)
    var hue: Double                   // 0...360
    var saturation: Double            // 0...1
    var brightness: Double            // 0...1
    
    // Penamaan warna (untuk display)
    var isccNbsName: String           // ISCC-NBS color name
    
    var createdAt: Date
    
    // Pre-computed pairs (bi-directional)
    var pairedItemIDs: [UUID]
    
    init(
        itemName: String,
        category: String,
        imageData: Data? = nil,
        itemDescription: String? = nil,
        hue: Double = 0,
        saturation: Double = 0,
        brightness: Double = 0,
        isccNbsName: String = "Unknown",
        createdAt: Date = .now,
        pairedItemIDs: [UUID] = []
    ) {
        self.id = UUID()
        self.itemName = itemName
        self.category = category
        self.imageData = imageData
        self.itemDescription = itemDescription
        self.hue = hue
        self.saturation = saturation
        self.brightness = brightness
        self.isccNbsName = isccNbsName
        self.createdAt = createdAt
        self.pairedItemIDs = pairedItemIDs
    }
}
```

Tambahkan juga computed properties yang berguna:

```swift
extension ClothingItem {
    var clothingCategory: ClothingCategory {
        ClothingCategory(rawValue: category) ?? .top
    }
    
    var displayColor: Color {
        Color(hue: hue / 360.0, saturation: saturation, brightness: brightness)
    }
    
    var resolvedImageName: String {
        if imageData != nil { return "" }  // akan pakai UIImage dari data
        return clothingCategory == .top ? "imageTShirt" : "imagePants"
    }
}
```

### 1.2 — Update `WardFitApp.swift`

```swift
import SwiftUI
import SwiftData

@main
struct WardFitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: ClothingItem.self)
    }
}
```

### 1.3 — Rewrite `WardrobeAppViewModel.swift`

Ganti dari mock arrays ke SwiftData. Inject `ModelContext` dari environment.

```swift
import SwiftUI
import SwiftData
import Combine

@Observable
final class WardrobeAppViewModel {
    private var modelContext: ModelContext
    
    var wardrobeItems: [ClothingItem] = []
    var savedLaterItems: [ClothingItem] = []  // keep in-memory for now
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchItems()
    }
    
    func fetchItems() {
        let descriptor = FetchDescriptor<ClothingItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        wardrobeItems = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func addItem(_ item: ClothingItem) {
        modelContext.insert(item)
        // TODO Phase 5: call ColorHarmonyEngine here for pair computation
        try? modelContext.save()
        fetchItems()
    }
    
    func deleteItem(_ item: ClothingItem) {
        // TODO Phase 5: cleanup pairedItemIDs from other items
        modelContext.delete(item)
        try? modelContext.save()
        fetchItems()
    }
    
    func updateItem(_ item: ClothingItem) {
        // SwiftData tracks changes automatically
        try? modelContext.save()
        fetchItems()
    }
    
    func saveLater(_ item: ClothingItem) {
        savedLaterItems.insert(item, at: 0)
    }
}
```

### 1.4 — Update `ContentView.swift`

Inject `ModelContext` dari environment ke `WardrobeAppViewModel`:

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var appViewModel: WardrobeAppViewModel?
    @State private var selectedTab: WFRootTab = .wardrobe

    var body: some View {
        Group {
            if let appViewModel {
                TabView(selection: $selectedTab) {
                    // ... existing tabs, pass appViewModel
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if appViewModel == nil {
                appViewModel = WardrobeAppViewModel(modelContext: modelContext)
            }
        }
    }
}
```

### 1.5 — Keep backward compatibility

- **DO NOT delete `MockModels.swift` yet** — keep it for reference
- Keep `ClothingCategory` enum di `MockModels.swift` (masih dipakai)
- Update semua screens secara bertahap untuk accept `ClothingItem` instead of `OutfitItem`/`MockWardrobeItem`
- Jika screen belum siap diubah, buat bridge extension:

```swift
extension ClothingItem {
    func toOutfitItem() -> OutfitItem {
        OutfitItem(
            id: id,
            itemName: itemName,
            itemImage: resolvedImageName,
            itemColor: displayColor,
            itemColorName: isccNbsName,
            itemCategory: category,
            itemDescription: itemDescription,
            createdAt: createdAt
        )
    }
}
```

### 1.6 — Update all Screens to use new ViewModel pattern

Setiap screen yang menerima `appViewModel` perlu di-update karena `WardrobeAppViewModel` sekarang `@Observable` bukan `ObservableObject`:
- Ganti `@ObservedObject var appViewModel` → parameter biasa (karena `@Observable`)
- Atau tetap pakai `@ObservedObject` + keep `ObservableObject` conformance

**Rekomendasi**: Gunakan `@Observable` macro (iOS 17+) agar lebih clean.

---

## Acceptance Criteria

- [ ] `ClothingItem` SwiftData model berhasil dibuat
- [ ] App tidak crash saat launch
- [ ] `.modelContainer` terpasang di `WardFitApp`
- [ ] `WardrobeAppViewModel` bisa CRUD ke SwiftData
- [ ] Data persist setelah app restart
- [ ] Semua existing screens tetap bisa render (tidak ada compile error)
- [ ] `MockModels.swift` masih ada untuk backward compat

---

## Constraints

- HANYA modifikasi files yang disebutkan di atas
- Jangan hapus `MockModels.swift`
- Jangan ubah design tokens di `WFTokens.swift`
- Jangan ubah component UI yang sudah ada (WFPrimaryButton, dll)
- Pastikan app tetap bisa di-build dan run setelah perubahan
