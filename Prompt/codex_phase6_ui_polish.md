# Codex Task: Phase 6 — UI Integration & Polish

> **Prerequisite**: Phase 1-5 sudah selesai.
> Baca `Prompt/codex_context.md` untuk full project context.

## Objective

Final integration: sambungkan semua engine ke UI, tambahkan Edit & Delete functionality, tampilkan pre-computed recommendations di detail screen, dan polish keseluruhan UX.

## Tasks

### 6.1 — Update `MatchResultScreen.swift`

Sekarang `MatchResultViewModel` mengembalikan `[HarmonyMatchResult]` (bukan `[MockMatchResult]`). Update UI:

- Tampilkan **harmony type** badge per result (e.g. "Complementary", "Analogous")
- Tampilkan **score label** ("Best Match", "Good Match", "Recommended")
- Optional: tampilkan **percentage** (e.g. "89%")
- Sort sudah descending dari engine
- Untuk setiap match result, fetch `ClothingItem` by `candidateID` dari database untuk tampilkan data

Contoh per-tile:
```swift
VStack(alignment: .leading, spacing: WFSpacing.xxs) {
    // Existing tile content...
    
    HStack(spacing: WFSpacing.xxs) {
        Text(match.harmonyType.rawValue)
            .font(WFType.caption)
            .foregroundStyle(WFColor.textSecondary)
        
        Spacer()
        
        Text(match.label)
            .font(.system(.caption2, design: .rounded).weight(.bold))
            .foregroundStyle(WFColor.textOnBrand)
            .padding(.horizontal, WFSpacing.xs)
            .padding(.vertical, 2)
            .background(Capsule().fill(WFColor.accentRose))
    }
}
```

### 6.2 — Update `WardrobeItemDetailScreen.swift` ⭐

Ini perubahan terpenting. Section "Recommended Matches" harus AKTIF:

**A) Tampilkan pre-computed recommendations:**
```swift
// Fetch paired items from database
private var recommendedMatches: [ClothingItem] {
    // Query ClothingItem where id IN item.pairedItemIDs
    // This needs ModelContext from environment
    // Or pass from appViewModel
}
```

Alternatif approach: tambahkan method di `WardrobeAppViewModel`:
```swift
func pairedItems(for item: ClothingItem) -> [ClothingItem] {
    wardrobeItems.filter { item.pairedItemIDs.contains($0.id) }
}
```

Lalu di view:
```swift
let recommendedMatches = appViewModel.pairedItems(for: item)

// Di "Recommended Matches" section:
if recommendedMatches.isEmpty {
    Text("No pairs found yet. Add more items to get recommendations.")
        .font(WFType.body)
        .foregroundStyle(WFColor.textSecondary)
} else {
    LazyVGrid(columns: gridColumns, spacing: WFSpacing.sm) {
        ForEach(recommendedMatches) { pairItem in
            NavigationLink {
                WardrobeItemDetailScreen(item: pairItem, appViewModel: appViewModel)
            } label: {
                WFWardrobeGridTile(item: pairItem)
            }
            .buttonStyle(.plain)
        }
    }
}
```

**B) Tambah Edit & Delete buttons:**
```swift
// Di bawah item detail, tambah action section:
WFSectionCard {
    Text("Actions")
        .font(WFType.title)
        .foregroundStyle(WFColor.textPrimary)
    
    VStack(spacing: WFSpacing.sm) {
        WFSecondaryButton(title: "Edit Item", icon: "pencil") {
            showEditSheet = true
        }
        
        Button {
            showDeleteConfirmation = true
        } label: {
            HStack(spacing: WFSpacing.xs) {
                Image(systemName: "trash")
                Text("Delete Item")
            }
            .font(WFType.bodyMedium)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                .fill(Color.red.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
.alert("Delete Item", isPresented: $showDeleteConfirmation) {
    Button("Cancel", role: .cancel) {}
    Button("Delete", role: .destructive) {
        appViewModel.deleteItem(item)
        dismiss()
    }
} message: {
    Text("Are you sure? This cannot be undone.")
}
```

**C) Tampilkan real photo:**
```swift
// Ganti placeholder image dengan:
if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
    Image(uiImage: uiImage)
        .resizable()
        .scaledToFill()
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: WFRadius.md))
} else {
    // existing placeholder
}
```

**D) Tampilkan ISCC-NBS color name + swatch:**
Di color detail row, tampilkan `item.isccNbsName` dan `item.displayColor` swatch.

### 6.3 — Buat `WardFit/Screens/EditItemSheet.swift`

Sheet untuk edit item yang sudah ada:

```swift
struct EditItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: ClothingItem
    let appViewModel: WardrobeAppViewModel
    
    @State private var itemName: String
    @State private var itemDescription: String
    @State private var selectedImage: UIImage?
    @State private var reExtractedColor: ExtractedColor?
    
    init(item: ClothingItem, appViewModel: WardrobeAppViewModel) {
        self.item = item
        self.appViewModel = appViewModel
        _itemName = State(initialValue: item.itemName)
        _itemDescription = State(initialValue: item.itemDescription ?? "")
        if let data = item.imageData {
            _selectedImage = State(initialValue: UIImage(data: data))
        }
    }
    
    var body: some View {
        NavigationStack {
            // Form with:
            // - Photo preview (option to re-pick)
            // - Item Name TextField
            // - Item Description TextField
            // - Current color swatch + ISCC-NBS name
            // - If re-picked photo: "Re-extract Color" button
        }
        .navigationTitle("Edit Item")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveChanges(); dismiss() }
            }
        }
    }
    
    private func saveChanges() {
        item.itemName = itemName
        item.itemDescription = itemDescription.isEmpty ? nil : itemDescription
        
        if let newImage = selectedImage, reExtractedColor != nil {
            item.imageData = newImage.jpegData(compressionQuality: 0.7)
        }
        
        if let newColor = reExtractedColor {
            // Warna berubah → re-compute pairs
            item.hue = newColor.hue
            item.saturation = newColor.saturation
            item.brightness = newColor.brightness
            item.isccNbsName = ISCCNBSColorNamer.name(
                hue: newColor.hue, saturation: newColor.saturation, brightness: newColor.brightness
            )
            appViewModel.recomputePairs(for: item)
        }
        
        appViewModel.updateItem(item)
    }
}
```

### 6.4 — Tambah `recomputePairs()` di `WardrobeAppViewModel`

```swift
func recomputePairs(for item: ClothingItem) {
    // 1. Hapus item ID dari semua paired items
    for pairedID in item.pairedItemIDs {
        if let paired = wardrobeItems.first(where: { $0.id == pairedID }) {
            paired.pairedItemIDs.removeAll { $0 == item.id }
        }
    }
    item.pairedItemIDs = []
    
    // 2. Re-run matching (same as addItem logic)
    let oppositeCategory = (item.category == "Top") ? "Bottom" : "Top"
    let candidates = wardrobeItems.filter { $0.category == oppositeCategory }
    let tuples = candidates.map { (id: $0.id, hue: $0.hue, sat: $0.saturation, bri: $0.brightness) }
    let matches = ColorHarmonyEngine.findMatches(
        sourceHue: item.hue, sourceSat: item.saturation, sourceBri: item.brightness,
        candidates: tuples
    )
    let good = matches.filter { $0.rawScore >= 0.4 }
    item.pairedItemIDs = good.map { $0.candidateID }
    
    for match in good {
        if let c = candidates.first(where: { $0.id == match.candidateID }),
           !c.pairedItemIDs.contains(item.id) {
            c.pairedItemIDs.append(item.id)
        }
    }
    
    try? modelContext.save()
}
```

### 6.5 — Update `ClothingCardView.swift` (`WFWardrobeGridTile`)

- Tampilkan **real photo** thumbnail dari `imageData`
- Tambahkan **color swatch** kecil (8x8 circle) di corner
- Tampilkan **ISCC-NBS name** sebagai subtitle di bawah category badge

```swift
// Di bawah category badge, tambah:
HStack(spacing: WFSpacing.xxs) {
    Circle()
        .fill(item.displayColor)
        .frame(width: 10, height: 10)
        .overlay(Circle().stroke(WFColor.borderStrong.opacity(0.4), lineWidth: 0.5))
    
    Text(item.isccNbsName)
        .font(.system(.caption2))
        .foregroundStyle(WFColor.textSecondary)
        .lineLimit(1)
}
```

### 6.6 — Cleanup: Remove Mock Dependencies

Setelah semua screen sudah menggunakan `ClothingItem`:
- Hapus penggunaan `MockData.resultCandidates()`, `MockData.wardrobeSeed`, dll
- Bisa keep `MockModels.swift` tapi tandai sebagai deprecated
- Pastikan `ClothingCategory` enum tetap tersedia (pindah ke file sendiri jika perlu)

## Acceptance Criteria

- [ ] `MatchResultScreen` menampilkan **harmony type** dan **score label** per match
- [ ] `WardrobeItemDetailScreen` menampilkan **pre-computed recommendations** (bukan kosong)
- [ ] User bisa **Edit item** (name, description, re-scan warna)
- [ ] Jika warna berubah saat edit → pairs **di-recompute**
- [ ] User bisa **Delete item** dengan konfirmasi → pairs di-cleanup
- [ ] Grid tiles menampilkan **real photo**, **color swatch**, **ISCC-NBS name**
- [ ] Detail screen menampilkan **real photo** dan **ISCC-NBS color info**
- [ ] App tidak crash, semua flow berjalan end-to-end
- [ ] Mock dependencies sudah tidak dipakai di production flow

## Constraints

- Follow existing design system: WFColor, WFSpacing, WFRadius, WFType
- Delete confirmation harus pakai `.alert` (bukan langsung hapus)
- Edit sheet pakai `.sheet` presentation
- Jangan ubah TabView structure di ContentView
- Pastikan NavigationStack tetap berfungsi (push/pop)
