//
//  UIViewController+Alert.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2018-11-21.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit

extension UIViewController {
    
    
    /// Create UIAlert
    ///
    /// - Parameters:
    ///   - title: Title of the alert
    ///   - message: message of the alert
    ///   - actions: any actions need to be added to the alert
    ///   - preferedStyle: prefered alertstyle (ex : alert or actionsheet)
    func popupAlert(title: String?, message: String?, actions:[UIAlertAction?], preferedStyle: UIAlertController.Style = .alert) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: preferedStyle)
        
        if actions.count != 0 {
            for action in actions {
                alert.addAction(action!)
            }
        }
        
        // Show the alert in the middle of the iPad
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        self.present(alert, animated: true, completion: nil)
    }
}

