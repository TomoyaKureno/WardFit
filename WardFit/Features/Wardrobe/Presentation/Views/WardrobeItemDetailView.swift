//
//  WardrobeItemDetailView.swift
//  WardFit
//
//  Created by Fathariq Dimas on 27/04/26.
//

import SwiftUI

struct WardrobeItemDetailView: View {
    let item: ClothingItem
    @ObservedObject var wardrobeStore: WardrobeStore
    let onSelectPairedItem: ((UUID) -> Void)?

    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false

    private let gridColumns = [
        GridItem(.flexible(), spacing: WFSpacing.sm),
        GridItem(.flexible(), spacing: WFSpacing.sm)
    ]

    @Environment(\.dismiss) private var dismiss

    init(
        item: ClothingItem,
        wardrobeStore: WardrobeStore,
        onSelectPairedItem: ((UUID) -> Void)? = nil
    ) {
        self.item = item
        self.wardrobeStore = wardrobeStore
        self.onSelectPairedItem = onSelectPairedItem
    }

    private var resolvedDescription: String {
        let trimmed = item.itemDescription?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty { return trimmed }

        return "\(item.itemName) is a \(item.category.lowercased()) piece with \(item.isccNbsName.lowercased()) tone. Great as a base for mix-and-match outfits."
    }

    private var dateText: String {
        item.createdAt.formatted(date: .abbreviated, time: .omitted)
    }

    private var recommendedMatches: [ClothingItem] {
        wardrobeStore.pairedItems(for: item)
    }

    private var canMutate: Bool {
        wardrobeStore.isInWardrobe(item)
    }

    var body: some View {
        ZStack {
            WFColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: WFLayout.sectionSpacing) {
                    headerSection
                    detailsSection
                    insightSection
                    recommendationSection

                    if canMutate {
                        actionsSection
                    }
                }
                .wfScreenContentPadding()
            }
        }
        .navigationTitle("Item Detail")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditSheet) {
            EditItemSheet(item: item, wardrobeStore: wardrobeStore)
        }
        .alert("Delete Item", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                wardrobeStore.deleteItem(item)
                dismiss()
            }
        } message: {
            Text("Are you sure? This cannot be undone.")
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
                    detailRow(title: "Added To Wardrobe", value: dateText)
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
                    Text("MATCHES")
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundStyle(WFColor.textOnBrand.opacity(0.85))

                    Text("\(recommendedMatches.count)")
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

            Text(insightText)
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

    private var insightText: String {
        switch recommendedMatches.count {
        case 0:
            return "No strong pairing found yet. Add more opposite-category items or rescan this color in cleaner lighting."
        case 1 ... 2:
            return "Good start. This item has a few reliable pairings in your wardrobe."
        default:
            return "Strong flexibility. This item can anchor several outfit combinations."
        }
    }

    private var recommendationSection: some View {
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

                Text("Precomputed from harmony engine.")
                    .font(WFType.caption)
                    .foregroundStyle(WFColor.textSecondary)
            }

            if recommendedMatches.isEmpty {
                Text("No pairs found yet. Add more items to get recommendations.")
                    .font(WFType.body)
                    .foregroundStyle(WFColor.textSecondary)
            } else {
                LazyVGrid(columns: gridColumns, spacing: WFSpacing.sm) {
                    ForEach(recommendedMatches) { pairItem in
                        if let onSelectPairedItem {
                            Button {
                                onSelectPairedItem(pairItem.id)
                            } label: {
                                WFWardrobeGridTile(item: pairItem)
                            }
                            .buttonStyle(.plain)
                        } else {
                            WFWardrobeGridTile(item: pairItem)
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
                    showEditSheet = true
                } label: {
                    WFButtonLabelContent(title: "Edit Item", icon: "pencil")
                }
                .buttonStyle(WFButtonStyle(tone: .secondary))

                Button {
                    showDeleteConfirmation = true
                } label: {
                    HStack(spacing: WFSpacing.xs) {
                        Image(systemName: "trash")
                        Text("Delete Item")
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
        WardrobeItemDetailView(
            item: ClothingItem(
                itemName: "Blue Oxford Shirt",
                category: ClothingCategory.top.rawValue,
                hue: 220,
                saturation: 0.55,
                brightness: 0.65,
                isccNbsName: "Vivid Blue"
            ),
            wardrobeStore: WardrobeStore()
        )
    }
}
