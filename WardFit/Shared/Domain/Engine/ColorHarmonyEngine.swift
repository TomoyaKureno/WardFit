import Foundation

enum HarmonyType: String, CaseIterable {
    case neutralBalance = "Neutral Balance"
    case monochromatic = "Monochromatic"
    case analogous = "Analogous"
    case complementary = "Complementary"
    case splitComplementary = "Split Complementary"
    case triadic = "Triadic"
}

struct HarmonyMatchResult: Identifiable {
    let id: UUID
    let candidateID: UUID
    let harmonyType: HarmonyType
    let rawScore: Double

    var percentage: Int {
        Int(rawScore * 100)
    }

    var label: String {
        switch percentage {
        case 80...100:
            return "Best Match"
        case 60..<80:
            return "Good Match"
        case 40..<60:
            return "Recommended"
        default:
            return "Possible"
        }
    }

    init(candidateID: UUID, harmonyType: HarmonyType, rawScore: Double) {
        self.id = UUID()
        self.candidateID = candidateID
        self.harmonyType = harmonyType
        self.rawScore = rawScore
    }
}

enum ColorHarmonyEngine {
    static func findMatches(
        sourceHue: Double,
        sourceSat: Double,
        sourceBri: Double,
        candidates: [(id: UUID, hue: Double, sat: Double, bri: Double)]
    ) -> [HarmonyMatchResult] {
        candidates.compactMap { candidate in
            guard let best = bestHarmony(
                srcH: sourceHue,
                srcS: sourceSat,
                srcB: sourceBri,
                canH: candidate.hue,
                canS: candidate.sat,
                canB: candidate.bri
            ) else {
                return nil
            }

            return HarmonyMatchResult(
                candidateID: candidate.id,
                harmonyType: best.type,
                rawScore: best.score
            )
        }
        .filter { $0.rawScore > 0.05 }
        .sorted { $0.rawScore > $1.rawScore }
    }

    private static func bestHarmony(
        srcH: Double,
        srcS: Double,
        srcB: Double,
        canH: Double,
        canS: Double,
        canB: Double
    ) -> (type: HarmonyType, score: Double)? {
        let source = ColorProfile(hue: srcH, saturation: srcS, brightness: srcB)
        let candidate = ColorProfile(hue: canH, saturation: canS, brightness: canB)

        if source.isNeutral || candidate.isNeutral {
            let score = neutralBalanceScore(source: source, candidate: candidate)
            return score > 0 ? (.neutralBalance, score) : nil
        }

        let results: [(HarmonyType, Double)] = [
            (.monochromatic, monochromaticScore(source: source, candidate: candidate)),
            (.analogous, analogousScore(source: source, candidate: candidate)),
            (.complementary, complementaryScore(source: source, candidate: candidate)),
            (.splitComplementary, splitComplementaryScore(source: source, candidate: candidate)),
            (.triadic, triadicScore(source: source, candidate: candidate))
        ]

        guard let best = results.max(by: { $0.1 < $1.1 }), best.1 > 0 else {
            return nil
        }

        return (best.0, best.1)
    }

    private static func hueDiff(_ a: Double, _ b: Double) -> Double {
        let diff = abs(a - b).truncatingRemainder(dividingBy: 360)
        return min(diff, 360 - diff)
    }

    private static func scoreNearHue(
        targetHue: Double,
        candidateHue: Double,
        tolerance: Double
    ) -> Double {
        let hueDistance = hueDiff(targetHue, candidateHue)
        guard hueDistance <= tolerance else { return 0 }
        return 1.0 - (hueDistance / tolerance)
    }

    private static func wearableScore(
        hueScore: Double,
        source: ColorProfile,
        candidate: ColorProfile,
        saturationWeight: Double = 0.18,
        brightnessWeight: Double = 0.16,
        contrastBonusWeight: Double = 0.10
    ) -> Double {
        guard hueScore > 0 else { return 0 }

        let saturationPenalty = abs(source.saturation - candidate.saturation) * saturationWeight
        let brightnessPenalty = abs(source.brightness - candidate.brightness) * brightnessWeight
        let valueContrast = abs(source.brightness - candidate.brightness)
        let contrastBonus = min(valueContrast, 0.45) * contrastBonusWeight
        let overSaturationPenalty = max(source.saturation + candidate.saturation - 1.55, 0) * 0.18

        return clamp(
            hueScore - saturationPenalty - brightnessPenalty - overSaturationPenalty + contrastBonus
        )
    }

    private static func neutralBalanceScore(source: ColorProfile, candidate: ColorProfile) -> Double {
        let neutral = source.isNeutral ? source : candidate
        let accent = source.isNeutral ? candidate : source
        let valueContrast = abs(neutral.brightness - accent.brightness)
        let contrastScore = 0.55 + min(valueContrast, 0.55) * 0.55

        if source.isNeutral && candidate.isNeutral {
            let brightnessGap = abs(source.brightness - candidate.brightness)
            let saturationGap = abs(source.saturation - candidate.saturation)
            return clamp(0.58 + min(brightnessGap, 0.55) * 0.55 - saturationGap * 0.20)
        }

        let neutralVersatility = 1.0 - min(neutral.saturation / 0.28, 1.0) * 0.18
        let accentStrength = 0.90 + min(accent.saturation, 0.75) * 0.12
        return clamp(contrastScore * neutralVersatility * accentStrength)
    }

    private static func monochromaticScore(source: ColorProfile, candidate: ColorProfile) -> Double {
        let hueScore = scoreNearHue(targetHue: source.hue, candidateHue: candidate.hue, tolerance: 14.0)
        guard hueScore > 0 else { return 0 }

        let valueVariation = abs(source.brightness - candidate.brightness)
        let saturationVariation = abs(source.saturation - candidate.saturation)
        let variationBonus = min((valueVariation * 0.35) + (saturationVariation * 0.18), 0.18)

        return clamp(
            wearableScore(
                hueScore: hueScore,
                source: source,
                candidate: candidate,
                saturationWeight: 0.12,
                brightnessWeight: 0.08,
                contrastBonusWeight: 0.06
            ) + variationBonus
        )
    }

    private static func analogousScore(source: ColorProfile, candidate: ColorProfile) -> Double {
        let hueDistance = hueDiff(source.hue, candidate.hue)
        guard hueDistance > 10, hueDistance <= 42 else { return 0 }

        let hueScore = 1.0 - ((hueDistance - 10) / 32)
        return wearableScore(hueScore: hueScore, source: source, candidate: candidate)
    }

    private static func complementaryScore(source: ColorProfile, candidate: ColorProfile) -> Double {
        let target = (source.hue + 180).truncatingRemainder(dividingBy: 360)
        let hueScore = scoreNearHue(targetHue: target, candidateHue: candidate.hue, tolerance: 22.0)
        return wearableScore(hueScore: hueScore, source: source, candidate: candidate)
    }

    private static func splitComplementaryScore(source: ColorProfile, candidate: ColorProfile) -> Double {
        let targetA = (source.hue + 150).truncatingRemainder(dividingBy: 360)
        let targetB = (source.hue + 210).truncatingRemainder(dividingBy: 360)
        let hueScore = max(
            scoreNearHue(targetHue: targetA, candidateHue: candidate.hue, tolerance: 22.0),
            scoreNearHue(targetHue: targetB, candidateHue: candidate.hue, tolerance: 22.0)
        )
        return wearableScore(hueScore: hueScore, source: source, candidate: candidate)
    }

    private static func triadicScore(source: ColorProfile, candidate: ColorProfile) -> Double {
        let targetA = (source.hue + 120).truncatingRemainder(dividingBy: 360)
        let targetB = (source.hue + 240).truncatingRemainder(dividingBy: 360)
        let hueScore = max(
            scoreNearHue(targetHue: targetA, candidateHue: candidate.hue, tolerance: 20.0),
            scoreNearHue(targetHue: targetB, candidateHue: candidate.hue, tolerance: 20.0)
        )
        return wearableScore(hueScore: hueScore, source: source, candidate: candidate)
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

private struct ColorProfile {
    let hue: Double
    let saturation: Double
    let brightness: Double

    var isNeutral: Bool {
        saturation <= neutralSaturationLimit || brightness <= 0.12 || brightness >= 0.96
    }

    private var neutralSaturationLimit: Double {
        switch brightness {
        case ..<0.25:
            return 0.22
        case 0.25..<0.75:
            return 0.14
        default:
            return 0.18
        }
    }
}
