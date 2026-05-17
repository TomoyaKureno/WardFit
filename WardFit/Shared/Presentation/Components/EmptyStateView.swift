import SwiftUI

struct WFEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var ctaTitle: String?
    var ctaAction: (() -> Void)?

    var body: some View {
        WFSectionCard {
            VStack(spacing: WFSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(WFColor.accentDenimSoft)

                VStack(spacing: WFSpacing.xs) {
                    Text(title)
                        .font(WFType.title)
                        .foregroundStyle(WFColor.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(WFType.body)
                        .foregroundStyle(WFColor.textSecondary)
                        .multilineTextAlignment(.center)
                }

                if let ctaTitle, let ctaAction {
                    Button {
                        ctaAction()
                    } label: {
                        WFButtonLabelContent(title: ctaTitle, icon: nil)
                    }
                    .buttonStyle(WFButtonStyle(tone: .primary))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, WFSpacing.sm)
        }
    }
}

struct EmptyStateView: View {
    let iconName: String
    let title: String
    let message: String

    var body: some View {
        WFEmptyState(icon: iconName, title: title, message: message)
    }
}

#Preview {
    WFEmptyState(
        icon: "hanger",
        title: "Your wardrobe is empty",
        message: "Add your first item and WardFit will help you mix and match.",
        ctaTitle: "Add Item",
        ctaAction: {}
    )
    .padding()
    .background(WFColor.bg)
}
