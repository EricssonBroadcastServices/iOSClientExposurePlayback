//
//  UIDevice+Extensions.swift
//  Analytics
//
//  Created by Fredrik Sjöberg on 2017-08-03.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import UIKit

extension UIDevice {
    /// Converts the old *Apple* naming convention for the *iOS* operation system name to the new one.
    internal static var mergedSystemName: String {
        let systemName = UIDevice.current.systemName
        if systemName == "iPhone OS" { return "iOS" }
        return systemName
    }
}
