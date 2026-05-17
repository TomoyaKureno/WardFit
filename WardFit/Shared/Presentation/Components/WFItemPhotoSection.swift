import SwiftUI
import UIKit

struct WFItemPhotoSection: View {
    let title: String
    @Binding var selectedImage: UIImage?
    var selectedImageRenderID: UUID?
    var initialScale: CGFloat?
    var initialOffset: CGSize?
    var extractedColor: ExtractedColor?
    var extractedColorName: String
    var placeholderIcon = "camera"
    var placeholderText = "Capture or pick photo"
    var onOpenCamera: () -> Void
    var onScopeRectChanged: (CGRect) -> Void
    var onRenderStateChanged: (ScopedPhotoRenderState) -> Void

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: WFSpacing.md) {
            Text(title)
                .font(WFType.title)
                .foregroundStyle(WFColor.textPrimary)

            photoPreview

            if selectedImage != nil {
                Text("Pinch to zoom and drag the photo to align the item in the scope.")
                    .font(WFType.caption)
                    .foregroundStyle(WFColor.textSecondary)
            }

            HStack(spacing: WFSpacing.sm) {
                GalleryPickerView(selectedImage: $selectedImage)

                Button {
                    onOpenCamera()
                } label: {
                    Label("Camera", systemImage: "camera")
                        .font(WFType.bodyMedium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(WFColor.textPrimary)
                .background(
                    RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                        .fill(WFColor.surfaceNested)
                        .overlay(
                            RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                                .stroke(WFColor.borderSoft, lineWidth: 1)
                        )
                )
                .disabled(!cameraAvailable)
                .opacity(cameraAvailable ? 1 : 0.5)
            }

            if let extractedColor {
                detectedColorRow(extractedColor)
            }
        }
    }

    @ViewBuilder
    private var photoPreview: some View {
        if let image = selectedImage {
            InteractiveScopePhotoView(
                image: image,
                initialScale: initialScale,
                initialOffset: initialOffset,
                onScopeRectChanged: onScopeRectChanged,
                onRenderStateChanged: onRenderStateChanged
            )
            .id(selectedImageRenderID)
            .clipShape(RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                .fill(WFColor.surfaceNested)
                .frame(height: 220)
                .overlay {
                    VStack(spacing: WFSpacing.xs) {
                        Image(systemName: placeholderIcon)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(WFColor.accentDenimSoft)

                        Text(placeholderText)
                            .font(WFType.bodyMedium)
                            .foregroundStyle(WFColor.textPrimary)
                    }
                }
        }
    }

    private func detectedColorRow(_ extractedColor: ExtractedColor) -> some View {
        VStack(alignment: .leading, spacing: WFSpacing.xs) {
            Text("Detected Color")
                .font(WFType.caption)
                .foregroundStyle(WFColor.textSecondary)

            HStack(spacing: WFSpacing.sm) {
                Circle()
                    .fill(Color(
                        hue: extractedColor.hue / 360.0,
                        saturation: extractedColor.saturation,
                        brightness: extractedColor.brightness
                    ))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(WFColor.borderStrong.opacity(0.45), lineWidth: 1)
                    )

                Text(extractedColorName)
                    .font(WFType.bodyMedium)
                    .foregroundStyle(WFColor.textPrimary)
            }
        }
    }
}
