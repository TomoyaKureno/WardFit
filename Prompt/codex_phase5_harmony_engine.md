# Codex Task: Phase 5 — Color Harmony Matching Engine

> **Prerequisite**: Phase 3 & 4 sudah selesai.
> Baca `Prompt/codex_context.md` untuk full project context.

## Objective

Implementasi **rule-based color harmony engine** — jantung dari app. Engine menghitung kecocokan warna antara 2 item berdasarkan 5 tipe harmony. **Matching dihitung SAAT ITEM DI-SAVE** dan hasilnya di-persist sebagai `pairedItemIDs` (bi-directional).

## Tasks

### 5.1 — Buat `WardFit/Engine/ColorHarmonyEngine.swift`

```swift
import Foundation

enum HarmonyType: String, CaseIterable {
    case monochromatic     = "Monochromatic"
    case analogous         = "Analogous"
    case complementary     = "Complementary"
    case splitComplementary = "Split Complementary"
    case triadic           = "Triadic"
}

struct HarmonyMatchResult: Identifiable {
    let id: UUID
    let candidateID: UUID
    let harmonyType: HarmonyType
    let rawScore: Double    // 0...1
    var percentage: Int { Int(rawScore * 100) }

    var label: String {
        switch percentage {
        case 80...100: return "Best Match"
        case 60..<80:  return "Good Match"
        case 40..<60:  return "Recommended"
        default:       return "Possible"
        }
    }

    init(candidateID: UUID, harmonyType: HarmonyType, rawScore: Double) {
        self.id = UUID()
        self.candidateID = candidateID
        self.harmonyType = harmonyType
        self.rawScore = rawScore
    }
}

enum ColorHarmonyEngine {

    // MARK: - Public API

    /// Find all matches for a source item from candidates (opposite category).
    /// Returns sorted by score descending.
    static func findMatches(
        sourceHue: Double, sourceSat: Double, sourceBri: Double,
        candidates: [(id: UUID, hue: Double, sat: Double, bri: Double)]
    ) -> [HarmonyMatchResult] {
        candidates.compactMap { c in
            guard let best = bestHarmony(
                srcH: sourceHue, srcS: sourceSat, srcB: sourceBri,
                canH: c.hue, canS: c.sat, canB: c.bri
            ) else { return nil as HarmonyMatchResult? }
            return HarmonyMatchResult(
                candidateID: c.id,
                harmonyType: best.type,
                rawScore: best.score
            )
        }
        .filter { $0.rawScore > 0.05 }
        .sorted { $0.rawScore > $1.rawScore }
    }

    // MARK: - Core Logic

    private static func bestHarmony(
        srcH: Double, srcS: Double, srcB: Double,
        canH: Double, canS: Double, canB: Double
    ) -> (type: HarmonyType, score: Double)? {
        let results: [(HarmonyType, Double)] = [
            (.monochromatic,     monochromaticScore(srcH: srcH, srcS: srcS, srcB: srcB, canH: canH, canS: canS, canB: canB)),
            (.analogous,         analogousScore(srcH: srcH, srcS: srcS, srcB: srcB, canH: canH, canS: canS, canB: canB)),
            (.complementary,     complementaryScore(srcH: srcH, srcS: srcS, srcB: srcB, canH: canH, canS: canS, canB: canB)),
            (.splitComplementary, splitComplementaryScore(srcH: srcH, srcS: srcS, srcB: srcB, canH: canH, canS: canS, canB: canB)),
            (.triadic,           triadicScore(srcH: srcH, srcS: srcS, srcB: srcB, canH: canH, canS: canS, canB: canB)),
        ]
        guard let best = results.max(by: { $0.1 < $1.1 }), best.1 > 0 else { return nil }
        return (best.0, best.1)
    }

    // MARK: - Hue Distance (circular)

    private static func hueDiff(_ a: Double, _ b: Double) -> Double {
        let d = abs(a - b).truncatingRemainder(dividingBy: 360)
        return min(d, 360 - d)
    }

    // MARK: - Penalty helpers

    private static func satBriPenalty(srcS: Double, srcB: Double, canS: Double, canB: Double) -> Double {
        abs(srcS - canS) * 0.3 + abs(srcB - canB) * 0.2
    }

    // MARK: - Harmony Scorers

    /// Monochromatic: same hue (±10°), different sat/bri
    private static func monochromaticScore(srcH: Double, srcS: Double, srcB: Double,
                                            canH: Double, canS: Double, canB: Double) -> Double {
        let tolerance = 10.0
        let hd = hueDiff(srcH, canH)
        guard hd <= tolerance else { return 0 }
        let hueScore = 1.0 - (hd / tolerance)
        // Bonus: reward sat/bri difference (monochromatic is about variation)
        let variation = abs(srcS - canS) * 0.3 + abs(srcB - canB) * 0.4
        let variationBonus = min(variation, 0.3)
        return max(0, min(1, hueScore * 0.7 + variationBonus))
    }

    /// Analogous: adjacent hues (±30°)
    private static func analogousScore(srcH: Double, srcS: Double, srcB: Double,
                                        canH: Double, canS: Double, canB: Double) -> Double {
        let tolerance = 30.0
        let hd = hueDiff(srcH, canH)
        guard hd <= tolerance, hd > 10 else { return 0 } // exclude mono range
        let hueScore = 1.0 - (hd / tolerance)
        let penalty = satBriPenalty(srcS: srcS, srcB: srcB, canS: canS, canB: canB)
        return max(0, hueScore - penalty)
    }

    /// Complementary: opposite hue (180° ± 15°)
    private static func complementaryScore(srcH: Double, srcS: Double, srcB: Double,
                                            canH: Double, canS: Double, canB: Double) -> Double {
        let target = (srcH + 180).truncatingRemainder(dividingBy: 360)
        let tolerance = 15.0
        let hd = hueDiff(target, canH)
        guard hd <= tolerance else { return 0 }
        let hueScore = 1.0 - (hd / tolerance)
        let penalty = satBriPenalty(srcS: srcS, srcB: srcB, canS: canS, canB: canB)
        return max(0, hueScore - penalty)
    }

    /// Split Complementary: 150° and 210° from source (±15°)
    private static func splitComplementaryScore(srcH: Double, srcS: Double, srcB: Double,
                                                 canH: Double, canS: Double, canB: Double) -> Double {
        let t1 = (srcH + 150).truncatingRemainder(dividingBy: 360)
        let t2 = (srcH + 210).truncatingRemainder(dividingBy: 360)
        let tolerance = 15.0
        let hd = min(hueDiff(t1, canH), hueDiff(t2, canH))
        guard hd <= tolerance else { return 0 }
        let hueScore = 1.0 - (hd / tolerance)
        let penalty = satBriPenalty(srcS: srcS, srcB: srcB, canS: canS, canB: canB)
        return max(0, hueScore - penalty)
    }

    /// Triadic: 120° and 240° from source (±15°)
    private static func triadicScore(srcH: Double, srcS: Double, srcB: Double,
                                      canH: Double, canS: Double, canB: Double) -> Double {
        let t1 = (srcH + 120).truncatingRemainder(dividingBy: 360)
        let t2 = (srcH + 240).truncatingRemainder(dividingBy: 360)
        let tolerance = 15.0
        let hd = min(hueDiff(t1, canH), hueDiff(t2, canH))
        guard hd <= tolerance else { return 0 }
        let hueScore = 1.0 - (hd / tolerance)
        let penalty = satBriPenalty(srcS: srcS, srcB: srcB, canS: canS, canB: canB)
        return max(0, hueScore - penalty)
    }
}
```

### 5.2 — Update `WardrobeAppViewModel.addItem()` — Save-Time Pair Computation

```swift
func addItem(_ item: ClothingItem) {
    modelContext.insert(item)

    // 1. Fetch opposite category items
    let oppositeCategory = (item.category == "Top") ? "Bottom" : "Top"
    let descriptor = FetchDescriptor<ClothingItem>(
        predicate: #Predicate { $0.category == oppositeCategory }
    )
    let candidates = (try? modelContext.fetch(descriptor)) ?? []

    // 2. Run harmony engine
    let candidateTuples = candidates.map { (id: $0.id, hue: $0.hue, sat: $0.saturation, bri: $0.brightness) }
    let matches = ColorHarmonyEngine.findMatches(
        sourceHue: item.hue, sourceSat: item.saturation, sourceBri: item.brightness,
        candidates: candidateTuples
    )

    // 3. Filter >= 40% and store pairs
    let threshold = 0.4
    let goodMatches = matches.filter { $0.rawScore >= threshold }
    item.pairedItemIDs = goodMatches.map { $0.candidateID }

    // 4. Bi-directional: update each matched candidate
    for match in goodMatches {
        if let candidate = candidates.first(where: { $0.id == match.candidateID }) {
            if !candidate.pairedItemIDs.contains(item.id) {
                candidate.pairedItemIDs.append(item.id)
            }
        }
    }

    try? modelContext.save()
    fetchItems()
}
```

### 5.3 — Update `deleteItem()` — Cascade Cleanup

```swift
func deleteItem(_ item: ClothingItem) {
    // Remove this item's ID from all paired items
    for pairedID in item.pairedItemIDs {
        let descriptor = FetchDescriptor<ClothingItem>(
            predicate: #Predicate { $0.id == pairedID }
        )
        if let paired = try? modelContext.fetch(descriptor).first {
            paired.pairedItemIDs.removeAll { $0 == item.id }
        }
    }
    modelContext.delete(item)
    try? modelContext.save()
    fetchItems()
}
```

### 5.4 — Update `MatchResultViewModel`

Ganti `MockData.resultCandidates()` dengan real engine:

```swift
func matches(from wardrobe: [ClothingItem]) -> [HarmonyMatchResult] {
    let candidates = wardrobe
        .filter { $0.category != selectedCategory.rawValue }
        .map { (id: $0.id, hue: $0.hue, sat: $0.saturation, bri: $0.brightness) }
    return ColorHarmonyEngine.findMatches(
        sourceHue: candidateItem.hue,
        sourceSat: candidateItem.saturation,
        sourceBri: candidateItem.brightness,
        candidates: candidates
    )
}
```

## Acceptance Criteria

- [ ] 5 harmony types implemented dan menghasilkan score yang masuk akal
- [ ] `addItem()` otomatis compute pairs dan simpan ke `pairedItemIDs`
- [ ] Pairs bersifat **bi-directional** (A↔B)
- [ ] `deleteItem()` membersihkan references dari paired items
- [ ] `MatchResultScreen` menampilkan real score & harmony type
- [ ] Scoring circular hue (0°=360°) bekerja benar

## Constraints

- SEMUA rule-based, TIDAK ADA AI/ML
- Scoring pakai HSB numerik, BUKAN ISCC-NBS names
- Threshold pair storage: score >= 0.4 (40%)
- Pairs WAJIB bi-directional
