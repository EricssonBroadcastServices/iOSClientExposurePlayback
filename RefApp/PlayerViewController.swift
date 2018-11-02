//
//  Player.swift
//  RefApp
//
//  Created by Karl Holmlöv on 11/1/18.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit

class PlayerViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let token = SessionToken(value: "FAKE")
        player = PlayerViewController(environment: environment, sessionToken: token)
        player.onError { (player, source, error) in
            print(error.message)
        }
        player.startPlayback(assetId: "kjasfkgasgf")
        player.configure(playerView: view)
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
