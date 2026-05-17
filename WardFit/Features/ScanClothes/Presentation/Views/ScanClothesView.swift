//
//  ScanClothesView.swift
//  WardFit
//
//  Created by Fathariq Dimas on 27/04/26.
//

import SwiftUI

struct ScanClothesFlowView: View {
    @ObservedObject var wardrobeStore: WardrobeStore
    @ObservedObject var coordinator: ScanClothesCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            ScanClothesView(
                wardrobeStore: wardrobeStore,
                viewModel: coordinator.scanViewModel,
                onOpenCamera: {
                    coordinator.push(.camera)
                },
                onFindMatch: { candidate in
                    coordinator.showResult(for: candidate)
                }
            )
            .navigationDestination(for: ScanClothesRoute.self) { route in
                coordinator.build(route, wardrobeStore: wardrobeStore)
            }
        }
    }
}

struct ScanClothesView: View {
    @ObservedObject var wardrobeStore: WardrobeStore
    @ObservedObject var viewModel: ScanClothesViewModel
    let onOpenCamera: () -> Void
    let onFindMatch: (ClothingItem) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            WFColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: WFLayout.sectionSpacing) {
                    VStack(alignment: .leading, spacing: WFSpacing.xs) {
                        Text("Check New Clothes")
                            .font(WFType.hero)
                            .foregroundStyle(WFColor.textPrimary)

                        Text("See if a new clothing item matches what you already own.")
                            .font(WFType.body)
                            .foregroundStyle(WFColor.textSecondary)
                    }

                    WFSectionCard {
                        VStack(alignment: .leading, spacing: WFSpacing.md) {
                            WFItemPhotoSection(
                                title: "Candidate",
                                selectedImage: $viewModel.selectedImage,
                                selectedImageRenderID: viewModel.selectedImageRenderID,
                                extractedColor: viewModel.extractedColor,
                                extractedColorName: viewModel.extractedColorName,
                                onOpenCamera: onOpenCamera,
                                onScopeRectChanged: viewModel.updateExtractionScopeRect,
                                onRenderStateChanged: viewModel.updateScopedPhotoRenderState
                            )

                            VStack(alignment: .leading, spacing: WFSpacing.xs) {
                                requiredLabel("Item Category")

                                WFCategorySelector(
                                    selectedCategory: $viewModel.selectedCategory,
                                    useAssetIcons: true
                                )
                            }
                        }
                    }
                }
                .wfScreenContentPadding()
                .padding(.bottom, 120)
            }

            bottomFindMatchBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private var bottomFindMatchBar: some View {
        VStack(spacing: 0) {
            Button {
                guard let candidate = viewModel.makeCandidateItem() else {
                    return
                }

                onFindMatch(candidate)
            } label: {
                WFButtonLabelContent(title: "Find Match", icon: "sparkles")
            }
            .buttonStyle(WFButtonStyle(tone: .primary))
            .disabled(!viewModel.canFindMatch)
        }
        .padding(.horizontal, WFLayout.screenHorizontalPadding)
        .padding(.top, WFLayout.screenBottomPadding)
        .padding(.bottom, WFLayout.bottomBarBottomPadding)
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: WFRadius.lg,
                topTrailingRadius: WFRadius.lg,
                style: .continuous
            )
            .fill(WFColor.surface)
            .ignoresSafeArea(edges: .bottom)
        )
        .shadow(
            color: WFShadow.color,
            radius: WFShadow.radius,
            x: 0,
            y: -WFShadow.y
        )
    }

    private func requiredLabel(_ title: String) -> some View {
        HStack(spacing: WFSpacing.xxs) {
            Text(title)
                .foregroundStyle(WFColor.textPrimary)
            Text("*")
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    ScanClothesFlowView(
        wardrobeStore: WardrobeStore(),
        coordinator: ScanClothesCoordinator()
    )
}
