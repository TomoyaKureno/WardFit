import SwiftUI
import PhotosUI
import UIKit

struct GalleryPickerView: View {
    @Binding var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var loadTask: Task<Void, Never>?

    var title: String = "Gallery"
    var icon: String = "photo.on.rectangle"

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            Label(title, systemImage: icon)
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
        .onChange(of: selectedItem) { _, newItem in
            loadTask?.cancel()

            guard let newItem else {
                return
            }

            loadTask = Task {
                do {
                    guard let data = try await newItem.loadTransferable(type: Data.self) else {
                        await MainActor.run {
                            selectedItem = nil
                        }
                        return
                    }

                    if Task.isCancelled {
                        return
                    }

                    guard let image = UIImage(data: data)?.normalizedForPreview(maxDimension: 2048) else {
                        await MainActor.run {
                            selectedItem = nil
                        }
                        return
                    }

                    await MainActor.run {
                        selectedImage = image
                        selectedItem = nil
                    }
                } catch {
                    await MainActor.run {
                        selectedItem = nil
                    }
                }
            }
        }
        .onDisappear {
            loadTask?.cancel()
        }
    }
}

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView

        init(_ parent: CameraPickerView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image.normalizedForPreview(maxDimension: 2048)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

extension UIImage {
    func normalizedForPreview(maxDimension: CGFloat) -> UIImage {
        let sourceSize = size
        guard sourceSize.width > 0, sourceSize.height > 0 else {
            return self
        }

        let longestSide = max(sourceSize.width, sourceSize.height)
        let ratio = min(maxDimension / longestSide, 1)
        let targetSize = CGSize(
            width: sourceSize.width * ratio,
            height: sourceSize.height * ratio
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
