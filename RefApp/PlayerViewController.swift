//
//  Player.swift
//  RefApp
//
//  Created by Karl Holmlöv on 11/1/18.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit
import Exposure
import ExposurePlayback
import Player

class PlayerViewController: UIViewController {

    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()

    var environment: Environment!
    var token: SessionToken!
    var assetId: String!
    fileprivate(set) var player: Player<HLSNative<ExposureContext>>!
    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = UIActivityIndicatorView.Style.gray
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        // Do any additional setup after loading the view.
        player = Player(environment: environment, sessionToken: token)
        player.onError { [weak self](player, source, error) in
            
            self?.activityIndicator.stopAnimating()
            let alert = UIAlertController(title: "Can't play asset", message: error.message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel) { _ in
                self?.navigationController?.popViewController(animated: true)
            })
            
            self?.present(alert, animated: true)
        }
        player.onPlaybackReady { [weak self] (_,_) in
            self?.activityIndicator.stopAnimating()
        }
        
        player.startPlayback(assetId: self.assetId)
        
        player.configure(playerView: view)
        
    }
}
