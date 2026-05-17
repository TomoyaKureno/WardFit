//
//  MatchResultView.swift
//  WardFit
//
//  Created by Fathariq Dimas on 27/04/26.
//

import SwiftUI

struct MatchResultView: View {
    @ObservedObject var wardrobeStore: WardrobeStore
    @StateObject private var viewModel: MatchResultViewModel
    @State private var showSaveNameSheet = false
    @State private var wardrobeName = ""
    @State private var shouldCompleteAfterAlert = false
    @State private var showCancelConfirmation = false
    let onSelectCandidate: ((UUID) -> Void)?
    let onSelectRecommendation: ((UUID) -> Void)?
    let onCompleteAction: (() -> Void)?

    private let gridColumns = [
        GridItem(.flexible(), spacing: WFSpacing.sm),
        GridItem(.flexible(), spacing: WFSpacing.sm)
    ]

    @Environment(\.dismiss) private var dismiss

    init(
        wardrobeStore: WardrobeStore,
        viewModel: MatchResultViewModel,
        onSelectCandidate: ((UUID) -> Void)? = nil,
        onSelectRecommendation: ((UUID) -> Void)? = nil,
        onCompleteAction: (() -> Void)? = nil
    ) {
        self.wardrobeStore = wardrobeStore
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSelectCandidate = onSelectCandidate
        self.onSelectRecommendation = onSelectRecommendation
        self.onCompleteAction = onCompleteAction
    }

    private struct MatchDisplay: Identifiable {
        let id: UUID
        let item: ClothingItem
    }

    private var displayResults: [MatchDisplay] {
        viewModel
            .matches(from: wardrobeStore.wardrobeItems)
            .compactMap { result in
                guard let item = viewModel.item(for: result.candidateID, in: wardrobeStore.wardrobeItems) else {
                    return nil
                }
                return MatchDisplay(id: result.id, item: item)
            }
    }

    private var trimmedWardrobeName: String {
        wardrobeName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func completeResultFlow() {
        if let onCompleteAction {
            onCompleteAction()
        } else {
            dismiss()
        }
    }

    var body: some View {
        ZStack {
            WFColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: WFLayout.sectionSpacing) {
                    candidateSection
                    insightSection
                    recommendationSection
                    actionSection
                }
                .wfScreenContentPadding()
            }
        }
        .navigationTitle("Match Result")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .alert(viewModel.feedbackTitle, isPresented: $viewModel.showFeedbackAlert) {
            Button("OK") {
                guard shouldCompleteAfterAlert else {
                    return
                }

                shouldCompleteAfterAlert = false
                completeResultFlow()
            }
        } message: {
            Text(viewModel.feedbackMessage)
        }
        .sheet(isPresented: $showSaveNameSheet) {
            saveToWardrobeSheet
        }
        .alert("Cancel Recommendation?", isPresented: $showCancelConfirmation) {
            Button("Keep Editing", role: .cancel) {}
            Button("Cancel", role: .destructive) {
                completeResultFlow()
            }
        } message: {
            Text("This result will not be saved. Are you sure you want to go back to the main page?")
        }
    }

    private var candidateSection: some View {
        WFSectionCard {
            Text("Candidate")
                .font(WFType.title)
                .foregroundStyle(WFColor.textPrimary)

            Button {
                onSelectCandidate?(viewModel.candidateItem.id)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                        .fill(WFColor.surfaceNested)

                    if let image = viewModel.candidateItem.uiImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    } else {
                        Image(viewModel.candidateItem.resolvedImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)
                    }
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                        .stroke(WFColor.borderStrong.opacity(0.45), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            HStack(spacing: WFSpacing.sm) {
                VStack(alignment: .leading, spacing: WFSpacing.xs) {
                    Text("Detected Color")
                        .font(WFType.bodyMedium)
                        .foregroundStyle(WFColor.textPrimary)

                    Circle()
                        .fill(viewModel.candidateItem.displayColor)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle()
                                .stroke(WFColor.borderStrong.opacity(0.55), lineWidth: 1)
                        )
                }

                Spacer(minLength: 0)
            }
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

            Text(viewModel.recommendationText(for: displayResults.count))
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
                message: "Try another category or use a photo with more neutral lighting."
            )
        } else {
            WFSectionCard {
                Text("Recommendations")
                    .font(WFType.title)
                    .foregroundStyle(WFColor.textPrimary)

                LazyVGrid(columns: gridColumns, spacing: WFSpacing.sm) {
                    ForEach(displayResults) { entry in
                        Button {
                            onSelectRecommendation?(entry.item.id)
                        } label: {
                            WFWardrobeGridTile(item: entry.item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var actionSection: some View {
        WFSectionCard {
            Text("Actions")
                .font(WFType.title)
                .foregroundStyle(WFColor.textPrimary)

            VStack(spacing: WFSpacing.sm) {
                Button {
                    showSaveNameSheet = true
                } label: {
                    WFButtonLabelContent(title: "Save to Wardrobe", icon: "hanger")
                }
                .buttonStyle(WFButtonStyle(tone: .primary))

                Button {
                    viewModel.saveForLater(using: wardrobeStore)
                    shouldCompleteAfterAlert = true
                } label: {
                    WFButtonLabelContent(title: "Save for Later", icon: "bookmark")
                }
                .buttonStyle(WFButtonStyle(tone: .secondary))

                Button {
                    showCancelConfirmation = true
                } label: {
                    HStack(spacing: WFSpacing.xs) {
                        Image(systemName: "xmark")
                        Text("Cancel")
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
                    viewModel.saveToWardrobe(
                        using: wardrobeStore,
                        customName: trimmedWardrobeName
                    )
                    showSaveNameSheet = false
                    wardrobeName = ""
                    shouldCompleteAfterAlert = true
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
}

#Preview {
    NavigationStack {
        MatchResultView(
            wardrobeStore: WardrobeStore(),
            viewModel: MatchResultViewModel(
                candidateItem: ClothingItem(
                    itemName: "Top Candidate",
                    category: ClothingCategory.top.rawValue,
                    hue: 220,
                    saturation: 0.6,
                    brightness: 0.5,
                    isccNbsName: "Navy"
                )
            )
        )
    }
}
