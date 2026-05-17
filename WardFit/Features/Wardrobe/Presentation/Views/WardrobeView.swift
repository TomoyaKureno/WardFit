//
//  WardrobeView.swift
//  WardFit
//
//  Created by Fathariq Dimas on 26/04/26.
//

import SwiftUI

struct WardrobeView: View {
    @ObservedObject var wardrobeStore: WardrobeStore
    @StateObject private var viewModel = WardrobeScreenViewModel()
    @ObservedObject var coordinator: WardrobeCoordinator

    private let gridColumns = [
        GridItem(.flexible(), spacing: WFSpacing.sm),
        GridItem(.flexible(), spacing: WFSpacing.sm)
    ]

    private var topCount: Int {
        wardrobeStore.wardrobeItems.filter { $0.clothingCategory == .top }.count
    }

    private var bottomCount: Int {
        wardrobeStore.wardrobeItems.filter { $0.clothingCategory == .bottom }.count
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            ZStack {
                WFColor.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: WFLayout.sectionSpacing) {
                        HStack(alignment: .top, spacing: WFSpacing.xl) {
                            VStack(alignment: .leading, spacing: WFSpacing.xs) {
                                Text("My Wardrobe")
                                    .font(WFType.hero)
                                    .foregroundStyle(WFColor.textPrimary)

                                Text("Make better outfit decisions with your digital closet.")
                                    .font(WFType.body)
                                    .foregroundStyle(WFColor.textSecondary)
                            }

                            Button {
                                coordinator.showAddItem()
                            } label: {
                                Image(systemName: "plus")
                                    .font(WFType.title)
                                    .frame(width: 56, height: 56)
                                    .contentShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.regular.interactive(), in: .circle)
                        }

                        Button {
                            coordinator.showScanClothes()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: WFSpacing.xs) {
                                    Text("Check New Clothes")
                                        .font(WFType.title)

                                    Text("See whether a clothing color goes with the clothes you already have.")
                                        .font(WFType.caption)
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer(minLength: 24)

                                Image(systemName: "chevron.right")
                                    .font(WFType.title)
                                    .contentShape(Circle())
                            }
                            .padding(WFSpacing.md)
                        }
                        .buttonStyle(WFButtonStyle(tone: .primary))

                        VStack(alignment: .leading, spacing: WFSpacing.sm) {
                            Text("Wardrobe Statistics")
                                .font(WFType.title)
                                .foregroundStyle(WFColor.textPrimary)

                            HStack(spacing: WFSpacing.sm) {
                                VStack(spacing: WFSpacing.xxs) {
                                    Spacer()

                                    Text("\(wardrobeStore.wardrobeItems.count)")
                                        .font(WFType.hero)
                                        .foregroundStyle(WFColor.textPrimary)

                                    Text("Total")
                                        .font(WFType.title)
                                        .foregroundStyle(WFColor.textSecondary)

                                    Spacer()
                                }
                                .padding(WFSpacing.sm)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                                        .fill(WFColor.highlightSoft.opacity(0.18))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                                                .stroke(WFColor.highlightSoft.opacity(0.45), lineWidth: 1)
                                        )
                                )
                                VStack(spacing: WFSpacing.sm) {
                                    statCard(title: "Tops", count: topCount, imageName: "imageTShirt", highlightColor: WFColor.highlightSoft)
                                    statCard(title: "Bottoms", count: bottomCount, imageName: "imagePants", highlightColor: WFColor.highlightWarm)
                                }
                            }
                        }
                        .padding(WFSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: WFRadius.lg, style: .continuous)
                                .fill(WFColor.highlightSoft.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: WFRadius.lg, style: .continuous)
                                        .stroke(WFColor.borderStrong.opacity(0.5), lineWidth: 1)
                                )
                        )

                        if wardrobeStore.wardrobeItems.isEmpty {
                            WFEmptyState(
                                icon: "hanger",
                                title: "Your wardrobe is empty",
                                message: "Add your first item and WardFit will help you mix and match.",
                                ctaTitle: "Add Item",
                                ctaAction: coordinator.showAddItem
                            )
                        } else {
                            VStack(alignment: .leading, spacing: WFSpacing.sm) {
                                Text("Wardrobe Items")
                                    .font(WFType.title)
                                    .foregroundStyle(WFColor.textPrimary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: WFSpacing.xs) {
                                        ForEach(WardrobeItemFilter.allCases) { filter in
                                            filterButton(for: filter)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }

                                let filteredItems = viewModel.filteredItems(from: wardrobeStore.wardrobeItems)
                                if filteredItems.isEmpty {
                                    WFEmptyState(
                                        icon: "magnifyingglass",
                                        title: "No items found",
                                        message: "Try a different keyword or change the  selected filter."
                                    )
                                } else {
                                    LazyVGrid(columns: gridColumns, spacing: WFSpacing.sm) {
                                        ForEach(filteredItems) { item in
                                            Button {
                                                coordinator.push(.wardrobeDetail(itemID: item.id))
                                            } label: {
                                                WFWardrobeGridTile(item: item)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .wfScreenContentPadding()
                    .padding(.top, 56)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationDestination(for: WardrobeRoute.self) { route in
                coordinator.build(route, wardrobeStore: wardrobeStore)
            }
        }
    }

    private func filterButton(for filter: WardrobeItemFilter) -> some View {
        let isSelected = viewModel.selectedFilter == filter

        return WFFilterChip(title: filter.rawValue, isSelected: isSelected) {
            viewModel.selectedFilter = filter
        }
    }

    private func statCard(
        title: String,
        count: Int,
        imageName: String,
        highlightColor: Color
    ) -> some View {
        HStack(spacing: WFSpacing.sm) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)
                .padding(WFSpacing.xs)
                .background(Circle().fill(highlightColor.opacity(0.32)))

            VStack(alignment: .leading, spacing: WFSpacing.xxs) {
                Text("\(count)")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(WFColor.textPrimary)

                Text(title)
                    .font(WFType.caption)
                    .foregroundStyle(WFColor.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(WFSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                .fill(highlightColor.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                        .stroke(highlightColor.opacity(0.45), lineWidth: 1)
                )
        )
    }
}

// #Preview {
//    WardrobeView(
//        wardrobeStore: WardrobeStore(),
//        coordinator: WardrobeCoordinator()
//    )
// }
