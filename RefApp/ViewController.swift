//
//  ViewController.swift
//  RefApp
//
//  Created by Fredrik Sjöberg on 2018-10-30.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit
import ExposurePlayback
import Player
import Exposure

class Obj {
    func test() { }
    init() { }
}

class ViewController: UIViewController {

    var onAuth: () -> Void = { }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let environment = Environment(baseUrl: "Env", customer: "CU", businessUnit: "BU")
        let username = "username"
        let password = "password"
        
        Authenticate(environment: environment)
            .login(username: username, password: password)
            .request()
            .validate()
            .response{
                if let value = $0.value {
                    // store -> value
                    self.onAuth()
                }

                if let error = $0.error {
                    print(error.message)
                }
            }

        
        let query = "tags.genres:action"
        ExposureApi<AssetList>(environment: environment,
                               endpoint: "/content/asset",
                               query: query,
                               method: .get)
            .request()
            .validate()
            .response { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                
                if let value = $0.value {
                    
                    
                    value.items?.forEach{
                        print($0.assetId)
                    }
                }
            }
    }


}

