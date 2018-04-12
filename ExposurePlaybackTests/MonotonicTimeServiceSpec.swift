//
//  MonotonicTimeServiceSpec.swift
//  ExposureTests
//
//  Created by Fredrik Sjöberg on 2018-01-08.
//  Copyright © 2018 emp. All rights reserved.
//

import Quick
import Nimble
import Player
import Exposure
import Foundation

@testable import ExposurePlayback

class MockedServerTimeProvider: ServerTimeProvider {
    var mockedFetchServerTime: (Environment, (ServerTime?, ExposureError?) -> Void) -> Void = { _,_ in }
    func fetchServerTime(using environment: Environment, callback: @escaping (ServerTime?, ExposureError?) -> Void) {
        mockedFetchServerTime(environment,callback)
    }
}

class MockedMonotonicServerTimeProvider: ServerTimeProvider {
    var mode: Mode = .delayFirstRequest(first: true)
    enum Mode {
        case delayFirstRequest(first: Bool)
        case errorFirstRequest
    }
    
    func fetchServerTime(using environment: Environment, callback: @escaping (ServerTime?, ExposureError?) -> Void) {
        switch mode {
        case .delayFirstRequest(first: let first):
            if first {
                mode = .delayFirstRequest(first: false)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(150)) {
                    let serverTime = self.createServerTime()
                    self.times.append(serverTime)
                    callback(serverTime, nil)
                }
            }
            else {
                let serverTime = self.createServerTime()
                times.append(serverTime)
                callback(serverTime, nil)
            }
        case .errorFirstRequest:
            if errors < 4 {
                errors += 1
                callback(nil, ExposureError.generalError(error: MockedError.sampleError))
            }
            else {
                let serverTime = self.createServerTime()
                times.append(serverTime)
                callback(serverTime, nil)
            }
        }
        
    }
    var times: [ServerTime] = []
    var errors: Int = 0
    
    enum MockedError: Error {
        case sampleError
    }
    
    func createServerTime() -> ServerTime {
        let json:[String: Any] = [
            "epochMillis": UInt64(Date().millisecondsSince1970)
        ]
        return json.decode(ServerTime.self)!
    }
}

class MonotonicTimeServiceSpec: QuickSpec {
    let environment = Environment(baseUrl: "someUrl", customer: "Customer", businessUnit: "BusinessUnit")
    
    override func spec() {
        super.spec()
        
        
        describe("MonotonicTimeService") {
            
            context("synchronous serverTime") {
                let service = MonotonicTimeService(environment: environment, refreshInterval: 500)
                service.onErrorPolicy = .retry(attempts: 5, interval: 100)
                let provider = MockedMonotonicServerTimeProvider()
                service.serverTimeProvider = provider

                it("should return no current time if not started") {
                    expect(service.serverTime).to(beNil())
                }

                it("should eventually return current time when running") {
                    expect(service.serverTime).toEventuallyNot(beNil())
                }
            }

            context("sync fails") {
                it("should apply retry policy if active") {
                    let service = MonotonicTimeService(environment: self.environment, refreshInterval: 500)
                    service.onErrorPolicy = .retry(attempts: 2, interval: 100)
                    let provider = MockedMonotonicServerTimeProvider()
                    service.serverTimeProvider = provider
                    provider.mode = .errorFirstRequest

                    service.serverTime{ time, error in
                        expect(time).to(beNil())
                    }

                    expect(provider.errors).toEventually(equal(2))
                    expect(provider.times.count).toEventually(equal(1))
                }

                it("should retain default refresh policy if active") {
                    let service = MonotonicTimeService(environment: self.environment, refreshInterval: 500)
                    service.onErrorPolicy = .retainRefreshInterval
                    let provider = MockedMonotonicServerTimeProvider()
                    service.serverTimeProvider = provider
                    provider.mode = .errorFirstRequest

                    service.serverTime{ time, error in
                        expect(time).to(beNil())
                    }

                    expect(provider.errors).toEventually(equal(2))
                    expect(provider.times.count).toEventually(equal(0))
                }
            }

            context("forcing updates disabled") {
                it("should not do network call when no server time is cached") {
                    let service = MonotonicTimeService(environment: self.environment, refreshInterval: 100)
                    service.onErrorPolicy = .retry(attempts: 5, interval: 100)
                    let provider = MockedMonotonicServerTimeProvider()
                    service.serverTimeProvider = provider

                    var times: [Int64] = []
                    service.serverTime{ time, error in
                        if let time = time {
                            times.append(time)
                        }
                    }

                    service.serverTime(forceRefresh: false) { time, error in
                        if let time = time {
                            times.append(time)
                        }
                    }

                    expect(provider.times.count).toEventually(equal(5))
                    expect(times.count).toEventually(equal(1))
                }
            }

            context("forcing updates enabled") {
                let service = MonotonicTimeService(environment: environment, refreshInterval: 100)
                service.onErrorPolicy = .retry(attempts: 5, interval: 100)
                let provider = MockedMonotonicServerTimeProvider()
                service.serverTimeProvider = provider

                it("should do network call when no server time is cached") {
                    var times: [Int64] = []
                    service.serverTime{ time, error in
                        if let time = time {
                            times.append(time)
                        }
                    }

                    service.serverTime(forceRefresh: true) { time, error in
                        if let time = time {
                            times.append(time)
                        }
                    }

                    expect(provider.times.count).toEventually(equal(5))
                    expect(times.count).toEventually(equal(2))
                }
            }
        }

        describe("MonotonicTimeService Difference") {
            let tolerance: Int64 = 210
            let date = Date().millisecondsSince1970
            let difference = MonotonicTimeService.Difference(serverStartTime: date + 400, localStartTime: date + 200)
            let monotonicTime = difference.monotonicTime(date: Date())
            it("should calculate servertime within reasonable bounds") {
                expect(monotonicTime).to(beGreaterThan(date-tolerance))
                expect(monotonicTime).to(beLessThan(date+tolerance))
            }
        }
    }
}
