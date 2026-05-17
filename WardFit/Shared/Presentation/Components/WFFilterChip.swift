import SwiftUI

struct WFFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(WFType.caption)
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
                .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
