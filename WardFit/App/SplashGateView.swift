//
//  SplashGateView.swift
//  WardFit
//
//  Created by Fathariq Dimas on 28/04/26.
//

import SwiftUI

struct SplashGateView: View {
    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            RootView()
                .opacity(isShowingSplash ? 0 : 1)

            if isShowingSplash {
                SplashScreenView()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
                    .zIndex(1)
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(2_000))

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.45)) {
                    isShowingSplash = false
                }
            }
        }
    }
}

private struct SplashScreenView: View {
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            background

            VStack(spacing: WFSpacing.xxl) {
                Spacer()

                brandMark

                VStack(spacing: WFSpacing.xs) {
                    Text("WardFit")
                        .font(.system(size: 46, weight: .heavy, design: .rounded))
                        .foregroundStyle(WFColor.textPrimary)
                        .tracking(-1.5)

                    Text("Your wardrobe, styled smarter.")
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .foregroundStyle(WFColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 16)

                Spacer()

                loadingIndicator
            }
            .padding(.horizontal, WFSpacing.xxl)
            .padding(.vertical, WFSpacing.xxl)
        }
        .onAppear {
            withAnimation(.spring(response: 0.75, dampingFraction: 0.78)) {
                hasAppeared = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("WardFit loading")
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    WFColor.bg,
                    WFColor.bgAlt,
                    WFColor.surface.opacity(0.75)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(WFColor.highlightWarm.opacity(0.22))
                .frame(width: 260, height: 260)
                .blur(radius: 10)
                .offset(x: -130, y: -260)

            Circle()
                .fill(WFColor.highlightSoft.opacity(0.24))
                .frame(width: 320, height: 320)
                .blur(radius: 14)
                .offset(x: 140, y: 260)

            RoundedRectangle(cornerRadius: 80, style: .continuous)
                .stroke(WFColor.borderSoft.opacity(0.35), lineWidth: 1)
                .frame(width: 260, height: 420)
                .rotationEffect(.degrees(-16))
                .offset(x: 150, y: -120)
        }
    }

    private var brandMark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(WFColor.surface.opacity(0.82))
                .frame(width: 148, height: 148)
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(WFColor.borderStrong.opacity(0.55), lineWidth: 1)
                )
                .shadow(color: WFShadow.color.opacity(1.5), radius: 22, x: 0, y: 14)

            Image("splashAppIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 118, height: 118)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .scaleEffect(hasAppeared ? 1 : 0.78)

            Image(systemName: "sparkles")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(WFColor.highlightWarm)
                .offset(x: 44, y: -44)
                .opacity(hasAppeared ? 1 : 0)
                .scaleEffect(hasAppeared ? 1 : 0.4)
        }
    }

    private var loadingIndicator: some View {
        HStack(spacing: WFSpacing.xs) {
            ForEach(0..<3, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(WFColor.accentRose.opacity(index == 1 ? 0.85 : 0.45))
                    .frame(width: index == 1 ? 22 : 8, height: 8)
            }
        }
        .opacity(hasAppeared ? 1 : 0)
        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: hasAppeared)
    }
}

#Preview {
    SplashScreenView()
}
