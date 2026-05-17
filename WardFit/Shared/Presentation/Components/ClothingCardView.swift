import SwiftUI

struct WFWardrobeGridTile: View {
    let item: ClothingItem
    private let cardHeight: CGFloat = 240
    private let imageHeight: CGFloat = 112

    var body: some View {
        VStack(alignment: .leading, spacing: WFSpacing.sm) {
            imageSection

            ZStack(alignment: .topLeading){
                VStack(alignment: .leading, spacing: WFSpacing.xs) {
                    Text(item.itemName)
                        .font(WFType.bodyMedium)
                        .foregroundStyle(WFColor.textPrimary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(item.category)
                        .font(WFType.caption)
                        .foregroundStyle(WFColor.textSecondary)
                        .padding(.horizontal, WFSpacing.xs)
                        .padding(.vertical, WFSpacing.xxs)
                        .background(
                            Capsule(style: .continuous)
                                .fill(WFColor.highlightSoft.opacity(0.35))
                        )

                    HStack(spacing: 4) {
                        Circle()
                            .fill(item.displayColor)
                            .frame(width: 8, height: 8)
                        
                        Text(item.isccNbsName).bold()
                            .lineLimit(1)
                    }
                    .font(WFType.caption)
                    .foregroundStyle(WFColor.textSecondary)
                    .padding(.horizontal, WFSpacing.xs)
                    .padding(.vertical, WFSpacing.xxs)
                    .background(
                        Capsule(style: .continuous)
                            .fill(WFColor.highlightSoft.opacity(0.35))
                    )
                }

                HStack {
                    Spacer()

                    Image(item.clothingCategory == .top ? "imageTShirt" : "imagePants")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .opacity(0.5)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(WFSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: cardHeight, alignment: .top)
        .clipped()
        .contentShape(
            RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
        )
        .background(
            RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                .fill(WFColor.surfaceAlt)
                .overlay(
                    RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                        .stroke(WFColor.borderStrong.opacity(0.45), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
    }

    private var imageSection: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                    .fill(WFColor.surfaceNested)

                if let uiImage = item.uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: imageHeight)
                        .clipped()
                } else {
                    Image(item.resolvedImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .opacity(0.9)
                }
            }
            .frame(width: proxy.size.width, height: imageHeight)
            .clipShape(RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                    .stroke(WFColor.borderStrong.opacity(0.32), lineWidth: 0.8)
            )
        }
        .frame(height: imageHeight)
    }
}

#Preview {
    WFWardrobeGridTile(
        item: ClothingItem(
            itemName: "Navy Jeans",
            category: ClothingCategory.bottom.rawValue,
            hue: 220,
            saturation: 0.7,
            brightness: 0.45,
            isccNbsName: "Navy"
        )
    )
    .padding()
    .background(WFColor.bg)
}
