//
//  AppCoordinator.swift
//  WardFit
//
//  Created by Fathariq Dimas on 26/04/26.
//

import SwiftUI
import Combine

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var selectedTab: AppTabRoute = .wardrobe

    let savedForLaterCoordinator: SavedForLaterCoordinator
    let wardrobeCoordinator: WardrobeCoordinator
    let wardrobeSearchCoordinator: WardrobeCoordinator

    init() {
        self.savedForLaterCoordinator = SavedForLaterCoordinator()
        self.wardrobeCoordinator = WardrobeCoordinator()
        self.wardrobeSearchCoordinator = WardrobeCoordinator()
    }
}
