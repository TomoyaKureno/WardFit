import SwiftUI

struct WFSectionCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: WFSpacing.md) {
            content
        }
        .padding(WFSpacing.md)
        .wfCardBackground()
    }
}

#Preview {
    WFSectionCard {
        Text("Section title")
            .font(WFType.title)
        Text("Card content")
            .font(WFType.body)
    }
    .padding()
}
