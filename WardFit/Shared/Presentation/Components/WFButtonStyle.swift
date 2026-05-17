import SwiftUI

enum WFButtonTone {
    case primary
    case secondary
}

struct WFButtonLabelContent: View {
    let title: String
    let icon: String?

    var body: some View {
        HStack(spacing: WFSpacing.xs) {
            if let icon {
                Image(systemName: icon)
            }
            Text(title)
                .lineLimit(1)
        }
        .font(WFType.bodyMedium)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
    }
}

struct WFButtonStyle: ButtonStyle {
    let tone: WFButtonTone
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foregroundColor.opacity(isEnabled ? 1 : 0.8))
            .background(backgroundView.opacity(isEnabled ? 1 : 0.45))
            .scaleEffect(configuration.isPressed && isEnabled ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var foregroundColor: Color {
        switch tone {
        case .primary:
            return WFColor.textOnBrand
        case .secondary:
            return WFColor.textPrimary
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch tone {
        case .primary:
            RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                .fill(WFColor.accentRose)
        case .secondary:
            RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                .fill(WFColor.surfaceNested)
                .overlay(
                    RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                        .stroke(WFColor.borderSoft, lineWidth: 1)
                )
        }
    }
}

#Preview {
    VStack(spacing: WFSpacing.md) {
        Button {} label: {
            WFButtonLabelContent(title: "Add Item", icon: "plus")
        }
        .buttonStyle(WFButtonStyle(tone: .primary))

        Button {} label: {
            WFButtonLabelContent(title: "Check New Item", icon: "sparkles")
        }
        .buttonStyle(WFButtonStyle(tone: .secondary))
    }
    .padding()
}
