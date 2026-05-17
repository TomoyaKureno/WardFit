import SwiftUI

struct EditItemSheet: View {
    @Environment(\.dismiss) private var dismiss

    let item: ClothingItem
    @ObservedObject var wardrobeStore: WardrobeStore
    @StateObject private var viewModel: EditItemSheetViewModel

    init(item: ClothingItem, wardrobeStore: WardrobeStore) {
        self.item = item
        self.wardrobeStore = wardrobeStore
        _viewModel = StateObject(wrappedValue: EditItemSheetViewModel(item: item))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WFColor.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: WFLayout.sectionSpacing) {
                        WFSectionCard {
                            WFItemPhotoSection(
                                title: "Photo",
                                selectedImage: $viewModel.selectedImage,
                                initialScale: viewModel.initialScale,
                                initialOffset: viewModel.initialOffset,
                                extractedColor: viewModel.extractedColor,
                                extractedColorName: viewModel.extractedColorName,
                                onOpenCamera: {
                                    viewModel.showCameraPicker = true
                                },
                                onScopeRectChanged: viewModel.updateExtractionScopeRect,
                                onRenderStateChanged: viewModel.updateScopedPhotoRenderState
                            )
                        }

                        WFSectionCard {
                            VStack(alignment: .leading, spacing: WFSpacing.sm) {
                                Text("Details")
                                    .font(WFType.title)
                                    .foregroundStyle(WFColor.textPrimary)

                                requiredLabel("Item Name")

                                TextField("Item Name", text: $viewModel.itemName)
                                    .textInputAutocapitalization(.words)
                                    .padding(.horizontal, WFSpacing.sm)
                                    .frame(height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: WFRadius.sm, style: .continuous)
                                            .fill(WFColor.surfaceNested)
                                    )

                                Text("Item Details")
                                    .foregroundStyle(WFColor.textPrimary)

                                TextField("Blue stripe cotton (Optional)", text: $viewModel.itemDescription)
                                    .textInputAutocapitalization(.sentences)
                                    .padding(.horizontal, WFSpacing.sm)
                                    .frame(height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: WFRadius.sm, style: .continuous)
                                            .fill(WFColor.surfaceNested)
                                    )

                                requiredLabel("Item Category")
                                WFCategorySelector(
                                    selectedCategory: $viewModel.selectedCategory,
                                    useAssetIcons: true
                                )
                            }
                        }
                    }
                    .wfScreenContentPadding()
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .sheet(isPresented: $viewModel.showCameraPicker) {
                CameraPickerView(selectedImage: $viewModel.selectedImage)
                    .ignoresSafeArea()
            }
        }
    }

    private func requiredLabel(_ title: String) -> some View {
        HStack(spacing: WFSpacing.xxs) {
            Text(title)
                .foregroundStyle(WFColor.textPrimary)
            Text("*")
                .foregroundStyle(.red)
        }
    }

    private func saveChanges() {
        guard viewModel.canSave else {
            return
        }

        let previousCategory = item.category
        let previousHue = item.hue
        let previousSaturation = item.saturation
        let previousBrightness = item.brightness

        item.itemName = viewModel.normalizedName
        item.itemDescription = viewModel.normalizedDescription
        item.category = viewModel.selectedCategory?.rawValue ?? item.category

        if let selectedImageData = viewModel.compressedImageData {
            item.imageData = selectedImageData
            item.originalImageData = viewModel.originalImageData
            item.previewScale = viewModel.previewScale
            item.previewOffsetX = viewModel.previewOffsetX
            item.previewOffsetY = viewModel.previewOffsetY
            item.previewViewportWidth = viewModel.previewViewportWidth
            item.previewViewportHeight = viewModel.previewViewportHeight
        }

        if let extractedColor = viewModel.extractedColor {
            item.hue = extractedColor.hue
            item.saturation = extractedColor.saturation
            item.brightness = extractedColor.brightness
            item.isccNbsName = viewModel.extractedColorName
        }

        let categoryChanged = previousCategory != item.category
        let colorChanged =
            abs(previousHue - item.hue) > 0.001 ||
            abs(previousSaturation - item.saturation) > 0.001 ||
            abs(previousBrightness - item.brightness) > 0.001

        wardrobeStore.updateItem(item, recomputePairs: categoryChanged || colorChanged)
    }
}
