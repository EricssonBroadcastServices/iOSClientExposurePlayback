//
//  RBMTextField.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2018-11-20.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit


/// RedBeeMedia Custom UITextField
class RBMTextField: UITextField {
    
    private var placeHolderText: String
    
    required init(placeHolderText: String) {
        self.placeHolderText = placeHolderText
        super.init(frame: .zero)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.borderStyle = .roundedRect
        self.textColor = ColorState.active.textFieldText
        self.backgroundColor = ColorState.active.textFieldBackground
        self.attributedPlaceholder = NSAttributedString(string: placeHolderText, attributes: [NSAttributedString.Key.foregroundColor: ColorState.active.textFieldPlaceholder])
    }
}

