//
//  SavedForLaterRoute.swift
//  WardFit
//
//  Created by Codex on 27/04/26.
//

import Foundation

enum SavedForLaterRoute: Hashable {
    case wardrobeDetail(itemID: UUID)
    case wardrobeItemDetail(itemID: UUID)
    case scanClothes
    case scanCamera
    case scanResult(candidateID: UUID)
    case scanCandidateDetail(candidateID: UUID)
}
