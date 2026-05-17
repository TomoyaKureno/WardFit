import Foundation

struct ISCCNBSEntry {
    let name: String
    let hueRange: ClosedRange<Double>
    let satRange: ClosedRange<Double>
    let briRange: ClosedRange<Double>
}

enum ISCCNBSColorNamer {
    private static let neutralNames: Set<String> = [
        "White",
        "Light Gray",
        "Medium Gray",
        "Dark Gray",
        "Black"
    ]

    static let entries: [ISCCNBSEntry] = [
        ISCCNBSEntry(name: "White", hueRange: 0...360, satRange: 0...0.05, briRange: 0.90...1.0),
        ISCCNBSEntry(name: "Light Gray", hueRange: 0...360, satRange: 0...0.05, briRange: 0.65...0.90),
        ISCCNBSEntry(name: "Medium Gray", hueRange: 0...360, satRange: 0...0.05, briRange: 0.40...0.65),
        ISCCNBSEntry(name: "Dark Gray", hueRange: 0...360, satRange: 0...0.05, briRange: 0.15...0.40),
        ISCCNBSEntry(name: "Black", hueRange: 0...360, satRange: 0...0.10, briRange: 0...0.15),

        ISCCNBSEntry(name: "Vivid Red", hueRange: 345...360, satRange: 0.7...1.0, briRange: 0.5...1.0),
        ISCCNBSEntry(name: "Vivid Red", hueRange: 0...15, satRange: 0.7...1.0, briRange: 0.5...1.0),
        ISCCNBSEntry(name: "Dark Red", hueRange: 345...360, satRange: 0.4...1.0, briRange: 0.15...0.5),
        ISCCNBSEntry(name: "Dark Red", hueRange: 0...15, satRange: 0.4...1.0, briRange: 0.15...0.5),
        ISCCNBSEntry(name: "Light Pink", hueRange: 345...360, satRange: 0.1...0.4, briRange: 0.7...1.0),
        ISCCNBSEntry(name: "Light Pink", hueRange: 0...15, satRange: 0.1...0.4, briRange: 0.7...1.0),

        ISCCNBSEntry(name: "Vivid Orange", hueRange: 15...45, satRange: 0.7...1.0, briRange: 0.6...1.0),
        ISCCNBSEntry(name: "Deep Orange", hueRange: 15...45, satRange: 0.5...1.0, briRange: 0.3...0.6),
        ISCCNBSEntry(name: "Light Orange", hueRange: 15...45, satRange: 0.2...0.5, briRange: 0.7...1.0),

        ISCCNBSEntry(name: "Vivid Yellow", hueRange: 45...70, satRange: 0.6...1.0, briRange: 0.7...1.0),
        ISCCNBSEntry(name: "Dark Yellow", hueRange: 45...70, satRange: 0.4...1.0, briRange: 0.3...0.7),
        ISCCNBSEntry(name: "Pale Yellow", hueRange: 45...70, satRange: 0.1...0.4, briRange: 0.8...1.0),

        ISCCNBSEntry(name: "Yellow Green", hueRange: 70...100, satRange: 0.4...1.0, briRange: 0.4...1.0),
        ISCCNBSEntry(name: "Olive", hueRange: 70...100, satRange: 0.2...0.6, briRange: 0.2...0.5),

        ISCCNBSEntry(name: "Vivid Green", hueRange: 100...160, satRange: 0.6...1.0, briRange: 0.5...1.0),
        ISCCNBSEntry(name: "Dark Green", hueRange: 100...160, satRange: 0.3...1.0, briRange: 0.1...0.5),
        ISCCNBSEntry(name: "Light Green", hueRange: 100...160, satRange: 0.1...0.4, briRange: 0.7...1.0),

        ISCCNBSEntry(name: "Vivid Teal", hueRange: 160...200, satRange: 0.5...1.0, briRange: 0.4...1.0),
        ISCCNBSEntry(name: "Dark Teal", hueRange: 160...200, satRange: 0.3...1.0, briRange: 0.1...0.4),

        ISCCNBSEntry(name: "Vivid Blue", hueRange: 200...260, satRange: 0.6...1.0, briRange: 0.5...1.0),
        ISCCNBSEntry(name: "Dark Blue", hueRange: 200...260, satRange: 0.4...1.0, briRange: 0.1...0.5),
        ISCCNBSEntry(name: "Light Blue", hueRange: 200...260, satRange: 0.1...0.5, briRange: 0.7...1.0),
        ISCCNBSEntry(name: "Navy", hueRange: 220...250, satRange: 0.5...1.0, briRange: 0.1...0.35),

        ISCCNBSEntry(name: "Vivid Purple", hueRange: 260...300, satRange: 0.5...1.0, briRange: 0.4...1.0),
        ISCCNBSEntry(name: "Dark Purple", hueRange: 260...300, satRange: 0.3...1.0, briRange: 0.1...0.4),
        ISCCNBSEntry(name: "Light Purple", hueRange: 260...300, satRange: 0.1...0.4, briRange: 0.7...1.0),

        ISCCNBSEntry(name: "Vivid Magenta", hueRange: 300...345, satRange: 0.5...1.0, briRange: 0.5...1.0),
        ISCCNBSEntry(name: "Deep Magenta", hueRange: 300...345, satRange: 0.4...1.0, briRange: 0.15...0.5),
        ISCCNBSEntry(name: "Light Pink", hueRange: 300...345, satRange: 0.1...0.4, briRange: 0.7...1.0),

        ISCCNBSEntry(name: "Light Brown", hueRange: 15...45, satRange: 0.3...0.7, briRange: 0.4...0.65),
        ISCCNBSEntry(name: "Dark Brown", hueRange: 15...45, satRange: 0.3...0.8, briRange: 0.1...0.4),
        ISCCNBSEntry(name: "Cream", hueRange: 30...60, satRange: 0.1...0.3, briRange: 0.85...1.0),
        ISCCNBSEntry(name: "Beige", hueRange: 30...50, satRange: 0.1...0.3, briRange: 0.7...0.85),
        ISCCNBSEntry(name: "Khaki", hueRange: 40...55, satRange: 0.2...0.5, briRange: 0.5...0.75)
    ]

    static func name(hue: Double, saturation: Double, brightness: Double) -> String {
        let normalizedHue = normalizeHue(hue)
        let sat = clamp01(saturation)
        let bri = clamp01(brightness)

        if let neutral = neutralName(saturation: sat, brightness: bri) {
            return neutral
        }

        if let earthTone = earthToneName(hue: normalizedHue, saturation: sat, brightness: bri) {
            return earthTone
        }

        if (220...250).contains(normalizedHue), sat >= 0.55, bri <= 0.34 {
            return "Navy"
        }

        let chromaticEntries = entries.filter { !neutralNames.contains($0.name) }
        guard let bestEntry = chromaticEntries.min(by: {
            score(for: $0, hue: normalizedHue, saturation: sat, brightness: bri) <
                score(for: $1, hue: normalizedHue, saturation: sat, brightness: bri)
        }) else {
            return "Unknown"
        }

        return bestEntry.name
    }

    private static func neutralName(saturation: Double, brightness: Double) -> String? {
        if brightness <= 0.12 && saturation <= 0.36 {
            return "Black"
        }

        let neutralThreshold: Double
        if brightness < 0.24 {
            neutralThreshold = 0.34
        } else if brightness < 0.48 {
            neutralThreshold = 0.24
        } else if brightness < 0.72 {
            neutralThreshold = 0.16
        } else if brightness < 0.78 {
            neutralThreshold = 0.12
        } else {
            neutralThreshold = 0.10
        }

        guard saturation <= neutralThreshold else {
            return nil
        }

        if brightness >= 0.92 {
            return "White"
        }
        if brightness >= 0.70 {
            return "Light Gray"
        }
        if brightness >= 0.32 {
            return "Medium Gray"
        }
        return "Dark Gray"
    }

    private static func earthToneName(hue: Double, saturation: Double, brightness: Double) -> String? {
        if (24...68).contains(hue), saturation <= 0.36 {
            if brightness >= 0.86 {
                return "Cream"
            }
            if brightness >= 0.58 {
                return "Beige"
            }
            if brightness >= 0.34 {
                return "Khaki"
            }
        }

        if (14...48).contains(hue), saturation >= 0.18, saturation <= 0.70, brightness <= 0.62 {
            return brightness < 0.35 ? "Dark Brown" : "Light Brown"
        }

        if (55...90).contains(hue), saturation <= 0.55, brightness <= 0.55 {
            return "Olive"
        }

        return nil
    }

    private static func score(
        for entry: ISCCNBSEntry,
        hue: Double,
        saturation: Double,
        brightness: Double
    ) -> Double {
        let hMid = midpoint(of: entry.hueRange)
        let sMid = midpoint(of: entry.satRange)
        let bMid = midpoint(of: entry.briRange)

        let hueDistance = wrappedHueDistance(hue, hMid) / 180.0
        let satDistance = abs(saturation - sMid)
        let briDistance = abs(brightness - bMid)

        let hueWeight = 0.20 + (saturation * 0.50)
        var score =
            (hueDistance * hueWeight) +
            (satDistance * 0.42) +
            (briDistance * 0.32)

        let hueMiss = hueRangeMiss(hue, range: entry.hueRange) / 180.0
        let satMiss = rangeMiss(saturation, range: entry.satRange)
        let briMiss = rangeMiss(brightness, range: entry.briRange)

        score += (hueMiss * 0.75) + (satMiss * 0.45) + (briMiss * 0.45)
        score += semanticPenalty(
            name: entry.name,
            hue: hue,
            saturation: saturation,
            brightness: brightness
        )

        return score
    }

    private static func semanticPenalty(
        name: String,
        hue: Double,
        saturation: Double,
        brightness: Double
    ) -> Double {
        var penalty = 0.0

        if name.contains("Vivid") {
            if saturation < 0.64 {
                penalty += (0.64 - saturation) * 1.35
            }
            if brightness < 0.40 {
                penalty += (0.40 - brightness) * 1.0
            }
        }

        if name.contains("Dark") || name == "Navy" {
            if brightness > 0.52 {
                penalty += (brightness - 0.52) * 1.1
            }
        }

        if name.contains("Light") || name.contains("Pale") || name == "Cream" || name == "White" {
            if brightness < 0.66 {
                penalty += (0.66 - brightness) * 1.0
            }
        }

        if name == "Navy" {
            penalty += (hueRangeMiss(hue, range: 220...250) / 180.0) * 1.0
            if brightness > 0.42 {
                penalty += (brightness - 0.42) * 1.2
            }
        }

        if name.contains("Pink") {
            let redDistance = min(
                wrappedHueDistance(hue, 0),
                wrappedHueDistance(hue, 340)
            ) / 180.0
            penalty += redDistance * 0.45
            if saturation > 0.55 {
                penalty += (saturation - 0.55) * 0.6
            }
        }

        if name.contains("Brown") || name == "Khaki" || name == "Beige" || name == "Cream" || name == "Olive" {
            penalty += (hueRangeMiss(hue, range: 15...90) / 180.0) * 0.9
        }

        return penalty
    }

    private static func midpoint(of range: ClosedRange<Double>) -> Double {
        (range.lowerBound + range.upperBound) / 2
    }

    private static func rangeMiss(_ value: Double, range: ClosedRange<Double>) -> Double {
        if range.contains(value) {
            return 0
        }
        return min(abs(value - range.lowerBound), abs(value - range.upperBound))
    }

    private static func hueRangeMiss(_ hue: Double, range: ClosedRange<Double>) -> Double {
        if range.contains(hue) {
            return 0
        }
        return min(
            wrappedHueDistance(hue, range.lowerBound),
            wrappedHueDistance(hue, range.upperBound)
        )
    }

    private static func wrappedHueDistance(_ lhs: Double, _ rhs: Double) -> Double {
        let delta = abs(lhs - rhs).truncatingRemainder(dividingBy: 360)
        return min(delta, 360 - delta)
    }

    private static func normalizeHue(_ hue: Double) -> Double {
        let normalized = hue.truncatingRemainder(dividingBy: 360)
        return normalized < 0 ? normalized + 360 : normalized
    }

    private static func clamp01(_ value: Double) -> Double {
        max(0, min(1, value))
    }
}
