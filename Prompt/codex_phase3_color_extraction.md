# Codex Task: Phase 3 — Color Extraction (Scan Terkontrol)

> **Prerequisite**: Phase 2 (Photo Picker) sudah selesai.
> Baca `Prompt/codex_context.md` untuk full project context.

---

## Objective

Implementasi **interactive color extraction** dari foto pakaian. Ini adalah **langkah SETELAH foto diambil** (Phase 2 sudah menangani camera + gallery picker dengan dashed-line overlay sebagai guide).

### 2-Step Flow Keseluruhan:
1. **Camera/Gallery (Phase 2)**: User memotret pakaian dengan bantuan **dashed-line siluet overlay** sebagai panduan posisi
2. **Preview Interaktif (Phase 3 — ini)**: Setelah foto diambil, user masuk ke preview dimana:

Apa yang terjadi di preview:
1. Ada **scope overlay** berbentuk siluet pakaian (atasan/bawahan) sesuai kategori — area di luar scope di-dim
2. User bisa **drag** dan **pinch-to-zoom** foto untuk fine-tune posisi pakaian di dalam scope
3. Sistem **otomatis** mengambil warna dominan dari area scope — **BUKAN manual** (tidak ada tombol "Extract")
4. Setiap kali user adjust zoom/drag, ada **debounce ~500ms** lalu warna otomatis di-re-extract
5. Warna dominan diambil dengan **k-means clustering** — bukan pixel averaging — agar mendapat warna single yang paling dominan, bukan campuran warna

---

## Perbedaan dari Pendekatan Sebelumnya

| Aspek | Sebelumnya | Sekarang |
|-------|-----------|----------|
| **Scope shape** | Persegi generic | Siluet pakaian (T-shirt / celana) |
| **Image interaction** | Static preview | **Drag + pinch-to-zoom** |
| **Extraction trigger** | Manual button | **Auto + debounce 500ms** |
| **Algorithm** | Pixel averaging | **K-means clustering** → dominant color |
| **Color result** | Bisa campuran warna | **Single dominant color** |

---

## Tasks

### 3.1 — Buat `WardFit/Engine/ColorExtractor.swift`

Engine yang mengambil warna dominan dari area tertentu menggunakan **k-means clustering sederhana**.

```swift
import CoreImage
import UIKit

struct ExtractedColor: Equatable {
    let hue: Double        // 0...360
    let saturation: Double // 0...1
    let brightness: Double // 0...1

    var swiftUIColor: Color {
        Color(hue: hue / 360.0, saturation: saturation, brightness: brightness)
    }
}

enum ColorExtractor {

    /// Extract the single most dominant color from a specific region using k-means clustering.
    /// This avoids blending different colors together — instead picks the most frequent color.
    static func extractDominantColor(from image: UIImage, scopeRect: CGRect) -> ExtractedColor? {
        guard let cgImage = image.cgImage else { return nil }
        let imgW = CGFloat(cgImage.width), imgH = CGFloat(cgImage.height)

        // Convert normalized rect to pixel coords
        let cropRect = CGRect(
            x: scopeRect.origin.x * imgW,
            y: scopeRect.origin.y * imgH,
            width: scopeRect.width * imgW,
            height: scopeRect.height * imgH
        ).intersection(CGRect(x: 0, y: 0, width: imgW, height: imgH))

        guard !cropRect.isEmpty,
              let cropped = cgImage.cropping(to: cropRect) else { return nil }

        // Downscale to manageable size for clustering (e.g. 40x40 = 1600 pixels)
        let sampleSize = 40
        guard let ctx = CGContext(
            data: nil, width: sampleSize, height: sampleSize,
            bitsPerComponent: 8, bytesPerRow: sampleSize * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: sampleSize, height: sampleSize))
        guard let data = ctx.data else { return nil }
        let ptr = data.bindMemory(to: UInt8.self, capacity: sampleSize * sampleSize * 4)

        // Collect all pixel colors as (R, G, B) tuples
        var pixels: [(r: Double, g: Double, b: Double)] = []
        pixels.reserveCapacity(sampleSize * sampleSize)
        for i in 0..<(sampleSize * sampleSize) {
            let o = i * 4
            pixels.append((
                r: Double(ptr[o]) / 255.0,
                g: Double(ptr[o + 1]) / 255.0,
                b: Double(ptr[o + 2]) / 255.0
            ))
        }

        // K-means clustering with k=3 (find 3 color clusters, return largest)
        let dominant = kMeansDominant(pixels: pixels, k: 3, iterations: 10)

        // Convert RGB to HSB
        let uiColor = UIColor(red: dominant.r, green: dominant.g, blue: dominant.b, alpha: 1)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

        return ExtractedColor(
            hue: Double(h) * 360.0,
            saturation: Double(s),
            brightness: Double(b)
        )
    }

    // MARK: - Simple K-Means Clustering

    private static func kMeansDominant(
        pixels: [(r: Double, g: Double, b: Double)],
        k: Int,
        iterations: Int
    ) -> (r: Double, g: Double, b: Double) {
        guard !pixels.isEmpty else { return (0, 0, 0) }
        guard pixels.count >= k else { return pixels[0] }

        // Initialize centroids by picking evenly spaced pixels
        var centroids: [(r: Double, g: Double, b: Double)] = []
        let step = pixels.count / k
        for i in 0..<k {
            centroids.append(pixels[i * step])
        }

        var assignments = [Int](repeating: 0, count: pixels.count)

        for _ in 0..<iterations {
            // Assign each pixel to nearest centroid
            for (idx, px) in pixels.enumerated() {
                var bestDist = Double.greatestFiniteMagnitude
                var bestCluster = 0
                for (ci, c) in centroids.enumerated() {
                    let dist = (px.r - c.r) * (px.r - c.r)
                             + (px.g - c.g) * (px.g - c.g)
                             + (px.b - c.b) * (px.b - c.b)
                    if dist < bestDist {
                        bestDist = dist
                        bestCluster = ci
                    }
                }
                assignments[idx] = bestCluster
            }

            // Update centroids
            for ci in 0..<k {
                var sumR = 0.0, sumG = 0.0, sumB = 0.0, count = 0.0
                for (idx, px) in pixels.enumerated() {
                    if assignments[idx] == ci {
                        sumR += px.r; sumG += px.g; sumB += px.b; count += 1
                    }
                }
                if count > 0 {
                    centroids[ci] = (sumR / count, sumG / count, sumB / count)
                }
            }
        }

        // Find largest cluster
        var clusterSizes = [Int](repeating: 0, count: k)
        for a in assignments { clusterSizes[a] += 1 }
        let largestIdx = clusterSizes.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0

        return centroids[largestIdx]
    }
}
```

### 3.2 — Buat `WardFit/Components/ClothingScopeOverlay.swift`

Overlay dengan **siluet pakaian** sesuai kategori. Area di luar siluet di-dim.

```swift
import SwiftUI

struct ClothingScopeOverlay: View {
    let category: ClothingCategory  // .top atau .bottom

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                // Dimmed area di luar scope
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .mask {
                        Rectangle()
                            .overlay {
                                scopeShape(in: size)
                                    .blendMode(.destinationOut)
                            }
                    }

                // Border scope
                scopeShape(in: size)
                    .stroke(Color.white.opacity(0.8), lineWidth: 2)

                // Label
                VStack {
                    Spacer()
                    Text("Adjust clothing inside the outline")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.black.opacity(0.6)))
                        .padding(.bottom, 20)
                }
            }
        }
        .allowsHitTesting(false) // Let gestures pass through to image behind
    }

    /// Return a shape path based on category.
    /// For Top: simplified T-shirt silhouette.
    /// For Bottom: simplified pants silhouette.
    /// Both centered in the given size, occupying ~60% of the area.
    @ViewBuilder
    private func scopeShape(in size: CGSize) -> some Shape {
        // Implementasi: buat Path yang menggambar siluet sederhana
        // T-shirt: badan persegi + lengan pendek di kiri kanan + leher
        // Pants: 2 kaki + pinggang
        // Posisi centered, ukuran ~60% dari container
        //
        // Alternatif simpler: gunakan RoundedRectangle biasa
        // dengan aspect ratio yang sesuai kategori
        // Top: lebih landscape (4:3)
        // Bottom: lebih portrait (3:4)

        let w = size.width * 0.6
        let h = category == .top ? w * 0.75 : w * 1.1
        let x = (size.width - w) / 2
        let y = (size.height - h) / 2

        RoundedRectangle(cornerRadius: 16)
            .path(in: CGRect(x: x, y: y, width: w, height: h))
    }
}
```

> **Catatan untuk implementor**: Idealnya `scopeShape` menggambar siluet pakaian yang lebih realistis (Path custom). Jika terlalu kompleks, RoundedRectangle dengan aspect ratio berbeda per kategori sudah cukup. Yang penting user bisa visual melihat area scope.

### 3.3 — Buat `WardFit/Components/InteractiveImagePreview.swift`

View yang menampilkan foto dengan **drag + pinch-to-zoom**, overlay siluet, dan **auto color extraction dengan debounce**.

```swift
import SwiftUI
import Combine

struct InteractiveImagePreview: View {
    let image: UIImage
    let category: ClothingCategory
    @Binding var extractedColor: ExtractedColor?

    // Gesture state
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // Debounce
    @State private var debounceTask: Task<Void, Never>?

    // Scope rect (normalized) — derived from overlay shape
    // This represents the center ~60% area matching the overlay
    private var scopeRect: CGRect {
        // The overlay occupies center 60% width, height depends on category
        let w = 0.6
        let aspectRatio: Double = category == .top ? 0.75 : 1.1
        let h = w * aspectRatio
        let x = (1.0 - w) / 2
        let y = (1.0 - h) / 2
        return CGRect(x: x, y: y, width: w, height: h)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                Color.black

                // User's photo — interactive (drag + zoom)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(scale)
                    .offset(offset)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .gesture(dragGesture)
                    .gesture(magnificationGesture)

                // Clothing scope overlay (non-interactive)
                ClothingScopeOverlay(category: category)
            }
        }
        .frame(height: 350)
        .clipShape(RoundedRectangle(cornerRadius: WFRadius.lg))
        .onAppear { triggerExtraction() }
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                triggerDebouncedExtraction()
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = max(0.5, min(3.0, lastScale * value))
                triggerDebouncedExtraction()
            }
            .onEnded { _ in
                lastScale = scale
            }
    }

    // MARK: - Auto Extraction with Debounce

    private func triggerDebouncedExtraction() {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms debounce
            guard !Task.isCancelled else { return }
            await MainActor.run { triggerExtraction() }
        }
    }

    private func triggerExtraction() {
        // Adjust scope rect based on current scale and offset
        // The scope overlay is fixed on screen, so we need to calculate
        // which part of the actual image falls under the scope area,
        // taking into account the user's zoom and pan.
        let adjustedRect = adjustedScopeRect()
        extractedColor = ColorExtractor.extractDominantColor(
            from: image, scopeRect: adjustedRect
        )
    }

    /// Calculate which region of the original image is visible under the scope overlay,
    /// accounting for user zoom (scale) and pan (offset).
    private func adjustedScopeRect() -> CGRect {
        // Base scope rect (normalized to view)
        let sr = scopeRect

        // Invert the user's transformations to map screen-space scope to image-space
        // When user zooms in (scale > 1), the visible portion of image shrinks
        // When user drags right, the visible image shifts left
        let viewWidth: Double = 1.0  // normalized
        let viewHeight: Double = 1.0

        // Image visible area considering scale
        let visibleW = viewWidth / Double(scale)
        let visibleH = viewHeight / Double(scale)

        // Offset in normalized coords
        let offX = -Double(offset.width) / (350 * Double(scale)) // 350 = frame height
        let offY = -Double(offset.height) / (350 * Double(scale))

        // Center of visible area
        let centerX = 0.5 + offX
        let centerY = 0.5 + offY

        // Map scope rect to image space
        let imgX = centerX - visibleW / 2 + sr.origin.x * visibleW
        let imgY = centerY - visibleH / 2 + sr.origin.y * visibleH
        let imgW = sr.width * visibleW
        let imgH = sr.height * visibleH

        // Clamp to 0...1
        return CGRect(
            x: max(0, min(1 - imgW, imgX)),
            y: max(0, min(1 - imgH, imgY)),
            width: min(imgW, 1),
            height: min(imgH, 1)
        )
    }
}
```

### 3.4 — Integrate ke `AddItemSheetViewModel` & `CheckItemViewModel`

Tambahkan:

```swift
// Di kedua ViewModel:
@Published var extractedColor: ExtractedColor?
```

**TIDAK perlu** method `extractColor()` manual karena `InteractiveImagePreview` otomatis set `extractedColor` via binding.

### 3.5 — Update `AddItemSheet.swift`

Setelah foto dipilih DAN kategori dipilih, tampilkan `InteractiveImagePreview`:

```swift
if let image = viewModel.selectedImage, let category = viewModel.selectedCategory {
    VStack(spacing: WFSpacing.sm) {
        InteractiveImagePreview(
            image: image,
            category: category,
            extractedColor: $viewModel.extractedColor
        )

        // Live color swatch (auto-updated)
        if let color = viewModel.extractedColor {
            HStack(spacing: WFSpacing.sm) {
                Circle()
                    .fill(color.swiftUIColor)
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(WFColor.borderStrong, lineWidth: 1))

                Text("Detected Color")
                    .font(WFType.bodyMedium)
                    .foregroundStyle(WFColor.textPrimary)
            }
            .transition(.opacity)
            .animation(.easeOut(duration: 0.2), value: color)
        }
    }
}
```

HSB dari `extractedColor` di-pass ke `ClothingItem` saat save.

### 3.6 — Update `CheckItemScreen.swift`

Sama: setelah foto + kategori dipilih, tampilkan `InteractiveImagePreview` dengan auto-extraction.

---

## Acceptance Criteria

- [ ] Setelah foto dipilih, user melihat **interactive preview** dengan scope overlay
- [ ] Scope overlay berbentuk sesuai kategori (**atasan** atau **bawahan**)
- [ ] User bisa **drag** foto untuk reposisi
- [ ] User bisa **pinch-to-zoom** foto
- [ ] Warna **otomatis di-extract** saat pertama kali tampil
- [ ] Setelah drag/zoom, ada **debounce 500ms** lalu warna di-re-extract otomatis
- [ ] Color swatch **live update** di UI
- [ ] Warna dominan diambil via **k-means clustering** (bukan averaging)
- [ ] HSB tersimpan ke `ClothingItem` saat save

## Constraints

- Core Graphics saja, BUKAN Vision framework
- BUKAN image classification — hanya pixel color clustering
- K-means dengan **k=3** clusters, **10 iterasi** (cukup cepat untuk 40x40 sample)
- Debounce **500ms** setelah gesture berakhir
- Extraction harus **async** agar tidak block UI
- Scope overlay harus `allowsHitTesting(false)` agar gestures pass-through ke image
- Follow design system (WFColor, WFSpacing, WFRadius, WFType)
