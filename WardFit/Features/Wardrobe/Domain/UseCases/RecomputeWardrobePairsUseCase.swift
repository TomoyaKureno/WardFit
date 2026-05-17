//
//  RecomputeWardrobePairsUseCase.swift
//  WardFit
//
//  Created by Codex on 27/04/26.
//

struct RecomputeWardrobePairsUseCase {
    func execute(for item: ClothingItem, in wardrobeItems: [ClothingItem]) {
        for entity in wardrobeItems where entity.id != item.id {
            entity.pairedItemIDs.removeAll { $0 == item.id }
        }
        item.pairedItemIDs = []

        let oppositeCategory = item.clothingCategory.opposite.rawValue
        let candidates = wardrobeItems.filter {
            $0.id != item.id && $0.category == oppositeCategory
        }

        let tuples = candidates.map {
            (id: $0.id, hue: $0.hue, sat: $0.saturation, bri: $0.brightness)
        }

        let matches = ColorHarmonyEngine.findMatches(
            sourceHue: item.hue,
            sourceSat: item.saturation,
            sourceBri: item.brightness,
            candidates: tuples
        )

        let accepted = matches.filter { $0.rawScore >= 0.4 }
        item.pairedItemIDs = accepted.map { $0.candidateID }

        for match in accepted {
            guard let candidate = candidates.first(where: { $0.id == match.candidateID }) else {
                continue
            }
            if !candidate.pairedItemIDs.contains(item.id) {
                candidate.pairedItemIDs.append(item.id)
            }
        }
    }
}
