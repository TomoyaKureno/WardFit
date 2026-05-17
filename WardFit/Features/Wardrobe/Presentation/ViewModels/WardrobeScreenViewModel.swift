import SwiftUI
import Combine

enum WardrobeItemFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case top = "Top"
    case bottom = "Bottom"

    var id: String { rawValue }

    func matches(_ item: ClothingItem) -> Bool {
        switch self {
        case .all:
            return true
        case .top:
            return item.clothingCategory == .top
        case .bottom:
            return item.clothingCategory == .bottom
        }
    }
}

final class WardrobeScreenViewModel: ObservableObject {
    @Published var selectedFilter: WardrobeItemFilter = .all
    @Published var searchText = ""

    func filteredItems(from items: [ClothingItem]) -> [ClothingItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return items.filter { item in
            let filterMatch = selectedFilter.matches(item)

            guard !query.isEmpty else {
                return filterMatch
            }

            let searchableText = [
                item.itemName,
                item.isccNbsName,
                item.category,
                item.itemDescription ?? ""
            ]
            .joined(separator: " ")
            .lowercased()

            return filterMatch && searchableText.contains(query)
        }
    }
}
