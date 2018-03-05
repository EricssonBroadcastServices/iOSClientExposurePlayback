//
//  SeekToTimeMock.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-03-05.
//  Copyright © 2018 emp. All rights reserved.
//

import Foundation
import Exposure

@testable import Player
@testable import ExposurePlayback

class SeekToTimeMock {
    let environment = Environment(baseUrl: "http://www.example.com", customer: "customer", businessUnit: "businessUnit")
    let token = SessionToken(value: "token")
    
    func runWithinBoundsTest(playable: Playable, properties: PlaybackProperties, seekTarget: Int64) -> TestEnv {
        let seekOffset: Int64 = 10 * 60 * 1000
        let currentDate = seekTarget - seekOffset
        let hour: Int64 = 60 * 60 * 1000
        
        let env = TestEnv(environment: environment, sessionToken: token)
        env.player.context.isDynamicManifest = { _,_ in return true }
        env.mockAsset(callback: env.defaultAssetMock(currentDate: currentDate, bufferDuration: hour))
        
        // Mock the ProgramService
        env.mockProgramService{ environment, sessionToken, channelId in
            let provider = MockedProgramProvider()
            provider.mockedFetchProgram = { _,_,_, callback in
                let program = Program
                    .validJson(programId: "program1", channelId: "channelId", assetId: "assetId")
                    .timestamp(starting: currentDate, ending: currentDate+hour)
                    .decodeWrap(Program.self)
                callback(program,nil)
            }
            let service = ProgramService(environment: environment, sessionToken: sessionToken, channelId: channelId)
            service.provider = provider
            return service
        }
        
        // Initiate test
        env.player
            .onProgramChanged { player, source, program in
                player.seek(toTime: seekTarget)
            }
            .onPlaybackReady { player, source in
                if let avPlayer = player.tech.avPlayer as? MockedAVPlayer {
                    avPlayer.mockedRate = 1
                }
        }
        
        env.player.startPlayback(playable: playable)

        return env
    }
}
