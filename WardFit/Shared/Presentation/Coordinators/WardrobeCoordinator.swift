//
//  WardrobeCoordinator.swift
//  WardFit
//
//  Created by Fathariq Dimas on 26/04/26.
//

import Combine
import SwiftUI

@MainActor
final class WardrobeCoordinator: FeatureCoordinator<WardrobeRoute> {
    private let scanViewModel = ScanClothesViewModel()
    private let addItemViewModel = AddItemViewModel()
    private var scanCandidatesByID: [UUID: ClothingItem] = [:]

    func showAddItem() {
        addItemViewModel.reset()
        push(.addItem)
    }

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
    func build(_ route: WardrobeRoute, wardrobeStore: WardrobeStore) -> some View {
        switch route {
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
                    description: Text("This item is no longer available. Go back and pick another item.")
                )
            }
        case .addItem:
            AddItemView(
                wardrobeStore: wardrobeStore,
                viewModel: addItemViewModel,
                onOpenCamera: { [weak self] in
                    self?.push(.addItemCamera)
                },
                onComplete: { [weak self] in
                    self?.popToRoot()
                }
            )
        case .addItemCamera:
            CustomCameraView(
                onCancel: { [weak self] in
                    self?.pop()
                },
                onCapture: { [weak self] image in
                    self?.addItemViewModel.selectedImage = image
                    self?.pop()
                }
            )
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
                        self?.push(.wardrobeDetail(itemID: itemID))
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
                WardrobeItemDetailView(
                    item: candidate,
                    wardrobeStore: wardrobeStore
                )
            } else {
                ContentUnavailableView(
                    "Candidate not available",
                    systemImage: "photo",
                    description: Text("Please scan the item again to view its details.")
                )
            }
        }
    }
}
