//
//  LoginViewController.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2018-11-19.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit
import Exposure

class LoginViewController: UIViewController {
    
    var environment: Environment!
    
    let topHolderView: UIView = {
        let view = UIView()
        return view
    }()
    
    let bottomHolderView: UIView = {
        let view = UIView()
        return view
    }()
    
    let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "redbee")
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let usernameTextField: RBMTextField = {
        let textfield = RBMTextField(placeHolderText: NSLocalizedString("Username", comment: ""))
        textfield.textContentType = UITextContentType.username
        return textfield
    }()
    
    let passwordTextField: RBMTextField = {
        let textfield = RBMTextField(placeHolderText: NSLocalizedString("Password", comment: ""))
        textfield.textContentType = UITextContentType.password
        textfield.isSecureTextEntry = true
        return textfield
    }()
    
    let loginButton: RBMButton = {
        let button = RBMButton(titleText: NSLocalizedString("Login", comment: ""))
        button.addTarget(self, action: #selector(authenticateUser), for: .touchUpInside)
        return button
    }()
    
    // MARK: Life Cycle
    override func loadView() {
        super.loadView()
        
        addSubViews()
        setupAnchorsForViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dissmissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        view.bindToKeyboard()
        
        self.navigationItem.title = NSLocalizedString("Login", comment: "")
        view.backgroundColor = ColorState.active.background
    }
    
    @objc func dissmissKeyboard() {
        view.endEditing(true)
    }
    
    deinit {
        view.unbindToKeyboard()
    }
    
}



// MARK: - Layout
extension LoginViewController {
    
    fileprivate func addSubViews() {
        
        view.addSubview(topHolderView)
        view.addSubview(bottomHolderView)
        view.addSubview(logoImageView)
        view.addSubview(usernameTextField)
        view.addSubview(passwordTextField)
        view.addSubview(loginButton)
    }
    
    fileprivate func setupAnchorsForViews() {
        
        if #available(iOS 11, *) {
            topHolderView.anchor(top: view.safeAreaLayoutGuide.topAnchor, bottom: bottomHolderView.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor)
            
            bottomHolderView.anchor(top: topHolderView.bottomAnchor, bottom: nil, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor)
            
            usernameTextField.anchor(top: bottomHolderView.topAnchor, bottom: nil, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top:20, left: 16, bottom:0, right: -16))
            
            passwordTextField.anchor(top: usernameTextField.bottomAnchor, bottom: nil, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top:20, left: 16, bottom:0, right: -16))
            
            loginButton.anchor(top: passwordTextField.bottomAnchor, bottom: nil, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top:20, left: 16, bottom:0, right: -16))
            
        } else {
            topHolderView.anchor(top: view.topAnchor, bottom: bottomHolderView.topAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor)
            
            bottomHolderView.anchor(top: topHolderView.bottomAnchor, bottom: nil, leading: view.leadingAnchor, trailing: view.trailingAnchor)
            
            usernameTextField.anchor(top: bottomHolderView.topAnchor, bottom: nil, leading: view.leadingAnchor, trailing: view.trailingAnchor, padding: .init(top:20, left: 16, bottom:0, right: -16))
            
            passwordTextField.anchor(top: usernameTextField.bottomAnchor, bottom: nil, leading: view.leadingAnchor, trailing: view.trailingAnchor, padding: .init(top:20, left: 16, bottom:0, right: -16))
            
            loginButton.anchor(top: passwordTextField.bottomAnchor, bottom: nil, leading: view.leadingAnchor, trailing: view.trailingAnchor, padding: .init(top:20, left: 16, bottom:0, right: -16))
        }
        
        topHolderView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/3).isActive = true
        
        logoImageView.anchor(top: nil, bottom: topHolderView.bottomAnchor, leading: nil, trailing: nil, padding: .init(top: 0, left: 0, bottom: 0, right: 0), size: .init(width: 0, height: 0))
        logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        bottomHolderView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 2/3).isActive = true
    }
}



// MARK: - Actions
extension LoginViewController {
    
    /// Authenticate the user with Authentication Endpoint
    @objc fileprivate func authenticateUser() {
        
        view.endEditing(true)
        
        let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })
        
        guard let username = usernameTextField.text, let password = passwordTextField.text, username != "", password != "" else {
            
            self.popupAlert(title:NSLocalizedString("Sorry", comment: "") , message: NSLocalizedString("Please fill all fields", comment: ""), actions: [okAction], preferedStyle: .alert)
            
            return
        }
        
        Authenticate(environment: environment)
            .login(username: username, password: password)
            .request()
            .validate()
            .response{ [weak self] in
                if let error = $0.error {
                    
                    let message = "\(error.code) " + error.message + "\n" + (error.info ?? "")
                    self?.popupAlert(title: error.domain , message: message, actions: [okAction], preferedStyle: .alert)
                }
                
                if let credentials = $0.value {
                    StorageProvider.store(environment: self?.environment)
                    StorageProvider.store(sessionToken: credentials.sessionToken)
                    
                    let navigationController = MainNavigationController()
                    self?.parent?.present(navigationController, animated: true, completion: nil)

                }
        }
    }
}
