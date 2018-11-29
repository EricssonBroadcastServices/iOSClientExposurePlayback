//
//  UITableView+EmptyMessage.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2018-11-21.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit

extension UITableView {
    
    
    /// Show empty message when there is no data to show in the UITableView
    ///
    /// - Parameter message: message need to be shown
    func showEmptyMessage(message: String) {
        let rect = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width:
            self.bounds.size.width, height: self.bounds.size.height))
        let messageLabel = UILabel(frame: rect)
        messageLabel.text = message
        messageLabel.textColor = ColorState.active.text
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = .center;
        messageLabel.font = UIFont(name: "TrebuchetMS", size: 15)
        messageLabel.sizeToFit()
        
        self.backgroundView = messageLabel
    }
    
    
    /// Hide empty message when there is data available to show
    func hideEmptyMessage() {
        let rect = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width:
            self.bounds.size.width, height: self.bounds.size.height))
        let view = UIView(frame: rect)
        view.backgroundColor = ColorState.active.background
        self.backgroundView = .none
    }
}
