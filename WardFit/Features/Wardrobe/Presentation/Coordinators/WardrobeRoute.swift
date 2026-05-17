//
//  WardrobeRoute.swift
//  WardFit
//
//  Created by Fathariq Dimas on 27/04/26.
//

import Foundation

enum WardrobeRoute: Hashable {
    case wardrobeDetail(itemID: UUID)
    case addItem
    case addItemCamera
    case scanClothes
    case scanCamera
    case scanResult(candidateID: UUID)
    case scanCandidateDetail(candidateID: UUID)
}
