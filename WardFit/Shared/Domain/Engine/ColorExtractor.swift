import CoreGraphics
import UIKit

struct ExtractedColor {
    let hue: Double
    let saturation: Double
    let brightness: Double

    var swiftUIColor: UIColor {
        UIColor(hue: hue / 360.0, saturation: saturation, brightness: brightness, alpha: 1)
    }
}

enum ColorExtractor {
    static func extractColor(from image: UIImage, scopeRect: CGRect) -> ExtractedColor? {
        guard let cgImage = normalizedCGImage(from: image) else { return nil }

        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)

        let cropRect = CGRect(
            x: scopeRect.origin.x * imageWidth,
            y: scopeRect.origin.y * imageHeight,
            width: scopeRect.width * imageWidth,
            height: scopeRect.height * imageHeight
        )
        .intersection(CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))

        guard !cropRect.isEmpty, let cropped = cgImage.cropping(to: cropRect) else {
            return nil
        }

        let sampleSize = 48
        guard let context = CGContext(
            data: nil,
            width: sampleSize,
            height: sampleSize,
            bitsPerComponent: 8,
            bytesPerRow: sampleSize * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cropped, in: CGRect(x: 0, y: 0, width: sampleSize, height: sampleSize))

        guard let data = context.data else { return nil }
        let pixelBuffer = data.bindMemory(to: UInt8.self, capacity: sampleSize * sampleSize * 4)

        let samples = collectSamples(pixelBuffer: pixelBuffer, sampleSize: sampleSize)
        guard !samples.isEmpty else { return nil }

        let clusteringSamples = filteredSamplesForDominantColor(samples)
        let dominant = dominantColorByKMeans(from: clusteringSamples.isEmpty ? samples : clusteringSamples)

        let dominantColor = UIColor(
            red: dominant.r,
            green: dominant.g,
            blue: dominant.b,
            alpha: 1
        )

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        dominantColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        return ExtractedColor(
            hue: Double(hue) * 360,
            saturation: Double(saturation),
            brightness: Double(brightness)
        )
    }

    static func extractCenterColor(from image: UIImage) -> ExtractedColor? {
        extractColor(from: image, scopeRect: CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4))
    }

    private static func normalizedCGImage(from image: UIImage) -> CGImage? {
        if image.imageOrientation == .up, let cgImage = image.cgImage {
            return cgImage
        }

        let renderer = UIGraphicsImageRenderer(size: image.size)
        let normalizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }

        return normalizedImage.cgImage
    }

    private static func collectSamples(pixelBuffer: UnsafePointer<UInt8>, sampleSize: Int) -> [RGBSample] {
        var samples: [RGBSample] = []
        samples.reserveCapacity(sampleSize * sampleSize)

        let totalPixels = sampleSize * sampleSize
        for pixel in 0..<totalPixels {
            let offset = pixel * 4
            let alpha = Double(pixelBuffer[offset + 3]) / 255.0
            guard alpha > 0.05 else { continue }

            let sample = RGBSample(
                r: Double(pixelBuffer[offset]) / 255.0,
                g: Double(pixelBuffer[offset + 1]) / 255.0,
                b: Double(pixelBuffer[offset + 2]) / 255.0
            )
            samples.append(sample)
        }

        return samples
    }

    private static func filteredSamplesForDominantColor(_ samples: [RGBSample]) -> [RGBSample] {
        guard samples.count > 16 else { return samples }

        let sortedBrightness = samples.map(\.brightness).sorted()
        let lowCutoff = sortedBrightness[Int(Double(sortedBrightness.count - 1) * 0.08)]
        let highCutoff = sortedBrightness[Int(Double(sortedBrightness.count - 1) * 0.96)]

        let filtered = samples.filter { sample in
            let isDeepShadow = sample.brightness < max(0.04, lowCutoff) && sample.saturation < 0.18
            let isSpecularHighlight = sample.brightness > min(0.98, highCutoff) && sample.saturation < 0.08
            return !isDeepShadow && !isSpecularHighlight
        }

        return filtered.count >= samples.count / 3 ? filtered : samples
    }

    private static func dominantColorByKMeans(from samples: [RGBSample]) -> RGBSample {
        let clusterCount = max(1, min(5, samples.count / 150 + 2))
        let k = min(clusterCount, samples.count)

        if k <= 1 {
            return average(samples)
        }

        var centroids = initialCentroids(from: samples, k: k)
        var counts = Array(repeating: 0, count: k)

        for _ in 0..<8 {
            var sums = Array(repeating: RGBSample.zero, count: k)
            counts = Array(repeating: 0, count: k)

            for sample in samples {
                let clusterIndex = nearestCluster(for: sample, centroids: centroids)
                sums[clusterIndex].r += sample.r
                sums[clusterIndex].g += sample.g
                sums[clusterIndex].b += sample.b
                counts[clusterIndex] += 1
            }

            for index in 0..<k where counts[index] > 0 {
                let total = Double(counts[index])
                centroids[index] = RGBSample(
                    r: sums[index].r / total,
                    g: sums[index].g / total,
                    b: sums[index].b / total
                )
            }
        }

        guard let dominantIndex = dominantClusterIndex(counts: counts, centroids: centroids),
              counts[dominantIndex] > 0 else {
            return average(samples)
        }

        return centroids[dominantIndex]
    }

    private static func initialCentroids(from samples: [RGBSample], k: Int) -> [RGBSample] {
        guard !samples.isEmpty else { return [] }

        var centroids: [RGBSample] = [samples[samples.count / 2]]
        centroids.reserveCapacity(k)

        while centroids.count < k {
            var bestSample = samples[0]
            var bestDistance = -1.0

            for sample in samples {
                let nearestDistance = centroids.reduce(Double.greatestFiniteMagnitude) { current, centroid in
                    min(current, sample.distanceSquared(to: centroid))
                }
                if nearestDistance > bestDistance {
                    bestDistance = nearestDistance
                    bestSample = sample
                }
            }

            centroids.append(bestSample)
        }

        return centroids
    }

    private static func dominantClusterIndex(counts: [Int], centroids: [RGBSample]) -> Int? {
        guard !counts.isEmpty, counts.count == centroids.count else { return nil }

        return counts.indices
            .filter { counts[$0] > 0 }
            .max(by: { lhs, rhs in
                let countGap = abs(counts[lhs] - counts[rhs])
                if countGap <= max(2, (counts[lhs] + counts[rhs]) / 20) {
                    return centroids[lhs].saturation < centroids[rhs].saturation
                }
                return counts[lhs] < counts[rhs]
            })
    }

    private static func nearestCluster(for sample: RGBSample, centroids: [RGBSample]) -> Int {
        var nearestIndex = 0
        var nearestDistance = Double.greatestFiniteMagnitude

        for index in centroids.indices {
            let distance = sample.distanceSquared(to: centroids[index])
            if distance < nearestDistance {
                nearestDistance = distance
                nearestIndex = index
            }
        }

        return nearestIndex
    }

    private static func average(_ samples: [RGBSample]) -> RGBSample {
        guard !samples.isEmpty else { return .zero }

        let sum = samples.reduce(RGBSample.zero) { partial, sample in
            RGBSample(r: partial.r + sample.r, g: partial.g + sample.g, b: partial.b + sample.b)
        }
        let divisor = Double(samples.count)

        return RGBSample(r: sum.r / divisor, g: sum.g / divisor, b: sum.b / divisor)
    }
}

private struct RGBSample {
    var r: Double
    var g: Double
    var b: Double

    static let zero = RGBSample(r: 0, g: 0, b: 0)

    func distanceSquared(to other: RGBSample) -> Double {
        let dr = r - other.r
        let dg = g - other.g
        let db = b - other.b
        return (dr * dr) + (dg * dg) + (db * db)
    }

    var brightness: Double {
        max(r, max(g, b))
    }

    var saturation: Double {
        let maxValue = brightness
        let minValue = min(r, min(g, b))
        guard maxValue > 0 else { return 0 }
        return (maxValue - minValue) / maxValue
    }
}
