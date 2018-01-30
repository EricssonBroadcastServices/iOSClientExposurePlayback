//
//  MonotonicTimeService.swift
//  Exposure
//
//  Created by Fredrik Sjöberg on 2018-01-09.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation

/// Service that syncs local device clock with server time
public class MonotonicTimeService {
    /// Refresh rate for contacting the server requesting an updated timestamp
    internal let refreshInterval: Int
    
    /// The currently active error policy
    ///
    /// Error policy used to guide `MonotonicTimeService` in the event of an error occurs during the refresh attempt
    public var onErrorPolicy: ErrorPolicy = .retry(attempts: 5, interval: 1000) {
        didSet {
            currentRetryAttempt = 0
        }
    }
    
    /// Error policy used to guide `MonotonicTimeService` in the event of an error occurs during the refresh attempt
    public enum ErrorPolicy {
        /// Attempts a specified number of retries in a fixed interval.
        ///
        /// If all attempts fail, defaults back to the standard `refreshInterval`
        case retry(attempts: Int, interval: Int)
        
        /// Retains the default `refreshInterval` and makes no attempt at an earlier server contact
        case retainRefreshInterval
    }
    
    /// Keeps track of the current retry attempt for the `.retry(_,_)` `ErrorPolicy`
    fileprivate var currentRetryAttempt: Int = 0
    
    /// Provides `MonotonicTimeService` with `ServerTime` on request
    internal var serverTimeProvider: ServerTimeProvider
    
    public init(environment: Environment, refreshInterval: Int = 1000 * 60 * 30) {
        self.environment = environment
        self.refreshInterval = refreshInterval
        
        let queue = DispatchQueue(label: "com.emp.exposure.monotonicTimeService",
                                  qos: DispatchQoS.background,
                                  attributes: DispatchQueue.Attributes.concurrent)
        self.queue = queue
        
        serverTimeProvider = ExposureServerTimeProvider()
    }
    
    deinit {
        timer?.setEventHandler{}
        timer?.cancel()
    }
    
    /// `Environment` in which the `ServerTime` request will be made
    fileprivate var environment: Environment
    
    /// Queue where `timer` runs
    fileprivate let queue: DispatchQueue
    
    /// The oneShot timer used to trigger `ServerTime` refresh requests
    fileprivate var timer: DispatchSourceTimer?
    
    /// Internal implementation of `ServerTimeProvider` using `Exposure`Type`
    internal struct ExposureServerTimeProvider: ServerTimeProvider {
        func fetchServerTime(using environment: Environment, callback: @escaping (ServerTime?, ExposureError?) -> Void) {
            FetchServerTime(environment: environment)
                .request()
                .response{ callback($0.value, $0.error) }
        }
    }
    
    /// The currently stored server time `Difference`
    fileprivate var currentDifference: Difference?
    
    /// State tracking if the serivce has been started or not
    fileprivate var state: State = .notStarted
    
    /// Tracks `MonotonicTimeSerive` state
    fileprivate enum State {
        /// Not yet started
        case notStarted
        
        /// The service is running
        case running
    }
    
    /// Stores the difference between local deviceTime and serverTime
    internal struct Difference {
        internal var serverStartTime: Int64
        internal var localStartTime: Int64
        
        /// Calculates the `MonotonicTime` at this moment
        internal func monotonicTime(date: Date) -> Int64 {
            return serverStartTime + date.millisecondsSince1970 - localStartTime
        }
    }
}

extension MonotonicTimeService {
    /// Synchronizes `date` with server wallclock time
    ///
    /// - parameter date: date to synchronize
    /// - returns: synchronized unix epoch timestamp if server time is available, else `nil`
    public func monotonicTime(date: Date) -> Int64? {
        return currentDifference?.monotonicTime(date: date)
    }
 
    /// Retrieve the latest *MonotonicTime*, in unix epoch time, as cached by the service. (in milliseconds)
    ///
    /// Accessing this property when the service is not yet running will start it.
    ///
    /// May return `nil` if no server time has been cached.
    public var serverTime: Int64? {
        switch state {
        case .notStarted:
            startTimer()
        default:
            break
        }
        return currentDifference?.monotonicTime(date: Date())
    }
    
    /// Fetches the latest *MonotonicTime*, in unix epoch time (in milliseconds). If the service is not running, calling this method (with or without `forceRefresh`) will start it and cause an immediate fetch request.
    ///
    /// - parameter forceRefresh: Specifying `true` will force a server request fetching an up to date `MonotonicTime` if the service is running. `false` will return the cached `MonotonicTime`.
    public func serverTime(forceRefresh: Bool = true, callback: @escaping (Int64?, ExposureError?) -> Void) {
        switch state {
        case .notStarted:
            startTimer()
            fetchServerTime{ callback($0?.monotonicTime(date: Date()), $1) }
        case .running:
            if forceRefresh {
                fetchServerTime{ callback($0?.monotonicTime(date: Date()), $1) }
            }
            else {
                callback(currentDifference?.monotonicTime(date: Date()), nil)
            }
        }
    }
    
    /// Starts the internal timer guiding the refresh process.
    private func startTimer() {
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.scheduleRepeating(deadline: .now(), interval: .milliseconds(refreshInterval))
        state = .running
        timer?.setEventHandler{ [weak self] in
            guard let `self` = self else { return }
            self.fetchServerTime{ [weak self] difference, error in
                guard let `self` = self else { return }
                DispatchQueue.main.async {
                    if let difference = difference {
                        self.currentDifference = difference
                        
                        self.timer?.scheduleOneshot(deadline: .now() + .milliseconds(self.refreshInterval))
                    }
                    else {
                        switch self.onErrorPolicy {
                        case .retainRefreshInterval:
                            self.timer?.scheduleOneshot(deadline: .now() + .milliseconds(self.refreshInterval))
                            return
                        case .retry(attempts: let attempts, interval: let interval):
                            if self.currentRetryAttempt < attempts {
                                self.timer?.scheduleOneshot(deadline: .now() + .milliseconds(interval))
                                self.currentRetryAttempt += 1
                            }
                            else {
                                self.timer?.scheduleOneshot(deadline: .now() + .milliseconds(self.refreshInterval))
                                self.currentRetryAttempt = 0
                            }
                        }
                    }
                }
            }
        }
        
        timer?.resume()
    }
    
    /// Convenience method for fetching the server time and perparing the `Difference` struct
    private func fetchServerTime(callback: @escaping (Difference?, ExposureError?) -> Void) {
        serverTimeProvider.fetchServerTime(using: environment) { serverTime, error in
            guard let serverTime = serverTime?.epochMillis else {
                callback(nil, error)
                return
            }
            
            let difference = Difference(serverStartTime: Int64(serverTime), localStartTime: Date().millisecondsSince1970)
            callback(difference, nil)
        }
    }
}

