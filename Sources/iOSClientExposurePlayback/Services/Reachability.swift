//    Copyright (c) 2014, Ashley Mills
//    All rights reserved.
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions are met:
//
//    1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
//    2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//    ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//    LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//    POSSIBILITY OF SUCH DAMAGE.

//
//  Reachability.swift
//  ExposurePlayback
//
//  Created by Fredrik Sjöberg on 2018-09-28.
//  Copyright © 2018 emp. All rights reserved.
//

import SystemConfiguration
import Foundation

internal enum ReachabilityError: Error {
    case UnableToSetCallback
    case UnableToSetDispatchQueue
    case UnableToGetInitialFlags
}

internal class Reachability {
    internal enum Connection: CustomStringConvertible {
        case none
        case wifi
        case cellular
        case unknown
        
        internal var description: String {
            switch self {
            case .cellular: return "Cellular"
            case .wifi: return "WiFi"
            case .none: return "None"
            case .unknown: return "Unknown"
            }
        }
    }
    
    internal var onReachabilityChanged: (Reachability.Connection) -> Void = { _ in }
    internal var connection: Connection {
        if flags == nil {
            try? setReachabilityFlags()
        }
        
        switch flags?.connection {
        case .none?: return .none
        case .cellular?: return .cellular
        case .wifi?: return .wifi
        case .unknown?, nil: return .unknown
        }
    }
    
    fileprivate var notifierRunning = false
    fileprivate let reachabilityRef: SCNetworkReachability
    fileprivate let queue: DispatchQueue
    fileprivate(set) var flags: SCNetworkReachabilityFlags? {
        didSet {
            guard flags != oldValue else { return }
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.onReachabilityChanged(self.connection)
            }
        }
    }
    
    
    internal init?() {
        var addr = sockaddr()
        addr.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        addr.sa_family = sa_family_t(AF_INET)
        
        guard let ref = SCNetworkReachabilityCreateWithAddress(nil, &addr) else { return nil }
        self.reachabilityRef = ref
        self.queue = DispatchQueue(label: "com.emp.reachability", qos: .default)
    }
    
    deinit {
        stopNotifier()
    }
}

internal extension Reachability {
    internal func startNotifier() throws {
        guard !notifierRunning else { return }
        
        let callback: SCNetworkReachabilityCallBack = { (scNetworkReachability, flags, info) in
            guard let info = info else { return }
            
            let reachability = Unmanaged<Reachability>.fromOpaque(info).takeUnretainedValue()
            reachability.flags = flags
        }
        
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutableRawPointer(Unmanaged<Reachability>.passUnretained(self).toOpaque())
        if !SCNetworkReachabilitySetCallback(reachabilityRef, callback, &context) {
            stopNotifier()
            throw ReachabilityError.UnableToSetCallback
        }
        
        if !SCNetworkReachabilitySetDispatchQueue(reachabilityRef, queue) {
            stopNotifier()
            throw ReachabilityError.UnableToSetDispatchQueue
        }
        
        try setReachabilityFlags()
        
        notifierRunning = true
    }
    
    internal func stopNotifier() {
        defer { notifierRunning = false }
        
        SCNetworkReachabilitySetCallback(reachabilityRef, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachabilityRef, nil)
    }
}

fileprivate extension Reachability {
    fileprivate func setReachabilityFlags() throws {
        try queue.sync { [unowned self] in
            var flags = SCNetworkReachabilityFlags()
            if !SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags) {
                self.stopNotifier()
                throw ReachabilityError.UnableToGetInitialFlags
            }
            
            self.flags = flags
        }
    }
}

internal extension SCNetworkReachabilityFlags {
    
    internal typealias Connection = Reachability.Connection
    
    internal var connection: Connection {
        guard contains(.reachable) else { return .none }
        
        var connection = Connection.none
        
        if !contains(.connectionRequired) {
            connection = .wifi
        }
        
        if !intersection([.connectionOnTraffic, .connectionOnDemand]).isEmpty {
            if !contains(.interventionRequired) {
                connection = .wifi
            }
        }
        
        if isOnWWANFlagSet {
            connection = .cellular
        }
        
        return connection
    }
    
    internal var isOnWWANFlagSet: Bool {
        #if os(iOS)
        return contains(.isWWAN)
        #else
        return false
        #endif
    }
}
