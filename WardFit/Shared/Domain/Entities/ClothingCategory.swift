import Foundation

enum ClothingCategory: String, CaseIterable, Identifiable {
    case top = "Top"
    case bottom = "Bottom"

    var id: String { rawValue }

    var opposite: ClothingCategory {
        switch self {
        case .top:
            return .bottom
        case .bottom:
            return .top
        }
    }

    var iconName: String {
        switch self {
        case .top:
            return "tshirt.fill"
        case .bottom:
            return "square.grid.2x2.fill"
        }
    }
}
