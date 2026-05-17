import SwiftUI

enum ColorScopeConfig {
    static let normalizedRect = CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4)
}

struct ColorScopeOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let scopeRect = CGRect(
                x: size.width * ColorScopeConfig.normalizedRect.origin.x,
                y: size.height * ColorScopeConfig.normalizedRect.origin.y,
                width: size.width * ColorScopeConfig.normalizedRect.width,
                height: size.height * ColorScopeConfig.normalizedRect.height
            )

            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        .white.opacity(0.95),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [8, 6])
                    )
                    .frame(width: scopeRect.width, height: scopeRect.height)
                    .position(x: scopeRect.midX, y: scopeRect.midY)

                Text("Align item in the guide")
                    .font(WFType.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, WFSpacing.sm)
                    .padding(.vertical, WFSpacing.xxs)
                    .background(.black.opacity(0.45), in: Capsule())
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, WFSpacing.sm)
            }
        }
        .allowsHitTesting(false)
    }
}

struct InteractiveScopePhotoView: View {
    let image: UIImage
    var height: CGFloat = 220
    var initialScale: CGFloat? = nil
    var initialOffset: CGSize? = nil
    var onScopeRectChanged: (CGRect) -> Void
    var onRenderStateChanged: ((ScopedPhotoRenderState) -> Void)? = nil

    @State private var baseScale: CGFloat = 1
    @State private var baseOffset: CGSize = .zero
    @State private var didApplyInitialTransform = false
    @GestureState private var gestureTransform = GestureTransform.identity

    private let minScale: CGFloat = 1
    private let maxScale: CGFloat = 4

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let liveScale = (baseScale * gestureTransform.scale).clamped(to: minScale...maxScale)
            let liveOffset = clampedOffset(
                CGSize(
                    width: baseOffset.width + gestureTransform.translation.width,
                    height: baseOffset.height + gestureTransform.translation.height
                ),
                scale: liveScale,
                in: size
            )

            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .scaleEffect(liveScale)
                    .offset(liveOffset)

                ColorScopeOverlay()
            }
            .frame(width: size.width, height: size.height)
            .clipped()
            .contentShape(Rectangle())
            .gesture(combinedGesture(size: size))
            .onAppear {
                let initialTransform = applyInitialTransformIfNeeded(in: size)
                notifyState(
                    in: size,
                    scale: initialTransform?.scale ?? liveScale,
                    offset: initialTransform?.offset ?? liveOffset
                )
            }
            .onChange(of: gestureTransform) { _, _ in
                notifyState(in: size, scale: liveScale, offset: liveOffset)
            }
            .onChange(of: size) { _, newSize in
                baseOffset = clampedOffset(baseOffset, scale: baseScale, in: newSize)
                notifyState(in: newSize, scale: baseScale, offset: baseOffset)
            }
        }
        .frame(height: height)
    }

    private func combinedGesture(size: CGSize) -> some Gesture {
        SimultaneousGesture(
            DragGesture(minimumDistance: 3),
            MagnificationGesture()
        )
        .updating($gestureTransform) { value, state, _ in
            state.translation = value.first?.translation ?? .zero
            state.scale = value.second ?? 1
        }
        .onEnded { value in
            let committedScale = (baseScale * (value.second ?? 1)).clamped(to: minScale...maxScale)
            let candidateOffset = CGSize(
                width: baseOffset.width + (value.first?.translation.width ?? 0),
                height: baseOffset.height + (value.first?.translation.height ?? 0)
            )
            let committedOffset = clampedOffset(candidateOffset, scale: committedScale, in: size)

            baseScale = committedScale
            baseOffset = committedOffset
            notifyState(in: size, scale: committedScale, offset: committedOffset)
        }
    }

    private func applyInitialTransformIfNeeded(in size: CGSize) -> (scale: CGFloat, offset: CGSize)? {
        guard !didApplyInitialTransform else { return nil }
        didApplyInitialTransform = true

        let restoredScale = (initialScale ?? minScale).clamped(to: minScale...maxScale)
        let restoredOffset = clampedOffset(initialOffset ?? .zero, scale: restoredScale, in: size)

        baseScale = restoredScale
        baseOffset = restoredOffset
        return (restoredScale, restoredOffset)
    }

    private func clampedOffset(_ candidate: CGSize, scale: CGFloat, in size: CGSize) -> CGSize {
        guard size.width > 0, size.height > 0 else {
            return .zero
        }

        let fitted = fittedImageSize(in: size)
        let renderedWidth = fitted.width * scale
        let renderedHeight = fitted.height * scale

        let maxX = max((renderedWidth - size.width) / 2, 0)
        let maxY = max((renderedHeight - size.height) / 2, 0)

        return CGSize(
            width: candidate.width.clamped(to: -maxX...maxX),
            height: candidate.height.clamped(to: -maxY...maxY)
        )
    }

    private func fittedImageSize(in viewport: CGSize) -> CGSize {
        guard image.size.width > 0, image.size.height > 0 else {
            return viewport
        }

        let baseScale = max(viewport.width / image.size.width, viewport.height / image.size.height)

        return CGSize(
            width: image.size.width * baseScale,
            height: image.size.height * baseScale
        )
    }

    private func notifyState(in size: CGSize, scale: CGFloat, offset: CGSize) {
        guard size.width > 0, size.height > 0 else {
            onScopeRectChanged(ColorScopeConfig.normalizedRect)
            return
        }

        let fitted = fittedImageSize(in: size)
        let renderedWidth = fitted.width * scale
        let renderedHeight = fitted.height * scale

        guard renderedWidth > 0, renderedHeight > 0 else {
            onScopeRectChanged(ColorScopeConfig.normalizedRect)
            return
        }

        let imageOriginX = (size.width - renderedWidth) / 2 + offset.width
        let imageOriginY = (size.height - renderedHeight) / 2 + offset.height

        let scopeInView = CGRect(
            x: size.width * ColorScopeConfig.normalizedRect.origin.x,
            y: size.height * ColorScopeConfig.normalizedRect.origin.y,
            width: size.width * ColorScopeConfig.normalizedRect.width,
            height: size.height * ColorScopeConfig.normalizedRect.height
        )

        let normalizedRect = CGRect(
            x: (scopeInView.origin.x - imageOriginX) / renderedWidth,
            y: (scopeInView.origin.y - imageOriginY) / renderedHeight,
            width: scopeInView.width / renderedWidth,
            height: scopeInView.height / renderedHeight
        )

        let clampedRect = normalizedRect.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
        onScopeRectChanged(clampedRect.isEmpty ? ColorScopeConfig.normalizedRect : clampedRect)

        onRenderStateChanged?(
            ScopedPhotoRenderState(
                previewImage: renderPreviewImage(in: size, scale: scale, offset: offset),
                scale: Double(scale),
                offsetX: Double(offset.width),
                offsetY: Double(offset.height),
                viewportWidth: Double(size.width),
                viewportHeight: Double(size.height)
            )
        )
    }

    private func renderPreviewImage(in size: CGSize, scale: CGFloat, offset: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(WFColor.surfaceNested).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let fitted = fittedImageSize(in: size)
            let renderedSize = CGSize(width: fitted.width * scale, height: fitted.height * scale)
            let drawRect = CGRect(
                x: (size.width - renderedSize.width) / 2 + offset.width,
                y: (size.height - renderedSize.height) / 2 + offset.height,
                width: renderedSize.width,
                height: renderedSize.height
            )

            image.draw(in: drawRect)
        }
    }
}

struct ScopedPhotoRenderState {
    let previewImage: UIImage
    let scale: Double
    let offsetX: Double
    let offsetY: Double
    let viewportWidth: Double
    let viewportHeight: Double
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

private struct GestureTransform: Equatable {
    var scale: CGFloat
    var translation: CGSize

    static let identity = GestureTransform(scale: 1, translation: .zero)
}

#Preview {
    ZStack {
        Rectangle().fill(.gray)
        ColorScopeOverlay()
    }
    .frame(height: 220)
    .padding()
}
