# Codex Task: Phase 2 — Real Photo Picker & Camera

> **Prerequisite**: Phase 1 (SwiftData) harus sudah selesai.
> Baca `Prompt/codex_context.md` untuk full project context.

---

## Objective

Mengganti dummy photo picker dengan real implementation menggunakan **PhotosUI** (gallery) dan **custom camera view** (AVFoundation). User bisa ambil foto pakaian dari gallery atau kamera.

**Khusus camera**: tampilkan **overlay garis-garis (dashed line) berbentuk siluet pakaian** (T-shirt atau celana, sesuai kategori yang dipilih) sebagai panduan posisi saat memotret. Overlay ini HANYA sebagai guide visual — bukan untuk cropping.

Foto disimpan sebagai `Data` (compressed JPEG) ke `ClothingItem.imageData`.

> **Note**: Drag & zoom untuk fine-tune posisi ada di **Phase 3** (interactive preview setelah capture), BUKAN di camera view ini.

---

## Tasks

### 2.1 — Buat `PhotoPickerView.swift` di `WardFit/Components/`

Wrapper yang support 2 mode:
1. **Gallery** — menggunakan `PhotosUI.PhotosPicker` (SwiftUI native)
2. **Camera** — custom camera view menggunakan `AVFoundation` atau `UIImagePickerController` via `UIViewControllerRepresentable`, **dengan overlay siluet pakaian**

```swift
import SwiftUI
import PhotosUI

// Gallery picker using PhotosUI
struct GalleryPickerView: View {
    @Binding var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            // ... label
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }
}

// Camera picker using UIKit bridge
struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
```

### 2.2 — Update `AddItemSheetViewModel.swift`

```swift
final class AddItemSheetViewModel: ObservableObject {
    @Published var itemName = ""
    @Published var itemDescription = ""
    @Published var selectedCategory: ClothingCategory?
    @Published var selectedImage: UIImage?
    @Published var showGalleryPicker = false
    @Published var showCameraPicker = false

    var hasSelectedPhoto: Bool { selectedImage != nil }

    var canSave: Bool {
        selectedCategory != nil && selectedImage != nil
    }

    var compressedImageData: Data? {
        selectedImage?.jpegData(compressionQuality: 0.7)
    }

    func save(using appViewModel: WardrobeAppViewModel) {
        guard let category = selectedCategory else { return }

        let item = ClothingItem(
            itemName: itemName.isEmpty ? "\(category.rawValue) Item" : itemName,
            category: category.rawValue,
            imageData: compressedImageData,
            itemDescription: itemDescription.isEmpty ? nil : itemDescription
            // hue, saturation, brightness → set di Phase 3 (auto-extracted)
            // isccNbsName → set di Phase 4
        )

        appViewModel.addItem(item)
    }
}
```

### 2.3 — Update `AddItemSheet.swift`

Ganti dummy photo button dengan real picker:

- Tampilkan photo source selector (Gallery / Camera)
- Setelah foto dipilih, tampilkan thumbnail preview
- Tambahkan `itemDescription` TextField yang benar
- **Fix bug**: line 83 di `AddItemSheet.swift` saat ini bind `itemDescription` field ke `$viewModel.itemName` — harusnya bind ke `$viewModel.itemDescription`

```swift
// Photo Section
if let image = viewModel.selectedImage {
    Image(uiImage: image)
        .resizable()
        .scaledToFill()
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: WFRadius.md))
} else {
    HStack(spacing: WFSpacing.sm) {
        WFSecondaryButton(title: "Gallery", icon: "photo") {
            viewModel.showGalleryPicker = true
        }
        WFSecondaryButton(title: "Camera", icon: "camera") {
            viewModel.showCameraPicker = true
        }
    }
}
```

### 2.4 — Update `CheckItemViewModel.swift`

```swift
final class CheckItemViewModel: ObservableObject {
    @Published var selectedCategory: ClothingCategory?
    @Published var selectedImage: UIImage?
    @Published var showGalleryPicker = false
    @Published var showCameraPicker = false

    var hasSelectedPhoto: Bool { selectedImage != nil }

    var canFindMatch: Bool {
        hasSelectedPhoto && selectedCategory != nil
    }

    var compressedImageData: Data? {
        selectedImage?.jpegData(compressionQuality: 0.7)
    }
}
```

### 2.5 — Update `CheckItemScreen.swift` & `ClothingCardView.swift`

- Ganti dummy camera button dengan real picker buttons
- `ClothingCardView`: tampilkan real image dari `imageData`, fallback ke placeholder

---

## Acceptance Criteria

- [ ] User bisa pilih foto dari **gallery** (PhotosUI)
- [ ] User bisa ambil foto dari **camera**
- [ ] Camera menampilkan **dashed-line clothing silhouette overlay** sesuai kategori
- [ ] Overlay T-shirt untuk "Top", overlay celana untuk "Bottom"
- [ ] Overlay HANYA guide visual — tidak mempengaruhi foto yang diambil
- [ ] Foto ditampilkan sebagai **thumbnail preview**
- [ ] Foto disimpan sebagai `imageData` (JPEG Data) ke `ClothingItem`
- [ ] Camera picker meminta izin kamera (`NSCameraUsageDescription`)
- [ ] App tidak crash jika user cancel picker

## Constraints

- **PhotosUI.PhotosPicker** untuk gallery, **UIImagePickerController** untuk camera
- Camera overlay menggunakan `cameraOverlayView` property dari `UIImagePickerController`
- Overlay harus `isUserInteractionEnabled = false` agar tidak block camera controls
- Garis overlay: **dashed line** (8pt dash, 6pt gap), warna putih 70% opacity
- Compress JPEG quality **0.7**
- JANGAN resize terlalu kecil — detail needed for color extraction Phase 3
- `Info.plist` harus punya `NSCameraUsageDescription`
- Follow design system (WFColor, WFSpacing, WFRadius, WFType)
- **User harus pilih kategori SEBELUM buka camera** agar overlay tahu bentuk apa yang ditampilkan
