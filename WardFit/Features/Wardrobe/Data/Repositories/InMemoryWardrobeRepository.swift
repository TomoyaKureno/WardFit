//
//  InMemoryWardrobeRepository.swift
//  WardFit
//
//  Created by Fathariq Dimas on 27/04/26.
//

@MainActor
final class InMemoryWardrobeRepository: WardrobeRepository {
    private var items: [ClothingItem]

    init(items: [ClothingItem] = []) {
        self.items = items
    }

    func fetchItems() -> [ClothingItem] {
        items
            .filter { $0.itemCollection == .wardrobe }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func fetchSavedLaterItems() -> [ClothingItem] {
        items
            .filter { $0.itemCollection == .savedLater }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func fetchCount() -> Int {
        fetchItems().count
    }

    func insert(_ item: ClothingItem) {
        guard !items.contains(where: { $0.id == item.id }) else {
            return
        }
        items.append(item)
    }

    func delete(_ item: ClothingItem) {
        items.removeAll { $0.id == item.id }
    }

    func save() {}
}
