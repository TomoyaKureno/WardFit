//
//  RootView.swift
//  WardFit
//
//  Created by Fathariq Dimas on 26/04/26.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var wardrobeStore: WardrobeStore?
    @StateObject private var appCoordinator = AppCoordinator()

    var body: some View {
        Group {
            if let wardrobeStore {
                TabView(selection: $appCoordinator.selectedTab) {
                    Tab("Wardrobe", systemImage: "hanger", value: .wardrobe) {
                        WardrobeView(wardrobeStore: wardrobeStore, coordinator: appCoordinator.wardrobeCoordinator)
                    }

                    Tab("Saved For Later", systemImage: "bookmark", value: .savedForLater) {
                        SavedForLaterView(
                            wardrobeStore: wardrobeStore,
                            coordinator: appCoordinator.savedForLaterCoordinator
                        )
                    }

                    Tab("Search", systemImage: "magnifyingglass", value: .search, role: .search) {
                        WardrobeSearchView(
                            wardrobeStore: wardrobeStore,
                            coordinator: appCoordinator.wardrobeSearchCoordinator,
                            onAppear: {
                                appCoordinator.selectedTab = .search
                            }
                        )
                    }
                }
                .background(WFColor.bg.ignoresSafeArea())
                .tint(WFColor.accentDenimSoft)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if wardrobeStore == nil {
                wardrobeStore = WardrobeStore(
                    repository: SwiftDataWardrobeRepository(modelContext: modelContext)
                )
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: ClothingItem.self, inMemory: true)
}
