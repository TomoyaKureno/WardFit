import SwiftData
import SwiftUI
import UIKit

@Model
final class ClothingItem {
    var id: UUID
    var itemName: String
    var category: String
    var imageData: Data?
    var originalImageData: Data?
    var itemDescription: String?
    var hue: Double
    var saturation: Double
    var brightness: Double
    var isccNbsName: String
    var createdAt: Date
    var pairedItemIDs: [UUID]
    var collection: String?
    var previewScale: Double?
    var previewOffsetX: Double?
    var previewOffsetY: Double?
    var previewViewportWidth: Double?
    var previewViewportHeight: Double?

    init(
        itemName: String,
        category: String,
        imageData: Data? = nil,
        originalImageData: Data? = nil,
        itemDescription: String? = nil,
        hue: Double = 0,
        saturation: Double = 0,
        brightness: Double = 0,
        isccNbsName: String = "Unknown",
        createdAt: Date = .now,
        pairedItemIDs: [UUID] = [],
        collection: String? = ClothingItemCollection.wardrobe.rawValue,
        previewScale: Double? = nil,
        previewOffsetX: Double? = nil,
        previewOffsetY: Double? = nil,
        previewViewportWidth: Double? = nil,
        previewViewportHeight: Double? = nil
    ) {
        self.id = UUID()
        self.itemName = itemName
        self.category = category
        self.imageData = imageData
        self.originalImageData = originalImageData
        self.itemDescription = itemDescription
        self.hue = hue
        self.saturation = saturation
        self.brightness = brightness
        self.isccNbsName = isccNbsName
        self.createdAt = createdAt
        self.pairedItemIDs = pairedItemIDs
        self.collection = collection
        self.previewScale = previewScale
        self.previewOffsetX = previewOffsetX
        self.previewOffsetY = previewOffsetY
        self.previewViewportWidth = previewViewportWidth
        self.previewViewportHeight = previewViewportHeight
    }
    
    func changeName() {
        itemName = "afra"
    }
}

enum ClothingItemCollection: String {
    case wardrobe
    case savedLater
}

extension ClothingItem {
    var itemCollection: ClothingItemCollection {
        ClothingItemCollection(rawValue: collection ?? ClothingItemCollection.wardrobe.rawValue) ?? .wardrobe
    }

    var clothingCategory: ClothingCategory {
        ClothingCategory(rawValue: category) ?? .top
    }

    var displayColor: Color {
        Color(hue: hue / 360.0, saturation: saturation, brightness: brightness)
    }

    var uiImage: UIImage? {
        guard let imageData else { return nil }
        return UIImage(data: imageData)
    }

    var originalUIImage: UIImage? {
        guard let originalImageData else { return nil }
        return UIImage(data: originalImageData)
    }

    var resolvedImageName: String {
        if imageData != nil { return "" }
        return clothingCategory == .top ? "imageTShirt" : "imagePants"
    }
}
