//
//  WardrobeCollectionUseCases.swift
//  WardFit
//
//  Created by Codex on 28/04/26.
//

import Foundation

struct WardrobeItemsSnapshot {
    let wardrobeItems: [ClothingItem]
    let savedLaterItems: [ClothingItem]
}

@MainActor
struct FetchWardrobeItemsUseCase {
    let repository: WardrobeRepository

    func execute() -> WardrobeItemsSnapshot {
        WardrobeItemsSnapshot(
            wardrobeItems: repository.fetchItems(),
            savedLaterItems: repository.fetchSavedLaterItems()
        )
    }
}

@MainActor
struct SeedWardrobeIfNeededUseCase {
    let repository: WardrobeRepository
    let recomputePairs: RecomputeWardrobePairsUseCase

    func execute() {
        guard repository.fetchCount() == 0 else {
            return
        }

        defaultWardrobeSeed.forEach { repository.insert($0) }
        repository.save()

        let wardrobeItems = repository.fetchItems()
        for item in wardrobeItems {
            recomputePairs.execute(for: item, in: wardrobeItems)
        }
        repository.save()
    }

    private var defaultWardrobeSeed: [ClothingItem] {
        [
            ClothingItem(
                itemName: "Navy Jeans",
                category: ClothingCategory.bottom.rawValue,
                itemDescription: "Slim denim fit with deep navy tone. Easy match for most light and earth-tone tops.",
                hue: 220,
                saturation: 0.79,
                brightness: 0.56,
                isccNbsName: "Navy",
                createdAt: .now.addingTimeInterval(-86400 * 5)
            ),
            ClothingItem(
                itemName: "Cream Chinos",
                category: ClothingCategory.bottom.rawValue,
                itemDescription: "Soft cotton chinos with warm cream color. Works best with dark or olive tops.",
                hue: 43,
                saturation: 0.11,
                brightness: 0.94,
                isccNbsName: "Cream",
                createdAt: .now.addingTimeInterval(-86400 * 4)
            ),
            ClothingItem(
                itemName: "Olive Tee",
                category: ClothingCategory.top.rawValue,
                itemDescription: "Casual olive tee with relaxed silhouette. Great for denim and neutral bottoms.",
                hue: 72,
                saturation: 0.48,
                brightness: 0.50,
                isccNbsName: "Olive",
                createdAt: .now.addingTimeInterval(-86400 * 3)
            ),
            ClothingItem(
                itemName: "White Shirt",
                category: ClothingCategory.top.rawValue,
                itemDescription: "Clean white shirt with smart-casual vibe. Flexible with nearly all bottom colors.",
                hue: 210,
                saturation: 0.02,
                brightness: 0.98,
                isccNbsName: "White",
                createdAt: .now.addingTimeInterval(-86400 * 2)
            )
        ]
    }
}

@MainActor
struct AddWardrobeItemUseCase {
    let repository: WardrobeRepository
    let normalizeItem: NormalizeClothingItemUseCase
    let recomputePairs: RecomputeWardrobePairsUseCase

    func execute(_ item: ClothingItem, wardrobeItems: [ClothingItem]) {
        item.collection = ClothingItemCollection.wardrobe.rawValue
        repository.insert(item)
        normalizeItem.execute(item)
        recomputePairs.execute(for: item, in: wardrobeItems)
        repository.save()
    }
}

@MainActor
struct UpdateWardrobeItemUseCase {
    let repository: WardrobeRepository
    let normalizeItem: NormalizeClothingItemUseCase
    let recomputePairs: RecomputeWardrobePairsUseCase

    func execute(_ item: ClothingItem, wardrobeItems: [ClothingItem], shouldRecomputePairs: Bool) {
        normalizeItem.execute(item)

        if shouldRecomputePairs {
            recomputePairs.execute(for: item, in: wardrobeItems)
        }

        repository.save()
    }
}

@MainActor
struct DeleteWardrobeItemUseCase {
    let repository: WardrobeRepository

    func execute(_ item: ClothingItem, wardrobeItems: [ClothingItem]) {
        for entity in wardrobeItems where entity.id != item.id {
            entity.pairedItemIDs.removeAll { $0 == item.id }
        }

        repository.delete(item)
        repository.save()
    }
}

@MainActor
struct SaveItemForLaterUseCase {
    let repository: WardrobeRepository

    func execute(_ item: ClothingItem, savedLaterItems: [ClothingItem]) {
        guard !savedLaterItems.contains(where: { $0.id == item.id }) else {
            return
        }

        item.collection = ClothingItemCollection.savedLater.rawValue
        repository.insert(item)
        repository.save()
    }
}

@MainActor
struct RemoveSavedLaterItemUseCase {
    let repository: WardrobeRepository

    func execute(_ item: ClothingItem) {
        repository.delete(item)
        repository.save()
    }
}

@MainActor
struct MoveSavedLaterItemToWardrobeUseCase {
    let repository: WardrobeRepository
    let normalizeItem: NormalizeClothingItemUseCase
    let recomputePairs: RecomputeWardrobePairsUseCase

    func execute(_ item: ClothingItem, customName: String, wardrobeItems: [ClothingItem]) {
        let savedItem = ClothingItem(
            itemName: customName,
            category: item.category,
            imageData: item.imageData,
            originalImageData: item.originalImageData,
            itemDescription: item.itemDescription,
            hue: item.hue,
            saturation: item.saturation,
            brightness: item.brightness,
            isccNbsName: item.isccNbsName,
            collection: ClothingItemCollection.wardrobe.rawValue,
            previewScale: item.previewScale,
            previewOffsetX: item.previewOffsetX,
            previewOffsetY: item.previewOffsetY,
            previewViewportWidth: item.previewViewportWidth,
            previewViewportHeight: item.previewViewportHeight
        )

        repository.delete(item)
        repository.insert(savedItem)
        normalizeItem.execute(savedItem)
        recomputePairs.execute(for: savedItem, in: wardrobeItems)
        repository.save()
    }
}

@MainActor
struct RecomputeSingleWardrobeItemPairsUseCase {
    let repository: WardrobeRepository
    let recomputePairs: RecomputeWardrobePairsUseCase

    func execute(for item: ClothingItem, wardrobeItems: [ClothingItem]) {
        recomputePairs.execute(for: item, in: wardrobeItems)
        repository.save()
    }
}

struct WardrobeItemLookupUseCase {
    func pairedItems(for item: ClothingItem, wardrobeItems: [ClothingItem]) -> [ClothingItem] {
        let lookup = Dictionary(uniqueKeysWithValues: wardrobeItems.map { ($0.id, $0) })
        return item.pairedItemIDs.compactMap { lookup[$0] }
    }

    func item(withID id: UUID, wardrobeItems: [ClothingItem], savedLaterItems: [ClothingItem]) -> ClothingItem? {
        if let wardrobe = wardrobeItems.first(where: { $0.id == id }) {
            return wardrobe
        }
        return savedLaterItems.first(where: { $0.id == id })
    }

    func isInWardrobe(_ item: ClothingItem, wardrobeItems: [ClothingItem]) -> Bool {
        wardrobeItems.contains { $0.id == item.id }
    }
}
