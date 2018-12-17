//
//  UIViewController+Toast.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2018-12-17.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit

extension UIViewController {
    
    /// Show a message as a toast
    ///
    /// - Parameters:
    ///   - message: message need to be shown
    ///   - duration: duration the toast should be shown
    func showToastMessage(message: String, duration: TimeInterval) {
        let toastLabel = UILabel(frame: CGRect(x: 0, y: self.view.frame.size.height-150, width: (self.view.frame.width - 10), height: 100))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "TrebuchetMS", size: 12.0)
        toastLabel.text = message
        toastLabel.numberOfLines = 0
        toastLabel.alpha = 1.0
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: duration, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}
