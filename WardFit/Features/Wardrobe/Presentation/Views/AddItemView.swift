import SwiftUI

struct AddItemView: View {
    @ObservedObject var wardrobeStore: WardrobeStore
    @ObservedObject private var viewModel: AddItemViewModel
    let onOpenCamera: () -> Void
    let onComplete: () -> Void

    init(
        wardrobeStore: WardrobeStore,
        viewModel: AddItemViewModel = AddItemViewModel(),
        onOpenCamera: @escaping () -> Void = {},
        onComplete: @escaping () -> Void = {}
    ) {
        self.wardrobeStore = wardrobeStore
        self.onOpenCamera = onOpenCamera
        self.onComplete = onComplete
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            WFColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: WFLayout.sectionSpacing) {
                    WFSectionCard {
                        WFItemPhotoSection(
                            title: "Photo",
                            selectedImage: $viewModel.selectedImage,
                            selectedImageRenderID: viewModel.selectedImageRenderID,
                            extractedColor: viewModel.extractedColor,
                            extractedColorName: viewModel.extractedColorName,
                            onOpenCamera: onOpenCamera,
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
        .navigationTitle("Add Item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    viewModel.save(using: wardrobeStore)
                    onComplete()
                }
                .disabled(!viewModel.canSave)
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
}

#Preview {
    NavigationStack {
        AddItemView(wardrobeStore: WardrobeStore())
    }
}
