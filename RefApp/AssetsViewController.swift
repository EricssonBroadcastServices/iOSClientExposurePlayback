//
//  AssetsViewController.swift
//  RefApp
//
//  Created by Karl Holmlöv on 10/31/18.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit
import ExposurePlayback
import Player
import Exposure

class AssetsViewController: UITableViewController {

    var assets = [Asset]()
    var environment: Environment!
    var sessionToken: SessionToken?
    var query = "assetType=MOVIE"
    var endpoint = "/content/asset"
    var method: HTTPMethod = .get

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let baseUrl = UserDefaults.standard.string(forKey: "expUrl"), let customer = UserDefaults.standard.string(forKey: "customer"), let buisnessUnit = UserDefaults.standard.string(forKey: "buisnessUnit")
        else {
            return
        }
        
        environment = Environment(baseUrl: baseUrl, customer: customer, businessUnit: buisnessUnit)
        
        loadAssets(query: self.query, environment: self.environment, endpoint: self.endpoint, method: self.method)
    }
    func loadAssets(query: String, environment: Environment, endpoint: String, method: HTTPMethod) {
        ExposureApi<AssetList>(environment: environment,
                               endpoint: endpoint,
                               query: query,
                               method: method)
            .request()
            .validate()
            .response { [weak self] in
                guard let `self` = self else {
                    return
                }
                self.assets = $0.value?.items ?? []
                
                self.tableView.reloadData()
            }
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let identifier = segue.identifier, identifier == "loginSegue", let destination = segue.destination as? ViewController {
            destination.onAuth = { [weak self] token in
                self?.sessionToken = token
            }
            destination.onEnvironment = { [weak self] env in
                guard let `self` = self else { return }
                self.environment = env
                self.loadAssets(query: self.query, environment: self.environment, endpoint: self.endpoint, method: self.method)
            }
            
            destination.onError = { [weak self] error in
                let alert = UIAlertController(title: "Error, please try again", message: error.message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel) { _ in })
                self?.present(alert, animated: true)
            }
        }
        if let identifier = segue.identifier, identifier == "playbackSegue", let destination = segue.destination as? PlayerViewController {
            if let assetId = sender as? String {
                destination.assetId = assetId
                destination.environment = self.environment
                destination.token = self.sessionToken
            }
        }
    }
}

extension AssetsViewController {
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assets.count
    }
   
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        cell.textLabel?.text = assets[indexPath.row].localized?.first?.title
        
        return cell
    }
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.sessionToken != nil {
            performSegue(withIdentifier: "playbackSegue", sender: assets[indexPath.row].assetId)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
