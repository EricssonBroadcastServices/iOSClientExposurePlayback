//
//  TrackSelectionViewModel.swift
//  iOSReferenceApp
//
//  Created by Fredrik Sjöberg on 2018-03-12.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

class TrackSelectionViewModel: Equatable {
    let model: TrackModel?
    
    init(model: TrackModel?) {
        self.model = model
    }
    
    var displayName: String {
        return model?.displayName ?? "Off"
    }
    
    public static func == (lhs: TrackSelectionViewModel, rhs: TrackSelectionViewModel) -> Bool {
        return lhs.model?.extendedLanguageTag == rhs.model?.extendedLanguageTag
    }
}
