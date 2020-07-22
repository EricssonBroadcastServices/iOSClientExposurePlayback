//
//  AppDelegate.swift
//  RefApp
//
//  Created by Fredrik Sjöberg on 2018-10-30.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit
import Download
import Exposure
import ExposureDownload

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, EnigmaDownloadManager {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow()
        let rootViewController = MainNavigationController()
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
        
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

    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        if identifier == SessionConfigurationIdentifier.default.rawValue {
            print("🛏 Rejoining session \(identifier)")
            
            self.enigmaDownloadManager.backgroundCompletionHandler = completionHandler
            
            enigmaDownloadManager.restoreTasks { downloadTasks in
                downloadTasks.forEach {
                    print("🛏 found",$0.taskDescription ?? "")
                    // Restore state
                                        // log(downloadTask: $0)
                }
            } 
        }
    }
    
    private func log(downloadTask: ExposureDownloadTask) {
        downloadTask.onCanceled{ task, url in
            print("📱 Media Download canceled",task.configuration.identifier,url)
            }
            .onPrepared { _ in
                print("📱 Media Download prepared")
            }
            .onSuspended { _ in
                print("📱 Media Download Suspended")
            }
            .onResumed { _ in
                print("📱 Media Download Resumed")
            }
            .onProgress { _, progress in
                print("📱 Percent",progress.current*100,"%")
            }
            .onShouldDownloadMediaOption{ _,_ in
                print("📱 Select media option")
                return nil
            }
            .onDownloadingMediaOption{ _,_ in
                print("📱 Downloading media option")
            }
            .onError {_, url, error in
                print("📱 Download error: \(error)",url ?? "")
            }
            .onCompleted { _, url in
                print("📱 Download completed: \(url)")
            }
    }

}

