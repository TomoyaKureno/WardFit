//
//  NormalizeClothingItemUseCase.swift
//  WardFit
//
//  Created by Codex on 27/04/26.
//

import Foundation

struct NormalizeClothingItemUseCase {
    func execute(_ item: ClothingItem) {
        let trimmedName = item.itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        item.itemName = trimmedName.isEmpty ? "\(item.clothingCategory.rawValue) Item" : trimmedName

        if item.isccNbsName == "Unknown" || item.isccNbsName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            item.isccNbsName = ISCCNBSColorNamer.name(
                hue: item.hue,
                saturation: item.saturation,
                brightness: item.brightness
            )
        }
    }
}
