//
//  AssetListTableViewController.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2018-11-21.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit
import Exposure
import ExposurePlayback

class AssetListTableViewController: UITableViewController {
    
    var assets = [Asset]()
    var sessionToken: SessionToken?
    
    var datasource:TableViewDataSource<Asset>?
    let cellId = "assetListTableViewCell"
    
    // MARK: Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.assetsDidLoad([])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = NSLocalizedString("Assets", comment: "")
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationBar.barStyle = .black
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        tableView.tableFooterView = UIView()
        
        addLogoutBarButtonItem()
        self.generateTableViewContent()
    }
    
    
    /// Add left bar button item
    fileprivate func addLogoutBarButtonItem() {
        let button = UIButton()
        button.addTarget(self, action:#selector(handleLogout), for: .touchUpInside)
        button.setTitle(NSLocalizedString("Logout", comment: ""), for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.leftBarButtonItem = barButton
    }
}

// MARK: - DataSource
extension AssetListTableViewController {
    
    /// Generate tableview content by loading assets from API
    fileprivate func generateTableViewContent() {
        guard let environment = StorageProvider.storedEnvironment, let _ = StorageProvider.storedSessionToken else {
            logoutUser()
            return
        }
        
        let query = "assetType=MOVIE"
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.loadAssets(query: query, environment: environment, endpoint: "/content/asset", method: HTTPMethod.get)
        }
    }
    
    /// Load the assets from the Exposure API
    ///
    /// - Parameters:
    ///   - query: The optional query to filter by Ex:assetType=TV_CHANNEL
    ///   - environment: Customer specific *Exposure* environment
    ///   - endpoint: Base exposure url. This is the customer specific URL to Exposure
    ///   - method: http method - GET
    fileprivate func loadAssets(query: String, environment: Environment, endpoint: String, method: HTTPMethod) {
        ExposureApi<AssetList>(environment: environment,
                               endpoint: endpoint,
                               query: query,
                               method: method)
            .request()
            .validate()
            .response { [weak self] in
                
                if let value = $0.value {
                    self?.assets = value.items ?? []
                    self?.assetsDidLoad(value.items ?? [])
                }
                
                if let error = $0.error {
                    let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: {
                        (alert: UIAlertAction!) -> Void in
                        self?.assetsDidLoad([])
                    })
                    
                    let message = "\(error.code) " + error.message + "\n" + (error.info ?? "")
                    self?.popupAlert(title: error.domain , message: message, actions: [okAction], preferedStyle: .alert)
                }
        }
    }
    
    
    /// Create the datasource for the tableview
    ///
    /// - Parameter assets: loaded assets from Exposure API
    func assetsDidLoad(_ assets: [Asset]) {
        datasource = .make(for: assets)
        DispatchQueue.main.async {
            self.tableView.dataSource = self.datasource
            self.tableView.reloadData()
        }
    }
}

// MARK: - Actions
extension AssetListTableViewController {
    
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
    fileprivate func logoutUser() {
        
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
