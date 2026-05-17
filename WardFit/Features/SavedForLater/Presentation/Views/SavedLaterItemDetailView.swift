import SwiftUI

struct SavedLaterItemDetailView: View {
    let item: ClothingItem
    @ObservedObject var wardrobeStore: WardrobeStore
    let onSelectRecommendation: ((UUID) -> Void)?
    let onFinish: () -> Void

    @State private var showSaveNameSheet = false
    @State private var wardrobeName = ""
    @State private var showDeleteConfirmation = false
    @State private var showFeedbackAlert = false
    @State private var feedbackTitle = ""
    @State private var feedbackMessage = ""
    @State private var shouldReturnAfterAlert = false

    private let gridColumns = [
        GridItem(.flexible(), spacing: WFSpacing.sm),
        GridItem(.flexible(), spacing: WFSpacing.sm)
    ]

    init(
        item: ClothingItem,
        wardrobeStore: WardrobeStore,
        onSelectRecommendation: ((UUID) -> Void)? = nil,
        onFinish: @escaping () -> Void
    ) {
        self.item = item
        self.wardrobeStore = wardrobeStore
        self.onSelectRecommendation = onSelectRecommendation
        self.onFinish = onFinish
    }

    private struct MatchDisplay: Identifiable {
        let id: UUID
        let item: ClothingItem
    }

    private var trimmedWardrobeName: String {
        wardrobeName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var dateText: String {
        item.createdAt.formatted(date: .abbreviated, time: .omitted)
    }

    private var resolvedDescription: String {
        let trimmed = item.itemDescription?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty { return trimmed }

        return "\(item.itemName) is a \(item.category.lowercased()) candidate with \(item.isccNbsName.lowercased()) tone."
    }

    private var displayResults: [MatchDisplay] {
        let oppositeCategory = item.clothingCategory.opposite.rawValue
        let candidates = wardrobeStore.wardrobeItems
            .filter { $0.category == oppositeCategory }
            .map { (id: $0.id, hue: $0.hue, sat: $0.saturation, bri: $0.brightness) }

        return ColorHarmonyEngine.findMatches(
            sourceHue: item.hue,
            sourceSat: item.saturation,
            sourceBri: item.brightness,
            candidates: candidates
        )
        .compactMap { result in
            guard let matchedItem = wardrobeStore.wardrobeItems.first(where: { $0.id == result.candidateID }) else {
                return nil
            }
            return MatchDisplay(id: result.id, item: matchedItem)
        }
    }

    private func recommendationText(for matchCount: Int) -> String {
        switch matchCount {
        case 0:
            return "No strong pairing found yet. Try another item photo with cleaner lighting."
        case 1 ... 2:
            return "Good start. You already have a few items that pair comfortably with this candidate."
        default:
            return "Strong flexibility. This candidate works well across many outfit combinations."
        }
    }

    var body: some View {
        ZStack {
            WFColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: WFLayout.sectionSpacing) {
                    headerSection
                    insightSection
                    recommendationSection
                    actionsSection
                }
                .wfScreenContentPadding()
            }
        }
        .navigationTitle("Saved Item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showSaveNameSheet) {
            saveToWardrobeSheet
        }
        .alert(feedbackTitle, isPresented: $showFeedbackAlert) {
            Button("OK") {
                guard shouldReturnAfterAlert else { return }
                shouldReturnAfterAlert = false
                onFinish()
            }
        } message: {
            Text(feedbackMessage)
        }
        .alert("Delete Saved Item", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                wardrobeStore.removeSavedLater(item)
                onFinish()
            }
        } message: {
            Text("Remove this item from Saved Later? This will not affect your wardrobe.")
        }
    }

    private var headerSection: some View {
        WFSectionCard {
            HStack(alignment: .top, spacing: WFSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                        .fill(WFColor.surfaceNested)

                    if let image = item.uiImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    } else {
                        Image(item.resolvedImageName)
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(width: 160, height: 220)
                .clipShape(RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                        .stroke(WFColor.borderStrong.opacity(0.35), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: WFSpacing.sm) {
                    Text(item.itemName)
                        .font(.title.bold())
                        .foregroundStyle(WFColor.textPrimary)

                    detailRow(title: "Category") {
                        Text(item.category)
                            .font(WFType.caption)
                            .foregroundStyle(WFColor.textPrimary)
                            .padding(.horizontal, WFSpacing.sm)
                            .padding(.vertical, WFSpacing.xxs)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(WFColor.highlightSoft.opacity(0.34))
                            )
                    }

                    detailColorRow()
                    detailRow(title: "Saved At", value: dateText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var detailsSection: some View {
        WFSectionCard {
            HStack(spacing: WFSpacing.xs) {
                Image(systemName: "list.bullet.clipboard")
                    .bold()
                Text("Item Details")
                    .font(WFType.title)
                Spacer(minLength: 0)
            }
            .foregroundStyle(WFColor.textPrimary)

            Text(resolvedDescription)
                .font(WFType.body)
                .foregroundStyle(WFColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var insightSection: some View {
        VStack(alignment: .leading, spacing: WFSpacing.sm) {
            HStack(spacing: WFSpacing.sm) {
                HStack(spacing: WFSpacing.xs) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                    Text("Stylist Insight")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                }
                .foregroundStyle(WFColor.textPrimary)

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: WFSpacing.xxs) {
                    Text("MATCHED")
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundStyle(WFColor.textOnBrand.opacity(0.85))

                    Text("\(displayResults.count)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(WFColor.textOnBrand)
                }
                .padding(.horizontal, WFSpacing.sm)
                .padding(.vertical, WFSpacing.xs)
                .frame(minWidth: 72)
                .background(
                    RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                        .fill(WFColor.accentRose)
                )
            }

            Rectangle()
                .fill(WFColor.borderStrong.opacity(0.45))
                .frame(height: 1)

            Text("Insight")
                .font(WFType.bodyMedium)
                .foregroundStyle(WFColor.textSecondary)

            Text(recommendationText(for: displayResults.count))
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(WFColor.textPrimary)
                .padding(.horizontal, WFSpacing.sm)
                .padding(.vertical, WFSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                        .fill(WFColor.highlightSoft.opacity(0.45))
                )
        }
        .padding(WFSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: WFRadius.sm, style: .continuous)
                .fill(WFColor.surfaceAlt)
                .overlay(
                    RoundedRectangle(cornerRadius: WFRadius.sm, style: .continuous)
                        .stroke(WFColor.borderStrong.opacity(0.65), lineWidth: 1.2)
                )
        )
        .overlay(alignment: .leading) {
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: 8,
                    bottomLeading: 8
                ),
                style: .continuous
            )
            .fill(WFColor.accentRose.opacity(0.85))
            .frame(width: 8)
        }
    }

    @ViewBuilder
    private var recommendationSection: some View {
        if displayResults.isEmpty {
            WFEmptyState(
                icon: "sparkles",
                title: "No strong pairing found yet",
                message: "Try adding more wardrobe items or use a photo with cleaner lighting."
            )
        } else {
            WFSectionCard {
                VStack(alignment: .leading, spacing: WFSpacing.xs) {
                    HStack(spacing: WFSpacing.xs) {
                        Image(systemName: "link")
                            .bold()
                        Text("Recommended Matches")
                            .font(WFType.title)
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(WFColor.textPrimary)

                    Text("Based on this saved item's color and category.")
                        .font(WFType.caption)
                        .foregroundStyle(WFColor.textSecondary)
                }

                LazyVGrid(columns: gridColumns, spacing: WFSpacing.sm) {
                    ForEach(displayResults) { entry in
                        if let onSelectRecommendation {
                            Button {
                                onSelectRecommendation(entry.item.id)
                            } label: {
                                WFWardrobeGridTile(item: entry.item)
                            }
                            .buttonStyle(.plain)
                        } else {
                            WFWardrobeGridTile(item: entry.item)
                        }
                    }
                }
            }
        }
    }

    private var actionsSection: some View {
        WFSectionCard {
            Text("Actions")
                .font(WFType.title)
                .foregroundStyle(WFColor.textPrimary)

            VStack(spacing: WFSpacing.sm) {
                Button {
                    wardrobeName = item.itemName
                    showSaveNameSheet = true
                } label: {
                    WFButtonLabelContent(title: "Save to Wardrobe", icon: "hanger")
                }
                .buttonStyle(WFButtonStyle(tone: .primary))

                Button {
                    showDeleteConfirmation = true
                } label: {
                    HStack(spacing: WFSpacing.xs) {
                        Image(systemName: "trash")
                        Text("Delete Saved Item")
                    }
                    .font(WFType.bodyMedium)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .background(
                    RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                        .fill(Color.red.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }

    private var saveToWardrobeSheet: some View {
        VStack(spacing: 24) {
            HStack {
                Button {
                    showSaveNameSheet = false
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(WFColor.textOnBrand)
                        .bold()
                        .padding()
                }
                .background(WFColor.accentRose)
                .clipShape(Circle())

                Spacer()

                Text("Save to Wardrobe")
                    .font(.headline)

                Spacer()

                Button {
                    guard !trimmedWardrobeName.isEmpty else { return }

                    wardrobeStore.saveSavedLaterToWardrobe(item, customName: trimmedWardrobeName)
                    showSaveNameSheet = false
                    feedbackTitle = "Saved to Wardrobe"
                    feedbackMessage = "Item has been added to your wardrobe."
                    shouldReturnAfterAlert = true
                    showFeedbackAlert = true
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundStyle(WFColor.textOnBrand)
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(WFColor.accentRose)
                        )
                }
                .buttonStyle(.plain)
                .disabled(trimmedWardrobeName.isEmpty)
                .opacity(trimmedWardrobeName.isEmpty ? 0.55 : 1)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: WFSpacing.xxs) {
                    Text("Item Name")
                        .foregroundStyle(WFColor.textPrimary)
                    Text("*")
                        .foregroundStyle(.red)
                }

                TextField("Item Name", text: $wardrobeName)
                    .textInputAutocapitalization(.words)
                    .padding(.horizontal, WFSpacing.sm)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: WFRadius.sm, style: .continuous)
                            .fill(WFColor.surfaceNested)
                    )

                if trimmedWardrobeName.isEmpty {
                    Text("Item name is required.")
                        .font(WFType.caption)
                        .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer()
        }
        .padding(24)
        .presentationDetents([.fraction(0.5)])
        .presentationDragIndicator(.visible)
    }

    private func detailRow<Content: View>(
        title: String,
        value: String? = nil,
        @ViewBuilder content: () -> Content = { EmptyView() }
    ) -> some View {
        VStack(alignment: .leading, spacing: WFSpacing.xxs) {
            Text(title)
                .font(WFType.caption)
                .foregroundStyle(WFColor.textSecondary)

            if let value {
                Text(value)
                    .font(WFType.bodyMedium)
                    .foregroundStyle(WFColor.textPrimary)
            } else {
                content()
            }
        }
    }

    private func detailColorRow() -> some View {
        VStack(alignment: .leading, spacing: WFSpacing.xxs) {
            Text("Color")
                .font(WFType.caption)
                .foregroundStyle(WFColor.textSecondary)

            HStack(spacing: WFSpacing.xs) {
                Circle()
                    .fill(item.displayColor)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle()
                            .stroke(WFColor.borderStrong.opacity(0.45), lineWidth: 1)
                    )

                Text(item.isccNbsName)
                    .font(WFType.bodyMedium)
                    .foregroundStyle(WFColor.textPrimary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SavedLaterItemDetailView(
            item: ClothingItem(
                itemName: "Saved Beige Shirt",
                category: ClothingCategory.top.rawValue,
                hue: 38,
                saturation: 0.32,
                brightness: 0.72,
                isccNbsName: "Beige"
            ),
            wardrobeStore: WardrobeStore(),
            onFinish: {}
        )
    }
}
