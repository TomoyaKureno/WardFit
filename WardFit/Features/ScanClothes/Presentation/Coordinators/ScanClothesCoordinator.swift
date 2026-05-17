//
//  ScanClothesCoordinator.swift
//  WardFit
//
//  Created by Fathariq Dimas on 26/04/26.
//

import Combine
import SwiftUI

@MainActor
final class ScanClothesCoordinator: FeatureCoordinator<ScanClothesRoute> {
    let scanViewModel = ScanClothesViewModel()
    private var candidatesByID: [UUID: ClothingItem] = [:]

    func makeRootView(wardrobeStore: WardrobeStore) -> some View {
        ScanClothesFlowView(wardrobeStore: wardrobeStore, coordinator: self)
    }

    func showResult(for candidate: ClothingItem) {
        candidatesByID[candidate.id] = candidate
        push(.result(candidateID: candidate.id))
    }

    func resetFlow() {
        popToRoot()
        scanViewModel.reset()
        candidatesByID.removeAll()
    }

    @ViewBuilder
    func build(_ route: ScanClothesRoute, wardrobeStore: WardrobeStore) -> some View {
        switch route {
        case .capture:
            ScanClothesView(
                wardrobeStore: wardrobeStore,
                viewModel: scanViewModel,
                onOpenCamera: { [weak self] in
                    self?.push(.camera)
                },
                onFindMatch: { [weak self] candidate in
                    self?.showResult(for: candidate)
                }
            )
        case .camera:
            CustomCameraView(
                onCancel: { [weak self] in
                    self?.pop()
                },
                onCapture: { [weak self] image in
                    self?.scanViewModel.selectedImage = image
                    self?.pop()
                }
            )
        case .result(let candidateID):
            if let candidate = candidatesByID[candidateID] {
                MatchResultView(
                    wardrobeStore: wardrobeStore,
                    viewModel: MatchResultViewModel(candidateItem: candidate),
                    onSelectCandidate: { [weak self] candidateID in
                        self?.push(.candidateDetail(candidateID: candidateID))
                    },
                    onSelectRecommendation: { [weak self] itemID in
                        self?.push(.wardrobeDetail(itemID: itemID))
                    },
                    onCompleteAction: { [weak self] in
                        self?.resetFlow()
                    }
                )
            } else {
                ContentUnavailableView(
                    "Result unavailable",
                    systemImage: "sparkles",
                    description: Text("Please scan the item again to generate recommendations.")
                )
            }
        case .candidateDetail(let candidateID):
            if let candidate = candidatesByID[candidateID] {
                WardrobeItemDetailView(item: candidate, wardrobeStore: wardrobeStore)
            } else {
                ContentUnavailableView(
                    "Candidate not available",
                    systemImage: "photo",
                    description: Text("Please scan the item again to view its details.")
                )
            }
        case .wardrobeDetail(let itemID):
            if let item = wardrobeStore.item(withID: itemID) {
                WardrobeItemDetailView(
                    item: item,
                    wardrobeStore: wardrobeStore,
                    onSelectPairedItem: { [weak self] pairedItemID in
                        self?.push(.wardrobeDetail(itemID: pairedItemID))
                    }
                )
            } else {
                ContentUnavailableView(
                    "Item not available",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This wardrobe item is no longer available.")
                )
            }
        }
    }
}
