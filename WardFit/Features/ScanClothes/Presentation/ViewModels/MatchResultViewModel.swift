import SwiftUI
import Combine

final class MatchResultViewModel: ObservableObject {
    let candidateItem: ClothingItem

    @Published var showFeedbackAlert = false
    @Published var feedbackTitle = "Update"
    @Published var feedbackMessage = ""

    init(candidateItem: ClothingItem) {
        self.candidateItem = candidateItem
    }

    var selectedCategory: ClothingCategory {
        candidateItem.clothingCategory
    }

    func matches(from wardrobeItems: [ClothingItem]) -> [HarmonyMatchResult] {
        let oppositeCategory = selectedCategory.opposite.rawValue
        let candidates = wardrobeItems
            .filter { $0.category == oppositeCategory }
            .map { (id: $0.id, hue: $0.hue, sat: $0.saturation, bri: $0.brightness) }

        return ColorHarmonyEngine.findMatches(
            sourceHue: candidateItem.hue,
            sourceSat: candidateItem.saturation,
            sourceBri: candidateItem.brightness,
            candidates: candidates
        )
    }

    func recommendationText(for matchCount: Int) -> String {
        switch matchCount {
        case 0:
            return "No strong pairing found yet. Try another item photo with cleaner lighting."
        case 1...2:
            return "Good start. You already have a few items that pair comfortably with this candidate."
        default:
            return "Strong flexibility. This candidate works well across many outfit combinations."
        }
    }

    func item(for id: UUID, in wardrobeItems: [ClothingItem]) -> ClothingItem? {
        wardrobeItems.first(where: { $0.id == id })
    }

    func saveForLater(using wardrobeStore: WardrobeStore) {
        wardrobeStore.saveLater(candidateItem)
        feedbackTitle = "Saved for Later"
        feedbackMessage = "Item has been saved to review later."
        showFeedbackAlert = true
    }

    func saveToWardrobe(using wardrobeStore: WardrobeStore, customName: String) {
        let trimmedName = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            feedbackTitle = "Name Required"
            feedbackMessage = "Please provide an item name."
            showFeedbackAlert = true
            return
        }

        let savedItem = ClothingItem(
            itemName: trimmedName,
            category: candidateItem.category,
            imageData: candidateItem.imageData,
            originalImageData: candidateItem.originalImageData,
            itemDescription: candidateItem.itemDescription,
            hue: candidateItem.hue,
            saturation: candidateItem.saturation,
            brightness: candidateItem.brightness,
            isccNbsName: candidateItem.isccNbsName,
            collection: ClothingItemCollection.wardrobe.rawValue,
            previewScale: candidateItem.previewScale,
            previewOffsetX: candidateItem.previewOffsetX,
            previewOffsetY: candidateItem.previewOffsetY,
            previewViewportWidth: candidateItem.previewViewportWidth,
            previewViewportHeight: candidateItem.previewViewportHeight
        )

        wardrobeStore.addItem(savedItem)
        feedbackTitle = "Saved to Wardrobe"
        feedbackMessage = "Item has been added to your wardrobe."
        showFeedbackAlert = true
    }
}
