//
//  AssetDetailsViewController.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2020-05-27.
//  Copyright © 2020 emp. All rights reserved.
//

import UIKit
import Exposure
import ExposurePlayback
import ExposureDownload

enum DownloadState: String {
    
    /// The asset is not downloaded at all.
    case notDownloaded
    
    /// The asset has a download in progress.
    case downloading
    
    /// The asset is downloaded and saved on disk.
    case downloaded
    
    /// The asset download suspended.
    case suspended
    
    /// The asset download cancelled.
    case cancelled
    
    /// The asset download prepared.
    case prepared
}

class AssetDetailsViewController: UITableViewController, EnigmaDownloadManager {
   
    
    var assetId = String()
    var downloadState = DownloadState.notDownloaded
    
    var sections = ["Play Asset", "Download", "Show Download Info"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Select Option"
        
        tableView.register(AssetListTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = ColorState.active.background
        
        
        // Check if this asset is available in downloads
        if self.enigmaDownloadManager.getDownloadedAsset(assetId: assetId) != nil {
            downloadState = DownloadState.downloaded
        }
    }
    
    func refreshTableView() {
        if self.enigmaDownloadManager.getDownloadedAsset(assetId: assetId) != nil {
            downloadState = DownloadState.downloaded
        }
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            let playable = AssetPlayable(assetId: assetId)
            self.handlePlay(playable: playable)
        case 1:
            switch downloadState {
            case .downloaded:
                deleteDownloadedAsset()
            case .notDownloaded:
                selectVideoTrack(indexPath: indexPath)
            case .downloading:
                print("Downloading")
                self.suspendOrCancelDownload(assetId: assetId, indexPath: indexPath)
            case .suspended:
                print("SUSPENDED")
                self.downloadAsset(indexPath: indexPath, videoTrack: nil, audios: nil, subtitles: nil)
            case .cancelled:
                print("Cancelled")
            case .prepared:
                print("Prepared")
            }
            
            // selectVideoTrack(indexPath: indexPath)
        // startDownload(indexPath: indexPath)
        case 2:
            showDownloadInfo()
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! AssetListTableViewCell
        
        cell.selectionStyle = .none
        cell.backgroundColor = ColorState.active.background
        
        cell.titleLabel.text = sections[indexPath.row]
        switch  indexPath.row {
        case 0:
            cell.downloadStateLabel.text = ""
        case 1:
            cell.downloadStateLabel.text = downloadState.rawValue
        case 2:
            cell.downloadStateLabel.text = ""
        default:
            break
        }
        return cell
    }
    
    func deleteDownloadedAsset() {
        switch downloadState {
        case .downloaded:
            let cancelbAction = UIAlertAction(title: "Cancel", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
            })
            
            let deletelAction = UIAlertAction(title: "Delete", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                
                // Developers can use ExposureDownloadTask delete option to delete an already downloaded asset
                self.enigmaDownloadManager.removeDownloadedAsset(assetId: self.assetId)
                self.downloadState = .notDownloaded
                
                self.refreshTableView()
                
            })
            
            self.popupAlert(title: "Delete Download", message: "Asset has Downloaded", actions: [deletelAction,cancelbAction], preferedStyle: .actionSheet)
        default:
            print("Do nothing")
        }
    }
    
    func suspendOrCancelDownload(assetId: String, indexPath: IndexPath) {
        
        guard let session = StorageProvider.storedSessionToken, let environment = StorageProvider.storedEnvironment else {
            print("No Session token or enviornment providec ")
            return
        }
         
        let task = self.enigmaDownloadManager.download(assetId: assetId, using: session, in: environment)
        let cell = tableView.cellForRow(at: indexPath) as! AssetListTableViewCell
        
        let message = "Do you want to suspend the video"
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
           (alert: UIAlertAction!) -> Void in
        })
        
        let suspendAction = UIAlertAction(title: "Suspend", style: .default, handler: {
           (alert: UIAlertAction!) -> Void in
            task.suspend()
            task.onSuspended(callback: { suspendedTask in
                self.downloadState = .suspended
                cell.downloadStateLabel.text = "Media Download Suspended"
            })
           
            
        })
        
        let cancelDownloadAction = UIAlertAction(title: "Cancel Download", style: .default, handler: {
           (alert: UIAlertAction!) -> Void in
            task.cancel()
            task.onCanceled(callback: { cancelledTask, url  in
                self.downloadState = .cancelled
                cell.downloadStateLabel.text = "Media Download Cancelled"
            })
        })
        
        self.popupAlert(title: "Suspend Downloading", message: message, actions: [suspendAction, cancelDownloadAction, cancelAction])
        
    }
    
    
    /// Select the Video track
    /// - Parameter indexPath: indexPath
    func selectVideoTrack(indexPath: IndexPath) {
        guard let session = StorageProvider.storedSessionToken, let environment = StorageProvider.storedEnvironment else {
            print("No Session token or enviornment providec ")
            return
        }
        
        self.enigmaDownloadManager.getDownloadableInfo(assetId: assetId, environment: environment, sessionToken: session) { [weak self] info in
            if let downloadInfo = info {
                
                // print("AUDIO DOWNLOAD INFO ", downloadInfo.audios )
                // print("VIDEOS DOWNLOAD INFO " , downloadInfo.videos )
                // print("SUBS DOWNLOAD INDO ", downloadInfo.subtitles )
                
                var allVideoTracks = [UIAlertAction]()
                
                // Check if the asset has any video tracks
                if downloadInfo.videos.count > 0 {
                    
                    for (_,video) in (downloadInfo.videos).enumerated() {
                        
                        let action = UIAlertAction(title: "bitrate - \(video.bitrate)", style: .default, handler: {
                            (alert: UIAlertAction!) -> Void in
                        
                            self?.downloadAsset(indexPath: indexPath , videoTrack: video.bitrate , audios: downloadInfo.audios , subtitles: downloadInfo.subtitles )
                        })
                        allVideoTracks.append(action)
                    }
                    
                    let message = "Select bit rate to download the video"
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
                        (alert: UIAlertAction!) -> Void in
                    })
                    
                    allVideoTracks.append(cancelAction)
                    
                    self?.popupAlert(title: "Download Info", message: message, actions: allVideoTracks, preferedStyle: .actionSheet)
                } else {
                    
                    // No Video Tracks available so start downloading , start downloading the default video tracks
                    self?.downloadAsset(indexPath: indexPath, videoTrack: nil, audios: nil , subtitles: nil )
                }
            } else {
                print("Asset does not have any downloadable info")
            }
        }
    }
    
    
    /// Download the asset
    /// - Parameters:
    ///   - indexPath: indexPath
    ///   - videoTrack: Selected videoTrack
    func downloadAsset(indexPath: IndexPath, videoTrack: Int?, audios: [Audios]?, subtitles: [Subtitles]?) {
        
        let cell = tableView.cellForRow(at: indexPath) as! AssetListTableViewCell
        
        guard let session = StorageProvider.storedSessionToken, let environment = StorageProvider.storedEnvironment else {
            print("No Session token or enviornment providec ")
            return
        }
        
        let message = "Choose option"
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })
        
        
        let task = self.enigmaDownloadManager.download(assetId: assetId, using: session, in: environment)
        

        
        switch downloadState {
        case .prepared:
            let resumeDownload = UIAlertAction(title: "Resume Download", style: .default, handler: { (alert: UIAlertAction) -> Void in
                task.resume()
            })
            self.popupAlert(title: nil, message: "message", actions: [resumeDownload,cancelAction], preferedStyle: .actionSheet)
            
        case .downloaded:
            let deletelAction = UIAlertAction(title: "Delete", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                
                // Developers can use ExposureDownloadTask delete option to delete an already downloaded asset
                self.enigmaDownloadManager.removeDownloadedAsset(assetId: self.assetId)
                self.refreshTableView()
                
            })
            
            self.popupAlert(title: nil, message: "Asset has Downloaded", actions: [deletelAction,cancelAction], preferedStyle: .actionSheet)
            
        case .downloading:
            
            let cancelDownload = UIAlertAction(title: "Cancel Download", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                task.cancel()
            })
            
            let suspendDownload = UIAlertAction(title: "Suspend Download", style: .default, handler: { (alert: UIAlertAction) -> Void in
                task.suspend()
            })
            
            self.popupAlert(title: nil, message: message, actions: [cancelDownload,suspendDownload, cancelAction], preferedStyle: .actionSheet)
            
        case .suspended:
            let resumeDownload = UIAlertAction(title: "Resume Download", style: .default, handler: { (alert: UIAlertAction) -> Void in
                task.resume()
            })
            
            self.popupAlert(title: nil, message: message, actions: [resumeDownload, cancelAction], preferedStyle: .actionSheet)
            
            
        case .notDownloaded:
            
            // Developers should fetch AvailabilityKeys related the currently logged user before checking if an asset is available to download for the user
            GetAvailabilityKeys(environment: environment, sessionToken: session)
                       .request()
                       .validate()
                        .response { result in
                            
                            if let error = result.error {
                                print("Error " , error)
                            }
                            
                            if let keys = result.value {
                                self.enigmaDownloadManager.isAvailableToDownload(assetId: self.assetId, environment: environment, availabilityKeys: keys.availabilityKeys ?? [] ) { [weak self] isAvailableToDownload in
                                    if isAvailableToDownload {
        
                                        task.addAllAdditionalMedia()
                                            
                                            // .addAudios(hlsNames: ["French", "German"])
                                            // .addSubtitles(hlsNames: ["French"])
                                        
                                        .onCanceled { task, url in
                                            print("📱 Media Download canceled",task.configuration.identifier,url)
                                        }
                                        .onPrepared { _ in
                                            print("📱 Media Download prepared")
                                            cell.downloadStateLabel.text = "Media Download prepared"
                                            self?.downloadState = DownloadState.prepared
                                            
                                            task.resume()
                                        }
                                        .onSuspended { _ in
                                            print("📱 Media Download Suspended")
                                            cell.downloadStateLabel.text = "Media Download Suspended"
                                            self?.downloadState = DownloadState.suspended
                                        }
                                        .onResumed { _ in
                                            print("📱 Media Download Resumed ")
                                            cell.downloadStateLabel.text = "Media Download Resumed"
                                            self?.downloadState = DownloadState.downloading
                                            
                                        }
                                        .onProgress { _, progress in
                                            print("📱 Percent", progress.current*100,"%")
                                            cell.downloadStateLabel.text = "Downloading"
                                            cell.downloadProgressView.progress = Float(progress.current)
                                            self?.downloadState = DownloadState.downloading
                                        }
                                        .onError {_, url, error in
                                            print("📱 Download error: \(error)",url ?? "")
                                            cell.downloadStateLabel.text = "Download error"
                                            cell.downloadProgressView.progress = 0
                                        }
                                        .onCompleted { _, url in
                                            print("📱 Download completed: \(url)")
                                            cell.downloadStateLabel.text = "Download completed"
                                            // self?.tableView.reloadData()
                                            
                                            self?.downloadState = DownloadState.downloaded
                                        }.prepare(lazily: false)
                                        
                                
                                        // If there is a video track , start downloading the sepcific
                                        if let videoTrack = videoTrack {
                                            task.use(bitrate: Int64(exactly: videoTrack))
                                        }
                                       
                                    } else {
                                        self?.popupAlert(title: nil, message: message, actions: [cancelAction], preferedStyle: .actionSheet)
                                    }
                            }
                }
            }
            
        default:
            print("Default")
        }
        
    }
    
    
    /// Show download info ( Video, Audio , Subtitles )
    func showDownloadInfo() {
        
        guard let session = StorageProvider.storedSessionToken, let environment = StorageProvider.storedEnvironment else {
            print("No Session token or enviornment providec ")
            return
        }
        
//
//        GetAvailabilityKeys(environment: environment, sessionToken: session)
//                   .request()
//                   .validate()
//                    .response { result in
//
//                        if let error = result.error {
//                            print("Error " , error)
//                        }
//
//                        if let keys = result.value {
//                            print("availabilityKeys ",  keys )
//                        }
//
//
//
//        }
//
         // Get download info related to the asset
        enigmaDownloadManager.getDownloadableInfo(assetId: assetId, environment: environment, sessionToken: session ) { [ weak self] info in
            if let downloadInfo = info {
                
                // print("AUDIO DOWNLOAD INFO ", downloadInfo.audios )
                // print("VIDEOS DOWNLOAD INFO " , downloadInfo.videos )
                // print("SUBS DOWNLOAD INDO ", downloadInfo.subtitles )
                
                let message = "Video : \(downloadInfo.videos) \n\n Audios : \(downloadInfo.audios) \n\n Subtitles: \(downloadInfo.subtitles)"
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
                    (alert: UIAlertAction!) -> Void in
                })
                
                self?.popupAlert(title: "Download Info", message: message, actions: [cancelAction], preferedStyle: .actionSheet)
                
                
            }
        }
        
    }
    
    /// Handle the play : ChannelPlayable or AssetPlayable
    ///
    /// - Parameters:
    ///   - playable: channelPlayable / AssetPlayable
    ///   - asset: asset
    func handlePlay(playable : Playable) {
        let destinationViewController = PlayerViewController()
        destinationViewController.environment = StorageProvider.storedEnvironment
        destinationViewController.sessionToken = StorageProvider.storedSessionToken
        
        /// Optional playback properties
        let properties = PlaybackProperties(autoplay: true,
                                            playFrom: .beginning,
                                            language: .custom(text: "fr", audio: "en"))
        
        destinationViewController.playbackProperties = properties
        destinationViewController.playable = playable
        
        self.navigationController?.pushViewController(destinationViewController, animated: false)
    }
}
