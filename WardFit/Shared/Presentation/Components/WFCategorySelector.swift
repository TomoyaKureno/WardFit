import SwiftUI

struct WFCategorySelector: View {
    @Binding var selectedCategory: ClothingCategory?
    var useAssetIcons = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: WFSpacing.xs) {
                ForEach(ClothingCategory.allCases) { category in
                    button(for: category)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func button(for category: ClothingCategory) -> some View {
        let isSelected = selectedCategory == category

        return Button {
            selectedCategory = category
        } label: {
            HStack(spacing: WFSpacing.xs) {
                if useAssetIcons {
                    Image(category == .top ? "imageTShirt" : "imagePants")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: category.iconName)
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(category.rawValue)
                    .font(WFType.body)
            }
            .foregroundStyle(isSelected ? WFColor.textOnBrand : WFColor.textPrimary)
            .padding(.horizontal, WFSpacing.sm)
            .padding(.vertical, WFSpacing.xs)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? WFColor.accentDenimSoft : WFColor.surfaceNested)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(WFColor.borderStrong.opacity(0.55), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WFCategorySelector(selectedCategory: .constant(.top))
        .padding()
        .background(WFColor.bg)
}
