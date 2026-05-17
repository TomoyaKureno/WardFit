//
//  WardrobeRepository.swift
//  WardFit
//
//  Created by Codex on 27/04/26.
//

import Foundation

@MainActor
protocol WardrobeRepository: AnyObject {
    func fetchItems() -> [ClothingItem]
    func fetchSavedLaterItems() -> [ClothingItem]
    func fetchCount() -> Int
    func insert(_ item: ClothingItem)
    func delete(_ item: ClothingItem)
    func save()
}
