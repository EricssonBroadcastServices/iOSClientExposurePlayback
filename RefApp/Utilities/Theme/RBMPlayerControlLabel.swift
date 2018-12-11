//
//  RBMPlayerControlLabel.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2018-11-28.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit


/// Custom UILabel for playercontrols
class RBMPlayerControlLabel: UILabel {
    
    private var labelText: String
    
    required init(labelText: String) {
        self.labelText = labelText
        super.init(frame: .zero)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.text = labelText
        self.textColor = ColorState.active.textFieldPlaceholder
        self.font = self.font.withSize(11)
    }
    
}
