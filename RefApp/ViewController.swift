//
//  ViewController.swift
//  RefApp
//
//  Created by Karl Holmlöv on 2018-10-30.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit
import ExposurePlayback
import Player
import Exposure

class ViewController: UIViewController {

    @IBOutlet weak var expUrl: UITextField!
    @IBOutlet weak var customer: UITextField!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var buisnessUnit: UITextField!
    

    @IBAction func Login(_ sender: Any) {
        guard let testedUrl = expUrl.text, let testedCustomer = customer.text, let testedBuisnessUnit = buisnessUnit.text, testedUrl != "", testedCustomer != "", testedBuisnessUnit != "" else {
            let alert = UIAlertController(title: "Invalid env", message: "Provide a valid env", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel) { _ in })
            
            self.present(alert, animated: true)
            return
        }
        let environment = Environment(baseUrl: testedUrl, customer: testedCustomer, businessUnit: testedBuisnessUnit)
        
        onEnvironment(environment)
        
        
        Authenticate(environment: environment)
            .login(username: username.text!, password: password.text!)
            .request()
            .validate()
            .response{ [weak self] in
                if let value = $0.value {
                    self?.onAuth(value.sessionToken)
                }

                if let error = $0.error {
                    print(error.message)
                    self?.onError(error)
                }
        }
        UserDefaults.standard.set(expUrl.text!, forKey: "expUrl")
        UserDefaults.standard.set(customer.text!, forKey: "customer")
        UserDefaults.standard.set(buisnessUnit.text!, forKey: "buisnessUnit")        
        
        navigationController?.popViewController(animated: true)
    }
    
    
    var onError: (ExposureError) -> Void = { _ in }
    var onAuth: (SessionToken) -> Void = { _ in }
    var onEnvironment: (Environment) -> Void = { _ in }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        expUrl.text = UserDefaults.standard.string(forKey: "expUrl")
        customer.text = UserDefaults.standard.string(forKey: "customer")
        buisnessUnit.text = UserDefaults.standard.string(forKey: "buisnessUnit")
    }


}

