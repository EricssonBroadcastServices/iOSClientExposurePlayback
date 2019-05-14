//
//  MainNavigationController.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2018-11-21.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit
import Exposure


/// Handles the main navigagion in the app
class MainNavigationController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationBar.tintColor = ColorState.active.textFieldPlaceholder
        self.navigationBar.barTintColor = ColorState.active.background
        self.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: ColorState.active.textFieldPlaceholder]
        
        if StorageProvider.storedSessionToken != nil {
            let assetlistViewController = SelectionTableViewController()
            viewControllers = [assetlistViewController]
        } else {
            perform(#selector(showLoginController), with: nil, afterDelay: 0.01)
        }
    }
    
    
    /// Show Enviornment view if user not logged in 
    @objc func showLoginController() {
        let environmentViewController = EnvironmentViewController()
        viewControllers = [environmentViewController]
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
}
