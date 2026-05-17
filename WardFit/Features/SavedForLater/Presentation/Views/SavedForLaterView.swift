//
//  SavedForLaterView.swift
//  WardFit
//
//  Created by Fathariq Dimas on 26/04/26.
//
import SwiftUI

struct SavedForLaterView: View {
    @ObservedObject var wardrobeStore: WardrobeStore
    @ObservedObject var coordinator: SavedForLaterCoordinator
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
                            Text("Saved For Later")
                                .font(WFType.hero)
                                .foregroundStyle(WFColor.textPrimary)

                            Text("Keep outfit candidates here and come back when you’re ready to decide.")
                                .font(WFType.body)
                                .foregroundStyle(WFColor.textSecondary)
                        }

                        if wardrobeStore.savedLaterItems.isEmpty {
                            WFEmptyState(
                                icon: "bookmark.slash",
                                title: "No saved items yet",
                                message: "Save candidates from match results to review them later.",
                                ctaTitle: "Check New Clothes",
                                ctaAction: {
                                    coordinator.showScanClothes()
                                }
                            )
                        } else {
                            VStack(alignment: .leading, spacing: WFSpacing.sm) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: WFSpacing.xs) {
                                        ForEach(WardrobeItemFilter.allCases) { filter in
                                            filterButton(for: filter)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }

                                let filteredItems = viewModel.filteredItems(from: wardrobeStore.savedLaterItems)

                                if filteredItems.isEmpty {
                                    WFEmptyState(
                                        icon: "line.3.horizontal.decrease.circle",
                                        title: "No saved items found",
                                        message: "Try switching the filter to see another category."
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
            .navigationDestination(for: SavedForLaterRoute.self) { route in
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
}

#Preview {
    SavedForLaterView(
        wardrobeStore: WardrobeStore(),
        coordinator: SavedForLaterCoordinator()
    )
}
