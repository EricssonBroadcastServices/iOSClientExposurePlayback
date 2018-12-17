//
//  Date+Extensions.swift
//  iOSReferenceApp
//
//  Created by Fredrik Sjöberg on 2017-07-10.
//  Copyright © 2017 emp. All rights reserved.
//


import Foundation

extension Date {
    public func subtract(days: UInt) -> Date? {
        var components = DateComponents()
        components.setValue(-Int(days), for: Calendar.Component.day)
        
        return Calendar.current.date(byAdding: components, to: self)
    }
    
    public func add(days: UInt) -> Date? {
        var components = DateComponents()
        components.setValue(Int(days), for: Calendar.Component.day)
        
        return Calendar.current.date(byAdding: components, to: self)
    }
    
    public func subtract(hours: UInt) -> Date? {
        var components = DateComponents()
        components.setValue(-Int(hours), for: Calendar.Component.hour)
        
        return Calendar.current.date(byAdding: components, to: self)
    }
    
    public func add(hours: UInt) -> Date? {
        var components = DateComponents()
        components.setValue(Int(hours), for: Calendar.Component.hour)
        
        return Calendar.current.date(byAdding: components, to: self)
    }
    
    public func dateString(format: String) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = format
        return timeFormatter.string(from: self)
    }
    
    public func hoursAndMinutes() -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.locale = Locale(identifier: "en_GB")
        
        return timeFormatter.string(from: self)
    }
}
