//
//  IbcScheme.swift
//  Navigation
//
//  Created by Fredrik Sjöberg on 2018-08-30.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit

public protocol ColorScheme {
    
    var accent: UIColor { get }
    var button: UIColor { get }
    var text: UIColor { get }
    var tagText: UIColor { get }
    var background: UIColor { get }
    var accentedBackground: UIColor { get }
    var destructive: UIColor { get }
    
    var sectionHeader: UIColor { get }
    
    var textFieldText: UIColor { get }
    var textFieldBackground: UIColor { get }
    var textFieldPlaceholder: UIColor { get }
}

public struct ColorState {
    public static var active: ColorScheme {
        return DarkScheme()
    }
}

public struct IbcScheme: ColorScheme {
    
    public var accent: UIColor {
        return UIColor("#dc281e")
    }
    
    public var button: UIColor {
        return UIColor.white
    }
    
    public var text: UIColor {
        return UIColor("#333333")
    }
    
    public var tagText: UIColor {
        return UIColor("#f0645a")
    }
    
    public var background: UIColor {
        return UIColor("#FFFFFF")
    }
    
    public var accentedBackground: UIColor {
        return UIColor("#f5f5f5")
    }
    
    public var destructive: UIColor {
        return UIColor("#6D1E2A")
    }
    
    public var sectionHeader: UIColor {
        return tagText
    }
    
    public var textFieldText: UIColor {
        return text
    }
    
    public var textFieldBackground: UIColor {
        return UIColor.white
    }
    
    public var textFieldPlaceholder: UIColor {
        return UIColor.darkGray
    }
}

public struct DarkScheme: ColorScheme {
    public var accent: UIColor {
        return UIColor("#dc281e")
    }
    
    public var button: UIColor {
        return UIColor.white
    }
    
    public var text: UIColor {
        return UIColor("#FDF8FB")
    }
    
    public var tagText: UIColor {
        return UIColor("#f0645a")
    }
    
    public var background: UIColor {
        return UIColor("#070606")
    }
    
    public var accentedBackground: UIColor {
        return UIColor("#151313")
    }
    
    public var destructive: UIColor {
        return UIColor("#6D1E2A")
    }
    
    public var sectionHeader: UIColor {
        return text
    }
    
    public var textFieldText: UIColor {
        return UIColor.white
    }
    
    public var textFieldBackground: UIColor {
        return UIColor("#252323")
    }
    
    public var textFieldPlaceholder: UIColor {
        return UIColor.lightGray
    }
}

