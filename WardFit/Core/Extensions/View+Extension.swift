//
//  View+Extension.swift
//  WardFit
//
//  Created by Fathariq Dimas on 26/04/26.
//

import SwiftUI

extension View {
    func wfCardBackground() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: WFRadius.lg, style: .continuous)
                    .fill(WFColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: WFRadius.lg, style: .continuous)
                            .stroke(WFColor.borderSoft, lineWidth: 1)
                    )
                    .shadow(color: WFShadow.color, radius: WFShadow.radius, x: 0, y: WFShadow.y)
            )
    }

    func wfScreenContentPadding() -> some View {
        self
            .padding(.horizontal, WFLayout.screenHorizontalPadding)
            .padding(.top, WFLayout.screenTopPadding)
            .padding(.bottom, WFLayout.screenBottomPadding)
    }
}
