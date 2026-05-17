//
//  SavedForLaterCoordinator.swift
//  WardFit
//
//  Created by Fathariq Dimas on 26/04/26.
//

import Combine
import SwiftUI

@MainActor
final class SavedForLaterCoordinator: FeatureCoordinator<SavedForLaterRoute> {
    private let scanViewModel = ScanClothesViewModel()
    private var scanCandidatesByID: [UUID: ClothingItem] = [:]

    func showScanClothes() {
        scanViewModel.reset()
        scanCandidatesByID.removeAll()
        push(.scanClothes)
    }

    private func showScanResult(for candidate: ClothingItem) {
        scanCandidatesByID[candidate.id] = candidate
        push(.scanResult(candidateID: candidate.id))
    }

    @ViewBuilder
    func build(_ route: SavedForLaterRoute, wardrobeStore: WardrobeStore) -> some View {
        switch route {
        case .wardrobeDetail(let itemID):
            if let item = wardrobeStore.item(withID: itemID) {
                SavedLaterItemDetailView(
                    item: item,
                    wardrobeStore: wardrobeStore,
                    onSelectRecommendation: { [weak self] itemID in
                        self?.push(.wardrobeItemDetail(itemID: itemID))
                    },
                    onFinish: { [weak self] in
                        self?.popToRoot()
                    }
                )
            } else {
                ContentUnavailableView(
                    "Item not available",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This item is no longer available.")
                )
            }
        case .scanClothes:
            ScanClothesView(
                wardrobeStore: wardrobeStore,
                viewModel: scanViewModel,
                onOpenCamera: { [weak self] in
                    self?.push(.scanCamera)
                },
                onFindMatch: { [weak self] candidate in
                    self?.showScanResult(for: candidate)
                }
            )
        case .scanCamera:
            CustomCameraView(
                onCancel: { [weak self] in
                    self?.pop()
                },
                onCapture: { [weak self] image in
                    self?.scanViewModel.selectedImage = image
                    self?.pop()
                }
            )
        case .scanResult(let candidateID):
            if let candidate = scanCandidatesByID[candidateID] {
                MatchResultView(
                    wardrobeStore: wardrobeStore,
                    viewModel: MatchResultViewModel(candidateItem: candidate),
                    onSelectCandidate: { [weak self] candidateID in
                        self?.push(.scanCandidateDetail(candidateID: candidateID))
                    },
                    onSelectRecommendation: { [weak self] itemID in
                        self?.push(.wardrobeItemDetail(itemID: itemID))
                    },
                    onCompleteAction: { [weak self] in
                        self?.popToRoot()
                    }
                )
            } else {
                ContentUnavailableView(
                    "Result unavailable",
                    systemImage: "sparkles",
                    description: Text("Please scan the item again to generate recommendations.")
                )
            }
        case .scanCandidateDetail(let candidateID):
            if let candidate = scanCandidatesByID[candidateID] {
                WardrobeItemDetailView(item: candidate, wardrobeStore: wardrobeStore)
            } else {
                ContentUnavailableView(
                    "Candidate not available",
                    systemImage: "photo",
                    description: Text("Please scan the item again to view its details.")
                )
            }
        case .wardrobeItemDetail(let itemID):
            if let item = wardrobeStore.wardrobeItems.first(where: { $0.id == itemID }) {
                WardrobeItemDetailView(
                    item: item,
                    wardrobeStore: wardrobeStore,
                    onSelectPairedItem: { [weak self] pairedItemID in
                        self?.push(.wardrobeItemDetail(itemID: pairedItemID))
                    }
                )
            } else {
                ContentUnavailableView(
                    "Wardrobe item not available",
                    systemImage: "hanger",
                    description: Text("This wardrobe item is no longer available.")
                )
            }
        }
    }
}
