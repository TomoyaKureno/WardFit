//
//  WFColor.swift
//  WardFit
//
//  Created by Fathariq Dimas on 26/04/26.
//

import SwiftUI
import UIKit

enum AppColors {
    static let backgroundBase = adaptive(light: "#F7F2EA", dark: "#18130F")
    static let backgroundSubtle = adaptive(light: "#EFE5D8", dark: "#221A14")

    static let surfaceLevel1 = adaptive(light: "#E7D8C7", dark: "#2B2119")
    static let surfaceLevel2 = adaptive(light: "#DDCAB5", dark: "#35281F")
    static let surfaceLevel3 = adaptive(light: "#D2BCA5", dark: "#413125")

    static let brandPrimary = adaptive(light: "#7F644D", dark: "#C4A385")
    static let brandSecondary = adaptive(light: "#9A7B60", dark: "#A98667")
    static let brandTertiary = adaptive(light: "#6A5241", dark: "#E1C7AC")

    static let textPrimary = adaptive(light: "#35291F", dark: "#F3E8DA")
    static let textSecondary = adaptive(light: "#695544", dark: "#CDB9A4")
    static let textOnBrand = adaptive(light: "#FAF5EF", dark: "#1B130E")

    static let highlightWarm = adaptive(light: "#AE8B6F", dark: "#8F6B4E")
    static let highlightSoft = adaptive(light: "#C2A88F", dark: "#6B503B")
    static let highlightCalm = adaptive(light: "#B59B82", dark: "#7C634F")

    static let borderSoft = adaptive(light: "#D7C3AE", dark: "#493729")
    static let borderStrong = adaptive(light: "#B79D84", dark: "#6C543F")

    private static func adaptive(light: String, dark: String) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark)
                : UIColor(hex: light)
        })
    }
}

enum WFColor {
    static let bg = AppColors.backgroundBase
    static let bgAlt = AppColors.backgroundSubtle
    static let surface = AppColors.surfaceLevel1
    static let surfaceAlt = AppColors.surfaceLevel2
    static let surfaceNested = AppColors.surfaceLevel3
    static let textPrimary = AppColors.textPrimary
    static let textSecondary = AppColors.textSecondary
    static let textOnBrand = AppColors.textOnBrand
    static let accentRose = AppColors.brandPrimary
    static let accentSage = AppColors.highlightCalm
    static let accentDenimSoft = AppColors.brandPrimary
    static let successSoft = AppColors.brandSecondary
    static let borderSoft = AppColors.borderSoft
    static let borderStrong = AppColors.borderStrong
    static let highlightWarm = AppColors.highlightWarm
    static let highlightSoft = AppColors.highlightSoft
}
