# Codex Task: Phase 4 — ISCC–NBS Color Naming

> **Prerequisite**: Phase 3 (Color Extraction) sudah selesai.
> Baca `Prompt/codex_context.md` untuk full project context.

## Objective

Implementasi ISCC–NBS color naming system. Mapping dari HSB numerik ke nama warna standar (e.g. "Vivid Blue", "Dark Olive Green"). ISCC-NBS HANYA untuk penamaan display, BUKAN untuk scoring.

## Tasks

### 4.1 — Buat `WardFit/Engine/ISCCNBSColorNamer.swift`

Buat lookup table yang memetakan range HSB ke nama warna ISCC-NBS. Gunakan subset ~30-50 nama warna yang paling umum untuk pakaian (tidak perlu lengkap 267 entry).

```swift
import Foundation

struct ISCCNBSEntry {
    let name: String
    let hueRange: ClosedRange<Double>   // 0...360
    let satRange: ClosedRange<Double>   // 0...1
    let briRange: ClosedRange<Double>   // 0...1
}

enum ISCCNBSColorNamer {

    static let entries: [ISCCNBSEntry] = [
        // Achromatic (low saturation)
        ISCCNBSEntry(name: "White",         hueRange: 0...360, satRange: 0...0.05,  briRange: 0.90...1.0),
        ISCCNBSEntry(name: "Light Gray",    hueRange: 0...360, satRange: 0...0.05,  briRange: 0.65...0.90),
        ISCCNBSEntry(name: "Medium Gray",   hueRange: 0...360, satRange: 0...0.05,  briRange: 0.40...0.65),
        ISCCNBSEntry(name: "Dark Gray",     hueRange: 0...360, satRange: 0...0.05,  briRange: 0.15...0.40),
        ISCCNBSEntry(name: "Black",         hueRange: 0...360, satRange: 0...0.10,  briRange: 0...0.15),

        // Reds (hue 0-15, 345-360)
        ISCCNBSEntry(name: "Vivid Red",       hueRange: 345...360, satRange: 0.7...1.0, briRange: 0.5...1.0),
        ISCCNBSEntry(name: "Vivid Red",       hueRange: 0...15,    satRange: 0.7...1.0, briRange: 0.5...1.0),
        ISCCNBSEntry(name: "Dark Red",        hueRange: 345...360, satRange: 0.4...1.0, briRange: 0.15...0.5),
        ISCCNBSEntry(name: "Dark Red",        hueRange: 0...15,    satRange: 0.4...1.0, briRange: 0.15...0.5),
        ISCCNBSEntry(name: "Light Pink",      hueRange: 345...360, satRange: 0.1...0.4, briRange: 0.7...1.0),
        ISCCNBSEntry(name: "Light Pink",      hueRange: 0...15,    satRange: 0.1...0.4, briRange: 0.7...1.0),

        // Oranges (hue 15-45)
        ISCCNBSEntry(name: "Vivid Orange",    hueRange: 15...45,  satRange: 0.7...1.0, briRange: 0.6...1.0),
        ISCCNBSEntry(name: "Deep Orange",     hueRange: 15...45,  satRange: 0.5...1.0, briRange: 0.3...0.6),
        ISCCNBSEntry(name: "Light Orange",    hueRange: 15...45,  satRange: 0.2...0.5, briRange: 0.7...1.0),

        // Yellows (hue 45-70)
        ISCCNBSEntry(name: "Vivid Yellow",    hueRange: 45...70,  satRange: 0.6...1.0, briRange: 0.7...1.0),
        ISCCNBSEntry(name: "Dark Yellow",     hueRange: 45...70,  satRange: 0.4...1.0, briRange: 0.3...0.7),
        ISCCNBSEntry(name: "Pale Yellow",     hueRange: 45...70,  satRange: 0.1...0.4, briRange: 0.8...1.0),

        // Yellow-Greens (hue 70-100)
        ISCCNBSEntry(name: "Yellow Green",    hueRange: 70...100, satRange: 0.4...1.0, briRange: 0.4...1.0),
        ISCCNBSEntry(name: "Olive",           hueRange: 70...100, satRange: 0.2...0.6, briRange: 0.2...0.5),

        // Greens (hue 100-160)
        ISCCNBSEntry(name: "Vivid Green",     hueRange: 100...160, satRange: 0.6...1.0, briRange: 0.5...1.0),
        ISCCNBSEntry(name: "Dark Green",      hueRange: 100...160, satRange: 0.3...1.0, briRange: 0.1...0.5),
        ISCCNBSEntry(name: "Light Green",     hueRange: 100...160, satRange: 0.1...0.4, briRange: 0.7...1.0),

        // Blue-Greens / Teal (hue 160-200)
        ISCCNBSEntry(name: "Vivid Teal",      hueRange: 160...200, satRange: 0.5...1.0, briRange: 0.4...1.0),
        ISCCNBSEntry(name: "Dark Teal",       hueRange: 160...200, satRange: 0.3...1.0, briRange: 0.1...0.4),

        // Blues (hue 200-260)
        ISCCNBSEntry(name: "Vivid Blue",      hueRange: 200...260, satRange: 0.6...1.0, briRange: 0.5...1.0),
        ISCCNBSEntry(name: "Dark Blue",       hueRange: 200...260, satRange: 0.4...1.0, briRange: 0.1...0.5),
        ISCCNBSEntry(name: "Light Blue",      hueRange: 200...260, satRange: 0.1...0.5, briRange: 0.7...1.0),
        ISCCNBSEntry(name: "Navy",            hueRange: 220...250, satRange: 0.5...1.0, briRange: 0.1...0.35),

        // Purples (hue 260-300)
        ISCCNBSEntry(name: "Vivid Purple",    hueRange: 260...300, satRange: 0.5...1.0, briRange: 0.4...1.0),
        ISCCNBSEntry(name: "Dark Purple",     hueRange: 260...300, satRange: 0.3...1.0, briRange: 0.1...0.4),
        ISCCNBSEntry(name: "Light Purple",    hueRange: 260...300, satRange: 0.1...0.4, briRange: 0.7...1.0),

        // Pinks / Magentas (hue 300-345)
        ISCCNBSEntry(name: "Vivid Magenta",   hueRange: 300...345, satRange: 0.5...1.0, briRange: 0.5...1.0),
        ISCCNBSEntry(name: "Deep Magenta",    hueRange: 300...345, satRange: 0.4...1.0, briRange: 0.15...0.5),
        ISCCNBSEntry(name: "Light Pink",      hueRange: 300...345, satRange: 0.1...0.4, briRange: 0.7...1.0),

        // Browns (low-mid sat, warm hues)
        ISCCNBSEntry(name: "Light Brown",     hueRange: 15...45,  satRange: 0.3...0.7, briRange: 0.4...0.65),
        ISCCNBSEntry(name: "Dark Brown",      hueRange: 15...45,  satRange: 0.3...0.8, briRange: 0.1...0.4),
        ISCCNBSEntry(name: "Cream",           hueRange: 30...60,  satRange: 0.1...0.3, briRange: 0.85...1.0),
        ISCCNBSEntry(name: "Beige",           hueRange: 30...50,  satRange: 0.1...0.3, briRange: 0.7...0.85),
        ISCCNBSEntry(name: "Khaki",           hueRange: 40...55,  satRange: 0.2...0.5, briRange: 0.5...0.75),
    ]

    static func name(hue: Double, saturation: Double, brightness: Double) -> String {
        // Find exact match first
        for entry in entries {
            if entry.hueRange.contains(hue) &&
               entry.satRange.contains(saturation) &&
               entry.briRange.contains(brightness) {
                return entry.name
            }
        }
        // Fallback: find nearest by distance
        return nearestName(hue: hue, saturation: saturation, brightness: brightness)
    }

    private static func nearestName(hue: Double, saturation: Double, brightness: Double) -> String {
        var bestName = "Unknown"
        var bestDist = Double.greatestFiniteMagnitude
        for entry in entries {
            let hMid = (entry.hueRange.lowerBound + entry.hueRange.upperBound) / 2
            let sMid = (entry.satRange.lowerBound + entry.satRange.upperBound) / 2
            let bMid = (entry.briRange.lowerBound + entry.briRange.upperBound) / 2
            let hDiff = min(abs(hue - hMid), 360 - abs(hue - hMid)) / 180.0
            let dist = hDiff * hDiff + (saturation - sMid) * (saturation - sMid) + (brightness - bMid) * (brightness - bMid)
            if dist < bestDist { bestDist = dist; bestName = entry.name }
        }
        return bestName
    }
}
```

### 4.2 — Integrate ke save flow

Di `AddItemSheetViewModel.save()` dan di `WardrobeAppViewModel.addItem()`:
- Setelah color extraction menghasilkan HSB
- Panggil `ISCCNBSColorNamer.name(hue:saturation:brightness:)`
- Set `item.isccNbsName` dengan hasilnya

### 4.3 — Tampilkan di UI

- Di `AddItemSheet`: setelah extract color, tampilkan nama warna di bawah color swatch
- Di `ClothingCardView`: tampilkan `isccNbsName` sebagai subtitle
- Di `WardrobeItemDetailScreen`: tampilkan di color detail row

## Acceptance Criteria

- [ ] `ISCCNBSColorNamer.name()` mengembalikan nama warna yang masuk akal
- [ ] Nama warna tersimpan di `ClothingItem.isccNbsName`
- [ ] Nama warna tampil di card tiles dan detail screen
- [ ] Achromatic colors (hitam, putih, abu) terdeteksi benar

## Constraints

- ISCC-NBS HANYA untuk naming/label — BUKAN untuk scoring
- Scoring tetap pakai HSB numerik (di Phase 5)
- Lookup table boleh subset ~30-50 nama yang relevan untuk pakaian
