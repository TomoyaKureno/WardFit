//
//  WardrobeSearchView.swift
//  WardFit
//
//  Created by Fathariq Dimas on 27/04/26.
//

import SwiftUI

struct WardrobeSearchView: View {
    @ObservedObject var wardrobeStore: WardrobeStore
    @ObservedObject var coordinator: WardrobeCoordinator
    let onAppear: (() -> Void)?
    @StateObject private var viewModel = WardrobeScreenViewModel()

    private let gridColumns = [
        GridItem(.flexible(), spacing: WFSpacing.sm),
        GridItem(.flexible(), spacing: WFSpacing.sm)
    ]

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            ZStack {
                WFColor.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: WFLayout.sectionSpacing) {
                        VStack(alignment: .leading, spacing: WFSpacing.xs) {
                            Text("Search")
                                .font(WFType.hero)
                                .foregroundStyle(WFColor.textPrimary)

                            Text("Search your closet and discover pieces that fit your look.")
                                .font(WFType.body)
                                .foregroundStyle(WFColor.textSecondary)
                        }

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
                                message: "Try another keyword or switch filter."
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
                    .wfScreenContentPadding()
                    .padding(.top, 56)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationDestination(for: WardrobeRoute.self) { route in
                coordinator.build(route, wardrobeStore: wardrobeStore)
            }
            .searchable(text: $viewModel.searchText, prompt: "Search wardrobe")
        }
        .onAppear {
            onAppear?()
        }
    }

    private func filterButton(for filter: WardrobeItemFilter) -> some View {
        let isSelected = viewModel.selectedFilter == filter

        return WFFilterChip(title: filter.rawValue, isSelected: isSelected) {
            viewModel.selectedFilter = filter
        }
    }
}

#Preview {
    WardrobeSearchView(
        wardrobeStore: WardrobeStore(),
        coordinator: WardrobeCoordinator(),
        onAppear: nil
    )
}
