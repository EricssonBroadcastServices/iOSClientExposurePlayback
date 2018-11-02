//
//  AppDelegate.swift
//  RefApp
//
//  Created by Fredrik Sjöberg on 2018-10-30.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if let image = UIImage(named: "redbee") {
            let logoView = UIImageView(image: image, constrainedByHeight: 40)
            
            if let root = window?.rootViewController as? UINavigationController{
                root.viewControllers.first?.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: logoView)
            }
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }


}

