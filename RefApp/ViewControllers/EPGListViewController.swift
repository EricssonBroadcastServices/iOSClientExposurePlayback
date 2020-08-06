//
//  EPGListViewController.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2019-05-06.
//  Copyright © 2019 emp. All rights reserved.
//

import Foundation
import UIKit
import Exposure
import ExposurePlayback


class EPGListViewController: UITableViewController  {
    
    var programs = [Program]()
    var channel: Asset!
    let cellIdentifier = "cellIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = ColorState.active.background
        
        
        self.generateTableViewContent()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.programs.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        let program = self.programs[indexPath.row]
        let current = Date()
        
        if let start = program.startDate, let _ = program.endDate {
            if start > current {
                cell.isUserInteractionEnabled = false
                //cell.backgroundColor = ColorState.active.textFieldPlaceholder
                cell.textLabel?.textColor = ColorState.active.textFieldPlaceholder
            } else {
                cell.isUserInteractionEnabled = true
                cell.backgroundColor = ColorState.active.background
                cell.textLabel?.textColor = ColorState.active.text
            }
        }
        
        cell.textLabel?.text = self.programs[indexPath.row].programId
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let program = self.programs[indexPath.row]
        let current = Date()
        if let start = program.startDate, let _ = program.endDate {
            if start <= current {
                self.showOptions(program: program, channel: channel)
            }
        }
        
        
    }
}

extension EPGListViewController {
    
    
    /// Show options: Play Using ProgramPlayable or AssetPlayable
    ///
    /// - Parameters:
    ///   - program: program
    ///   - channel: channel
    fileprivate func showOptions(program: Program, channel: Asset) {
        
        let message = "Choose option"
        
        let playProgramPlayable = UIAlertAction(title: "Play Program Using Program Playable - Test Only", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            let playable = ProgramPlayable(assetId: program.programId, channelId: channel.assetId)
            self.handleProgramPlay(playable: playable, asset: channel)
            
        })
        
        let playAssetPlayable = UIAlertAction(title: "Play Program Using Asset Playable", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            let playable = AssetPlayable(assetId: program.assetId)
            self.handleProgramPlay(playable: playable, asset: channel)
        })
        
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })
        
        self.popupAlert(title: nil, message: message, actions: [playAssetPlayable ,playProgramPlayable, cancelAction], preferedStyle: .actionSheet)
    }
    
    func handleProgramPlay(playable : Playable, asset: Asset) {
        let destinationViewController = PlayerViewController()
        destinationViewController.environment = StorageProvider.storedEnvironment
        destinationViewController.sessionToken = StorageProvider.storedSessionToken
        destinationViewController.channel = asset
        
        /// Optional playback properties
        let properties = PlaybackProperties(autoplay: true,
                                            playFrom: .defaultBehaviour,
                                            language: .custom(text: "fr", audio: "en"),
                                            maxBitrate: 300000)
        
        destinationViewController.playbackProperties = properties
        destinationViewController.playable = playable
        
        self.navigationController?.pushViewController(destinationViewController, animated: false)
    }
}

// MARK: - DataSource
extension EPGListViewController {
    
    /// Generate tableview content by loading assets from API
    fileprivate func generateTableViewContent() {
        guard let environment = StorageProvider.storedEnvironment, let sessionToken = StorageProvider.storedSessionToken else {
            let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: {
                (alert: UIAlertAction!) -> Void in
                
            })
            
            let message = "Invalid Session Token, please login again"
            self.popupAlert(title: "Error" , message: message, actions: [okAction], preferedStyle: .alert)
            return
        }
        
        
        let date = Date()
        let start = (date.subtract(days: 1) ?? date).millisecondsSince1970
        let end = (date.add(hours: 4) ?? date).millisecondsSince1970
        
        fetchEpg(for: channel, from: start, to: end, environment: environment, sessionToken: sessionToken) { [weak self] epg, error in
            guard let `self` = self else { return }
            
            if let error = error {
                let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: {
                    (alert: UIAlertAction!) -> Void in
                })
                let message = "\(error.code) " + error.message + "\n" + (error.info ?? "")
                self.popupAlert(title: error.domain , message: message, actions: [okAction], preferedStyle: .alert)
            }
            
            self.programs = epg?.programs ?? []
            self.tableView.reloadData()
        }
        
    }
    
    
    /// Fetch EPG
    ///
    /// - Parameters:
    ///   - channel: channel
    ///   - start: start time
    ///   - end: end time
    ///   - environment: environment
    ///   - sessionToken: session token
    ///   - callback: callback
    fileprivate func fetchEpg(for channel: Asset, from start: Int64, to end: Int64, environment: Environment, sessionToken: SessionToken, callback: @escaping (ChannelEpg?, ExposureError?) -> Void) {
        // Fetch Epg
        
        FetchEpg(environment: environment)
            .channel(id: channel.assetId)
            .filter(starting: start, ending: end)
            .filter(onlyPublished: true)
            .request()
            .validate()
            .response{
                callback($0.value,$0.error)
        }
    }
}

