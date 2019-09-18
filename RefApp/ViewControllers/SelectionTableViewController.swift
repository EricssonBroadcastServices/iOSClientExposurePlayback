//
//  SelectionTableVIewController.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2019-05-06.
//  Copyright © 2019 emp. All rights reserved.
//

import Foundation
import UIKit
import Exposure

class SelectionTableViewController: UITableViewController {
   
    /// "MOVIE", "TV_CHANNEL", "LIVE_EVENTS" : => WILL USE ASSET ENDPOINT WITH FILTER : assetType
    /// "LIVE_EVENTS_USING_EVENT_ENDPOINT" :==> WILL USE EVENT ENDPOINT IN THE EXPOSURE
    var sections = ["MOVIE", "TV_CHANNEL", "LIVE_EVENTS", "LIVE_EVENTS_USING_EVENT_ENDPOINT"]
    
    
    let cellIdentifier = "cellIdentifier"
    
    var events = [Asset]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Select Asset Type"
        tableView.backgroundColor = ColorState.active.background
        tableView.tableFooterView = UIView()
        addLogoutBarButtonItem()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    }
    
    /// Add left bar button item
    fileprivate func addLogoutBarButtonItem() {
        let button = UIButton()
        button.addTarget(self, action:#selector(handleLogout), for: .touchUpInside)
        button.setTitle(NSLocalizedString("Logout", comment: ""), for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.sizeToFit()
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.leftBarButtonItem = barButton
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return sections.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.textLabel?.text = sections[indexPath.row]
        cell.selectionStyle = .none
        cell.backgroundColor = ColorState.active.background
        cell.textLabel?.textColor = ColorState.active.text
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let destinationViewController = AssetListTableViewController()
        destinationViewController.selectedAsssetType = sections[indexPath.row]
        self.navigationController?.pushViewController(destinationViewController, animated: false)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SelectionTableViewController {
    
    /// User confirmation for logout
    @objc fileprivate func handleLogout() {
        let title = NSLocalizedString("Log out", comment: "")
        let message = NSLocalizedString("Do you want to log out from the application ?", comment: "")
        
        let logOutAction = UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: UIAlertAction.Style.default, handler: { alert -> Void in
            self.logoutUser()
        })
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("No", comment: ""), style: UIAlertAction.Style.default, handler: {
            (action : UIAlertAction!) -> Void in })
        
        self.popupAlert(title: title, message: message, actions: [logOutAction, cancelAction])
    }
    
    /// Log out the user from the application
    func logoutUser() {
        
        let navigationController = MainNavigationController()
        
        guard let environment = StorageProvider.storedEnvironment, let sessionToken = StorageProvider.storedSessionToken else {
            self.present(navigationController, animated: true, completion: nil)
            return
        }
        
        Authenticate(environment: environment)
            .logout(sessionToken: sessionToken)
            .request()
            .validate()
            .responseData{ data, error in
                if let error = error {
                    let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: {
                        (alert: UIAlertAction!) -> Void in
                        
                        StorageProvider.store(environment: nil)
                        StorageProvider.store(sessionToken: nil)
                        self.present(navigationController, animated: true, completion: nil)
                    })
                    
                    let message = "\(error.code) " + error.message + "\n" + (error.info ?? "")
                    self.popupAlert(title: error.domain , message: message, actions: [okAction], preferedStyle: .alert)
                }
                else {
                    StorageProvider.store(environment: nil)
                    StorageProvider.store(sessionToken: nil)
                    self.present(navigationController, animated: true, completion: nil)
                }
        }
    }
}
