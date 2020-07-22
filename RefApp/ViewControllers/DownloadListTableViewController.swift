//
//  DownloadListTableViewController.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2020-05-25.
//  Copyright © 2020 emp. All rights reserved.
//

import UIKit
import ExposureDownload
import ExposurePlayback

class DownloadListTableViewController: UITableViewController, EnigmaDownloadManager {
    
    var downloadedAssets: [OfflineMediaAsset]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = ColorState.active.background
        
        self.refreshTableView()
        
    }
    
    func refreshTableView() {
        downloadedAssets = enigmaDownloadManager.getDownloadedAssets()
        tableView.reloadData()
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if downloadedAssets?.count == 0 {
            tableView.showEmptyMessage(message: NSLocalizedString("No downloaded content", comment: ""))
        } else {
            tableView.hideEmptyMessage()
        }
        return downloadedAssets?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.showOptions(indexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.selectionStyle = .none
        cell.backgroundColor = ColorState.active.background
        cell.textLabel?.textColor = ColorState.active.text
        
        if let asset = downloadedAssets?[indexPath.row] {
            cell.textLabel?.text = asset.assetId
        }
        
        return cell
    }
    
    func showOptions(_ row:Int ) {
        let message = "Choose option"
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })
        
        let deletelAction = UIAlertAction(title: "Delete", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            
            if let asset = self.downloadedAssets?[row] {
                
                // Developers can use ExposureDownloadTask delete option to delete an already downloaded asset
                self.enigmaDownloadManager.removeDownloadedAsset(assetId: asset.assetId)
                self.refreshTableView()
            }
        })
        
        let playOffline = UIAlertAction(title: "Play Offline", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            
            if let asset = self.downloadedAssets?[row] {
                
                // Developers can check if an asset is already downloaded by passing an assetId.
                // If the asset is already downloaded, API will return OfflineMediaAsset which has assetId, entitlement, urlAsset etc.
                let offlineMedia = self.enigmaDownloadManager.offline(assetId: asset.assetId)
                let urlAsset = offlineMedia?.urlAsset
                
                if let entitlement = offlineMedia?.entitlement, let urlAsset = urlAsset {

                    let destinationViewController = PlayerViewController()
                    destinationViewController.environment = StorageProvider.storedEnvironment
                    destinationViewController.sessionToken = StorageProvider.storedSessionToken
                    
                    /// Optional playback properties
                    let properties = PlaybackProperties(autoplay: true,
                                                        playFrom: .bookmark,
                                                        language: .custom(text: "fr", audio: "en"),
                                                        maxBitrate: 300000)
                    
                    destinationViewController.playbackProperties = properties
                    
                    // Developers can create an OfflineMediaPlayable & pass it to the player to play any offline media.
                    destinationViewController.offlineMediaPlayable = OfflineMediaPlayable(assetId: asset.assetId, entitlement: entitlement, url: urlAsset.url)
                    
                    self.navigationController?.pushViewController(destinationViewController, animated: false)
                    
                }
            }
            
            
        })
        
        self.popupAlert(title: nil, message: message, actions: [playOffline, deletelAction, cancelAction], preferedStyle: .actionSheet)
    }
}
