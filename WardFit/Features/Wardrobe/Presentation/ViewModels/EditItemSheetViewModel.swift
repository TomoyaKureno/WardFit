import SwiftUI
import UIKit
import Combine

final class EditItemSheetViewModel: ObservableObject {
    @Published var itemName: String
    @Published var itemDescription: String
    @Published var selectedCategory: ClothingCategory?
    @Published var selectedImage: UIImage?
    @Published var showCameraPicker = false
    @Published var extractedColor: ExtractedColor?
    @Published var extractionScopeRect: CGRect = EditItemSheetViewModel.defaultScopeRect
    @Published private var scopedPhotoRenderState: ScopedPhotoRenderState?

    private let originalColor: ExtractedColor
    let initialScale: CGFloat?
    let initialOffset: CGSize?
    private var cancellables: Set<AnyCancellable> = []
    private static let defaultScopeRect = ColorScopeConfig.normalizedRect

    init(item: ClothingItem) {
        itemName = item.itemName
        itemDescription = item.itemDescription ?? ""
        selectedCategory = ClothingCategory(rawValue: item.category) ?? .top
        selectedImage = item.originalUIImage ?? item.uiImage
        initialScale = item.previewScale.map { CGFloat($0) }
        if let offsetX = item.previewOffsetX, let offsetY = item.previewOffsetY {
            initialOffset = CGSize(width: offsetX, height: offsetY)
        } else {
            initialOffset = nil
        }
        originalColor = ExtractedColor(
            hue: item.hue,
            saturation: item.saturation,
            brightness: item.brightness
        )
        extractedColor = originalColor
        bindAutoExtraction()
    }

    var extractedColorName: String {
        guard let extractedColor else { return "Unknown" }
        return ISCCNBSColorNamer.name(
            hue: extractedColor.hue,
            saturation: extractedColor.saturation,
            brightness: extractedColor.brightness
        )
    }

    var compressedImageData: Data? {
        (scopedPhotoRenderState?.previewImage ?? selectedImage)?.jpegData(compressionQuality: 0.7)
    }

    var originalImageData: Data? {
        selectedImage?.jpegData(compressionQuality: 0.85)
    }

    var previewScale: Double? {
        scopedPhotoRenderState?.scale
    }

    var previewOffsetX: Double? {
        scopedPhotoRenderState?.offsetX
    }

    var previewOffsetY: Double? {
        scopedPhotoRenderState?.offsetY
    }

    var previewViewportWidth: Double? {
        scopedPhotoRenderState?.viewportWidth
    }

    var previewViewportHeight: Double? {
        scopedPhotoRenderState?.viewportHeight
    }

    var normalizedName: String {
        itemName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedDescription: String? {
        let trimmed = itemDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var canSave: Bool {
        !normalizedName.isEmpty && selectedCategory != nil && extractedColor != nil
    }

    func updateExtractionScopeRect(_ rect: CGRect) {
        extractionScopeRect = normalize(rect)
    }

    func updateScopedPhotoRenderState(_ state: ScopedPhotoRenderState) {
        scopedPhotoRenderState = state
    }

    private func bindAutoExtraction() {
        $selectedImage
            .dropFirst()
            .sink { [weak self] image in
                guard let self else { return }
                self.extractionScopeRect = Self.defaultScopeRect
                self.scopedPhotoRenderState = nil
                if image == nil {
                    self.extractedColor = self.originalColor
                } else {
                    self.extractedColor = nil
                }
            }
            .store(in: &cancellables)

        Publishers.CombineLatest($selectedImage, $extractionScopeRect.removeDuplicates())
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] image, scopeRect in
                guard let self else { return }
                guard let image else {
                    return
                }
                self.extractedColor = ColorExtractor.extractColor(from: image, scopeRect: scopeRect)
            }
            .store(in: &cancellables)
    }

    private func normalize(_ rect: CGRect) -> CGRect {
        let x = min(max(rect.origin.x, 0), 1)
        let y = min(max(rect.origin.y, 0), 1)
        let width = min(max(rect.width, 0.05), 1 - x)
        let height = min(max(rect.height, 0.05), 1 - y)
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
