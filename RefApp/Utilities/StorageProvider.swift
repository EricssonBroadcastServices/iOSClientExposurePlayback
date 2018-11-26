//
//  StorageProvider.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2018-11-26.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Exposure


/// Responsible for managing persistence of the exposure credentials
enum StorageProvider {
    static var storedExposureUrl: String? {
        return UserDefaults.standard.string(forKey: "exposureUrl")
    }
    
    static var storedEnvironment: Environment? {
        guard let url = UserDefaults.standard.string(forKey: "exposureUrl"),
            let customer = UserDefaults.standard.string(forKey: "exposureCustomer"),
            let businessUnit = UserDefaults.standard.string(forKey: "exposureBusinessUnit") else { return nil }
        
        return Environment(baseUrl: url, customer: customer, businessUnit: businessUnit)
    }
    
    
    static func store(exposureUrl: String?) {
        UserDefaults.standard.set(exposureUrl, forKey: "exposureUrl")
    }
    
    static func store(environment: Environment?) {
        if let environment = environment {
            UserDefaults.standard.set(environment.baseUrl, forKey: "exposureUrl")
            UserDefaults.standard.set(environment.customer, forKey: "exposureCustomer")
            UserDefaults.standard.set(environment.businessUnit, forKey: "exposureBusinessUnit")
        }
        else {
            UserDefaults.standard.removeObject(forKey: "exposureUrl")
            UserDefaults.standard.removeObject(forKey: "exposureCustomer")
            UserDefaults.standard.removeObject(forKey: "exposureBusinessUnit")
        }
    }
    
    static var storedSessionToken: SessionToken? {
        guard let token = UserDefaults.standard.string(forKey: "exposureSessionToken") else { return nil }
        return SessionToken(value: token)
    }
    
    static func store(sessionToken: SessionToken?) {
        if let sessionToken = sessionToken {
            UserDefaults.standard.set(sessionToken.value, forKey: "exposureSessionToken")
        }
        else {
            UserDefaults.standard.removeObject(forKey: "exposureSessionToken")
        }
    }
}

