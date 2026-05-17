import AVFoundation
import Combine
import SwiftUI
import UIKit

struct CustomCameraView: View {
    let onCancel: () -> Void
    let onCapture: (UIImage) -> Void

    @StateObject private var camera = CameraCaptureViewModel()

    var body: some View {
        ZStack {
            WFColor.bg.ignoresSafeArea()

            switch camera.state {
            case .ready:
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()
                    .overlay(cameraGuide)
            case .denied:
                unavailableContent(
                    title: "Camera access needed",
                    message: "Enable camera access in Settings to scan clothing directly."
                )
            case .unavailable:
                unavailableContent(
                    title: "Camera unavailable",
                    message: "This device or simulator does not have an available camera."
                )
            case .checking:
                ProgressView("Preparing camera...")
                    .foregroundStyle(WFColor.textPrimary)
            }

            VStack {
                topBar
                lightingTipCard
                Spacer()
                bottomBar
            }
            .padding(.horizontal, WFLayout.screenHorizontalPadding)
            .padding(.vertical, WFSpacing.lg)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            camera.onCapture = onCapture
            camera.prepare()
        }
        .onDisappear {
            camera.stop()
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: onCancel) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(WFColor.textPrimary)
                    .frame(width: 54, height: 54)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Camera")
                .font(WFType.bodyMedium)
                .foregroundStyle(.white)
                .padding(.horizontal, WFSpacing.md)
                .padding(.vertical, WFSpacing.xs)
                .background(
                    Capsule(style: .continuous)
                        .fill(.black.opacity(0.36))
                )

            Spacer()

            Color.clear
                .frame(width: 54, height: 54)
        }
    }

    private var cameraGuide: some View {
        VStack(spacing: WFSpacing.xl) {
            Text("Align item in the guide")
                .font(WFType.bodyMedium)
                .foregroundStyle(.white)
                .padding(.horizontal, WFSpacing.md)
                .padding(.vertical, WFSpacing.xs)
                .background(
                    Capsule(style: .continuous)
                        .fill(.black.opacity(0.45))
                )

            RoundedRectangle(cornerRadius: WFRadius.lg, style: .continuous)
                .stroke(
                    .white,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [10, 8])
                )
                .frame(width: 210, height: 140)
                .shadow(color: .black.opacity(0.25), radius: 8, y: 2)
        }
    }

    private var lightingTipCard: some View {
        HStack(alignment: .top, spacing: WFSpacing.sm) {
            Image(systemName: "lightbulb.max.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.yellow)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(.black.opacity(0.24))
                )

            VStack(alignment: .leading, spacing: WFSpacing.xxs) {
                Text("Color accuracy tip")
                    .font(WFType.bodyMedium)
                    .foregroundStyle(.white)

                Text("Use bright, even natural light. Avoid harsh shadows, backlight, and mixed indoor lighting.")
                    .font(WFType.caption)
                    .foregroundStyle(.white.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(WFSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: WFRadius.lg, style: .continuous)
                .fill(.black.opacity(0.36))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: WFRadius.lg, style: .continuous))
        )
        .padding(.top, WFSpacing.sm)
    }

    private var bottomBar: some View {
        VStack(spacing: WFSpacing.md) {
            Text("Place the clothing item inside the guide.")
                .font(WFType.caption)
                .foregroundStyle(.white.opacity(0.85))

            Button {
                camera.capture()
            } label: {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.9), lineWidth: 4)
                        .frame(width: 82, height: 82)

                    Circle()
                        .fill(.white)
                        .frame(width: 64, height: 64)
                }
            }
            .buttonStyle(.plain)
            .disabled(camera.state != .ready)
            .opacity(camera.state == .ready ? 1 : 0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, WFSpacing.md)
        .padding(.bottom, WFSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: WFRadius.lg, style: .continuous)
                .fill(.black.opacity(0.28))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: WFRadius.lg, style: .continuous))
        )
    }

    private func unavailableContent(title: String, message: String) -> some View {
        WFEmptyState(
            icon: "camera.fill",
            title: title,
            message: message
        )
        .padding(.horizontal, WFLayout.screenHorizontalPadding)
    }
}

private struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.videoPreviewLayer.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}

private enum CameraState {
    case checking
    case ready
    case denied
    case unavailable
}

private final class CameraCaptureViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var state: CameraState = .checking

    let session = AVCaptureSession()
    var onCapture: ((UIImage) -> Void)?

    private let output = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "WardFit.camera.session")
    private var isConfigured = false

    func prepare() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let viewModel = self else {
                    return
                }

                Task { @MainActor in
                    if granted {
                        viewModel.configureAndStart()
                    } else {
                        viewModel.state = .denied
                    }
                }
            }
        case .denied, .restricted:
            state = .denied
        @unknown default:
            state = .unavailable
        }
    }

    func capture() {
        guard state == .ready else { return }
        output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }

    func stop() {
        sessionQueue.async { [session] in
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    private func configureAndStart() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if !isConfigured {
                guard configureSession() else {
                    Task { @MainActor in self.state = .unavailable }
                    return
                }
            }

            if !session.isRunning {
                session.startRunning()
            }

            Task { @MainActor in self.state = .ready }
        }
    }

    private func configureSession() -> Bool {
        session.beginConfiguration()
        session.sessionPreset = .photo
        defer { session.commitConfiguration() }

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input),
            session.canAddOutput(output)
        else {
            return false
        }

        session.addInput(input)
        session.addOutput(output)
        isConfigured = true
        return true
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard
            error == nil,
            let data = photo.fileDataRepresentation(),
            let image = UIImage(data: data)
        else {
            return
        }

        Task { @MainActor [weak self] in
            self?.onCapture?(image.normalizedForPreview(maxDimension: 2048))
        }
    }
}
