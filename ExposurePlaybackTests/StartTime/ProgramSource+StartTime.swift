//
//  ProgramSource+StartTime.swift
//  ExposureTests
//
//  Created by Fredrik Sjöberg on 2018-01-29.
//  Copyright © 2018 emp. All rights reserved.
//

import Quick
import Nimble
import Player
import Exposure

@testable import ExposurePlayback

class ProgramSourceStartTimeSpec: QuickSpec {
    override func spec() {
        super.spec()
        let segmentLength:Int64 = 6000
        describe("ProgramSource") {
            let environment = Environment(baseUrl: "url", customer: "customer", businessUnit: "businessUnit")
            let sessionToken = SessionToken(value: "token")
            let tech = HLSNative<ExposureContext>()
            
            context(".defaultBehaviour") {
                context("USP") {
                    let exposureContext = ExposureContext(environment: environment, sessionToken: sessionToken)
                    exposureContext.playbackProperties = PlaybackProperties(playFrom: .defaultBehaviour)
                    context("live program") {
                        it("should use default behavior with lastViewedOffset specified") {
                            let entitlement = buildEntitlement(lastViewedOffset: 100, isLive: true)
                            let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                            source.handleStartTime(for: tech, in: exposureContext)
                            
                            expect(tech.startTime).to(beNil())
                            expect(tech.startPosition).to(beNil())
                        }
                        
                        it("should use default behavior with lastViewedTime specified") {
                            let entitlement = buildEntitlement(lastViewedTime: 100, isLive: true)
                            let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                            source.handleStartTime(for: tech, in: exposureContext)
                            
                            expect(tech.startTime).to(beNil())
                            expect(tech.startPosition).to(beNil())
                        }
                        
                        it("should use default behavior with no bookmarks specified") {
                            let entitlement = buildEntitlement(isLive: true)
                            let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                            source.handleStartTime(for: tech, in: exposureContext)
                            
                            expect(tech.startTime).to(beNil())
                            expect(tech.startPosition).to(beNil())
                        }
                    }
                    
                    context("catchup program") {
                        it("should use default behavior with lastViewedOffset specified") {
                            let entitlement = buildEntitlement(lastViewedOffset: 100)
                            let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                            source.handleStartTime(for: tech, in: exposureContext)
                            
                            expect(tech.startTime).to(beNil())
                            expect(tech.startPosition).to(equal(segmentLength))
                        }
                        
                        it("should use default behavior with lastViewedTime specified") {
                            let entitlement = buildEntitlement(lastViewedTime: 100)
                            let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                            source.handleStartTime(for: tech, in: exposureContext)
                            
                            expect(tech.startTime).to(beNil())
                            expect(tech.startPosition).to(equal(segmentLength))
                        }
                        
                        it("should use default behavior with no bookmarks specified") {
                            let entitlement = buildEntitlement()
                            let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                            source.handleStartTime(for: tech, in: exposureContext)
                            
                            expect(tech.startTime).to(beNil())
                            expect(tech.startPosition).to(equal(segmentLength))
                        }
                    }
                }
                
                context("old pipe") {
                    let exposureContext = ExposureContext(environment: environment, sessionToken: sessionToken)
                    exposureContext.playbackProperties = PlaybackProperties(playFrom: .defaultBehaviour)
                    it("should use default behavior with lastViewedOffset specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe", lastViewedOffset: 100)
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(beNil())
                    }
                    
                    it("should use default behavior with lastViewedTime specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe", lastViewedTime: 100)
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(beNil())
                    }
                    
                    it("should use default behavior with no bookmarks specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe")
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(beNil())
                    }
                }
            }
            
            context(".beginning") {
                
                context("USP") {
                    let exposureContext = ExposureContext(environment: environment, sessionToken: sessionToken)
                    exposureContext.playbackProperties = PlaybackProperties(playFrom: .beginning)
                    it("should start from segmentLength with lastViewedOffset specified") {
                        let entitlement = buildEntitlement(lastViewedOffset: 100)
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(equal(segmentLength))
                    }
                    
                    it("should start from segmentLength with lastViewedTime specified") {
                        let entitlement = buildEntitlement(lastViewedTime: 100)
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(equal(segmentLength))
                    }
                    
                    it("should start from segmentLength with no bookmarks specified") {
                        let entitlement = buildEntitlement()
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(equal(segmentLength))
                    }
                }
                
                context("old pipe") {
                    let exposureContext = ExposureContext(environment: environment, sessionToken: sessionToken)
                    exposureContext.playbackProperties = PlaybackProperties(playFrom: .beginning)
                    it("should rely on vod manifest to start from 0 with lastViewedOffset specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe", lastViewedOffset: 100)
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(beNil())
                    }
                    
                    it("should rely on vod manifest to start from 0 with lastViewedTime specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe", lastViewedTime: 100)
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(beNil())
                    }
                    
                    it("should rely on vod manifest to start from 0 with no bookmarks specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe")
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(beNil())
                    }
                }
            }
            
            context(".bookmark") {
                context("USP") {
                    let exposureContext = ExposureContext(environment: environment, sessionToken: sessionToken)
                    exposureContext.playbackProperties = PlaybackProperties(playFrom: .bookmark)
                    it("should pick up lastViewedOffset if specified") {
                        let entitlement = buildEntitlement(lastViewedOffset: 100)
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(equal(100))
                    }
                    
                    it("should use default behavior with lastViewedTime specified") {
                        let entitlement = buildEntitlement(lastViewedTime: 100)
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(equal(segmentLength))
                    }
                    
                    context("live program") {
                        it("should use default behavior with no bookmarks specified") {
                            let entitlement = buildEntitlement(isLive: true)
                            let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                            source.handleStartTime(for: tech, in: exposureContext)
                            
                            expect(tech.startTime).to(beNil())
                            expect(tech.startPosition).to(beNil())
                        }
                    }
                    
                    context("catchup program") {
                        it("should use default behavior with no bookmarks specified") {
                            let entitlement = buildEntitlement()
                            let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                            source.handleStartTime(for: tech, in: exposureContext)
                            
                            expect(tech.startTime).to(beNil())
                            expect(tech.startPosition).to(equal(segmentLength))
                        }
                    }
                }
                
                context("old pipe") {
                    let exposureContext = ExposureContext(environment: environment, sessionToken: sessionToken)
                    exposureContext.playbackProperties = PlaybackProperties(playFrom: .bookmark)
                    it("should pick up lastViewedOffset if specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe", lastViewedOffset: 100)
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(equal(100))
                    }
                    
                    it("should use default behavior with lastViewedTime specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe", lastViewedTime: 100)
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(beNil())
                    }
                    
                    it("should use default behavior with no bookmarks specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe")
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(beNil())
                    }
                }
            }
            
            context(".customTime") {
                context("USP") {
                    let exposureContext = ExposureContext(environment: environment, sessionToken: sessionToken)
                    exposureContext.playbackProperties = PlaybackProperties(playFrom: .customTime(timestamp: 300))
                    it("should use custom value if lastViewedOffset if specified") {
                        let entitlement = buildEntitlement(lastViewedOffset: 100)
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(equal(300))
                        expect(tech.startPosition).to(beNil())
                    }
                    
                    it("should use custom value if lastViewedTime specified") {
                        let entitlement = buildEntitlement(lastViewedTime: 100)
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(equal(300))
                        expect(tech.startPosition).to(beNil())
                    }
                    
                    it("should use custom value if no bookmarks specified") {
                        let entitlement = buildEntitlement()
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(equal(300))
                        expect(tech.startPosition).to(beNil())
                    }
                }
                
                context("old pipe") {
                    let exposureContext = ExposureContext(environment: environment, sessionToken: sessionToken)
                    exposureContext.playbackProperties = PlaybackProperties(playFrom: .customTime(timestamp: 300))
                    it("should use custom value if lastViewedOffset if specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe", lastViewedOffset: 100)
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startPosition).to(beNil())
                        expect(tech.startTime).to(equal(300))
                    }
                    
                    it("should use custom value if lastViewedTime specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe", lastViewedTime: 100)
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startPosition).to(beNil())
                        expect(tech.startTime).to(equal(300))
                    }
                    
                    it("should use custom value if no bookmarks specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe")
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startPosition).to(beNil())
                        expect(tech.startTime).to(equal(300))
                    }
                }
            }
            context(".customPosition") {
                context("USP") {
                    let exposureContext = ExposureContext(environment: environment, sessionToken: sessionToken)
                    exposureContext.playbackProperties = PlaybackProperties(playFrom: .customPosition(position: 300))
                    it("should use custom value if lastViewedOffset if specified") {
                        let entitlement = buildEntitlement(lastViewedOffset: 100)
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startPosition).to(equal(300))
                        expect(tech.startTime).to(beNil())
                    }
                    
                    it("should use custom value if lastViewedTime specified") {
                        let entitlement = buildEntitlement(lastViewedTime: 100)
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startPosition).to(equal(300))
                        expect(tech.startTime).to(beNil())
                    }
                    
                    it("should use custom value if no bookmarks specified") {
                        let entitlement = buildEntitlement()
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startPosition).to(equal(300))
                        expect(tech.startTime).to(beNil())
                    }
                }
                
                context("old pipe") {
                    let exposureContext = ExposureContext(environment: environment, sessionToken: sessionToken)
                    exposureContext.playbackProperties = PlaybackProperties(playFrom: .customPosition(position: 300))
                    it("should use custom value if lastViewedOffset if specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe", lastViewedOffset: 100)
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(equal(300))
                    }
                    
                    it("should use custom value if lastViewedTime specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe", lastViewedTime: 100)
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(equal(300))
                    }
                    
                    it("should use custom value if no bookmarks specified") {
                        let entitlement = buildEntitlement(pipe: "http://www.old.pipe")
                        let source = ProgramSource(entitlement: entitlement, assetId: "assetId", channelId: "channelId")
                        source.handleStartTime(for: tech, in: exposureContext)
                        
                        expect(tech.startTime).to(beNil())
                        expect(tech.startPosition).to(equal(300))
                    }
                }
            }
        }
        
        func buildEntitlement(pipe: String = "http://www.example.com/.isml", lastViewedOffset: Int? = nil, lastViewedTime: Int? = nil, isLive: Bool = false) -> PlaybackEntitlement {
            var json = PlaybackEntitlement.requiedJson
            json["mediaLocator"] = pipe
            json["live"] = isLive
                
            if let offset = lastViewedOffset {
                json["lastViewedOffset"] = offset
            }
            
            if let offset = lastViewedTime {
                json["lastViewedTime"] = offset
            }
            return json.decode(PlaybackEntitlement.self)!
        }
    }
}
