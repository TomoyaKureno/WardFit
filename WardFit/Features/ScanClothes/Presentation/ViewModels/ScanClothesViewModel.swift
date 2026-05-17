//
//  ScanClothesViewModel.swift
//  WardFit
//
//  Created by Fathariq Dimas on 27/04/26.
//


import SwiftUI
import UIKit
import Combine

final class ScanClothesViewModel: ObservableObject {
    @Published var selectedCategory: ClothingCategory?
    @Published var selectedImage: UIImage?
    @Published var extractedColor: ExtractedColor?
    @Published var extractionScopeRect: CGRect = ScanClothesViewModel.defaultScopeRect
    @Published private var scopedPhotoRenderState: ScopedPhotoRenderState?
    @Published private(set) var selectedImageRenderID = UUID()

    private var cancellables: Set<AnyCancellable> = []
    private static let defaultScopeRect = ColorScopeConfig.normalizedRect

    init() {
        bindAutoExtraction()
    }

    func reset() {
        selectedCategory = nil
        selectedImage = nil
        extractedColor = nil
        extractionScopeRect = Self.defaultScopeRect
        scopedPhotoRenderState = nil
        selectedImageRenderID = UUID()
    }

    var hasSelectedPhoto: Bool {
        selectedImage != nil
    }

    var compressedImageData: Data? {
        (scopedPhotoRenderState?.previewImage ?? selectedImage)?.jpegData(compressionQuality: 0.7)
    }

    var originalImageData: Data? {
        selectedImage?.jpegData(compressionQuality: 0.85)
    }

    var extractedColorName: String {
        guard let extractedColor else { return "Unknown" }
        return ISCCNBSColorNamer.name(
            hue: extractedColor.hue,
            saturation: extractedColor.saturation,
            brightness: extractedColor.brightness
        )
    }

    var canFindMatch: Bool {
        hasSelectedPhoto && selectedCategory != nil && extractedColor != nil
    }

    func updateExtractionScopeRect(_ rect: CGRect) {
        extractionScopeRect = normalize(rect)
    }

    func updateScopedPhotoRenderState(_ state: ScopedPhotoRenderState) {
        scopedPhotoRenderState = state
    }

    func makeCandidateItem() -> ClothingItem? {
        guard let selectedCategory,
              let extractedColor,
              let compressedImageData else {
            return nil
        }

        return ClothingItem(
            itemName: "\(selectedCategory.rawValue) Candidate",
            category: selectedCategory.rawValue,
            imageData: compressedImageData,
            originalImageData: originalImageData,
            itemDescription: nil,
            hue: extractedColor.hue,
            saturation: extractedColor.saturation,
            brightness: extractedColor.brightness,
            isccNbsName: extractedColorName,
            collection: ClothingItemCollection.savedLater.rawValue,
            previewScale: scopedPhotoRenderState?.scale,
            previewOffsetX: scopedPhotoRenderState?.offsetX,
            previewOffsetY: scopedPhotoRenderState?.offsetY,
            previewViewportWidth: scopedPhotoRenderState?.viewportWidth,
            previewViewportHeight: scopedPhotoRenderState?.viewportHeight
        )
    }

    private func bindAutoExtraction() {
        $selectedImage
            .sink { [weak self] image in
                guard let self else { return }
                self.extractionScopeRect = Self.defaultScopeRect
                if image == nil {
                    self.extractedColor = nil
                    self.scopedPhotoRenderState = nil
                } else {
                    self.selectedImageRenderID = UUID()
                    self.scopedPhotoRenderState = nil
                }
            }
            .store(in: &cancellables)

        Publishers.CombineLatest($selectedImage, $extractionScopeRect.removeDuplicates())
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] image, scopeRect in
                guard let self else { return }
                guard let image else {
                    self.extractedColor = nil
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
