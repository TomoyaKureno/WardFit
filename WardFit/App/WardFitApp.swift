//
//  WardFitApp.swift
//  WardFit
//
//  Created by Fathariq Dimas on 21/04/26.
//

import SwiftUI
import SwiftData

@main
struct WardFitApp: App {
    var body: some Scene {
        WindowGroup {
            SplashGateView()
        }
        .modelContainer(for: ClothingItem.self)
    }
}
