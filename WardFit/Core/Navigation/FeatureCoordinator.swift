//
//  FeatureCoordinator.swift
//  WardFit
//
//  Created by Fathariq Dimas on 27/04/26.
//

import Combine
import SwiftUI

@MainActor
class FeatureCoordinator<Route: Hashable>: ObservableObject {
    @Published var path = NavigationPath()

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard path.count > 0 else { return }

        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
