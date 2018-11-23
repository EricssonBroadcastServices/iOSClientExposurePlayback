//
//  RBMButton.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2018-11-21.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit


/// RedBeeMedia Custom UIButton
class RBMButton: UIButton {
    
    private var titleText: String
    
    required init(titleText: String) {
        self.titleText = titleText
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        backgroundColor = UIColor.clear
        setTitle(titleText, for: .normal)
        setTitleColor(UIColor.white, for: .normal)
        layer.borderColor = ColorState.active.textFieldPlaceholder.cgColor
        layer.cornerRadius = 5
        layer.borderWidth = 1
    }
}
