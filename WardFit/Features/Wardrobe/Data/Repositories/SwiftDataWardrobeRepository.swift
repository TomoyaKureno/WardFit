//
//  SwiftDataWardrobeRepository.swift
//  WardFit
//
//  Created by Codex on 27/04/26.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataWardrobeRepository: WardrobeRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchItems() -> [ClothingItem] {
        let descriptor = FetchDescriptor<ClothingItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return ((try? modelContext.fetch(descriptor)) ?? [])
            .filter { $0.itemCollection == .wardrobe }
    }

    func fetchSavedLaterItems() -> [ClothingItem] {
        let descriptor = FetchDescriptor<ClothingItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return ((try? modelContext.fetch(descriptor)) ?? [])
            .filter { $0.itemCollection == .savedLater }
    }

    func fetchCount() -> Int {
        fetchItems().count
    }

    func insert(_ item: ClothingItem) {
        if item.modelContext == nil {
            modelContext.insert(item)
        }
    }

    func delete(_ item: ClothingItem) {
        modelContext.delete(item)
    }

    func save() {
        try? modelContext.save()
    }
}
