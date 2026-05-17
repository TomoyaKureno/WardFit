//
//  ScanClothesRoute.swift
//  WardFit
//
//  Created by Fathariq Dimas on 27/04/26.
//

import Foundation

enum ScanClothesRoute: Hashable {
    case capture
    case camera
    case result(candidateID: UUID)
    case candidateDetail(candidateID: UUID)
    case wardrobeDetail(itemID: UUID)
}
