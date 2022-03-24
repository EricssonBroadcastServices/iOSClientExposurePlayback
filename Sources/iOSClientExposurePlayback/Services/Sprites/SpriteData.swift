//
//  SpriteData.swift
//  ExposurePlayback
//
//  Created by Udaya Sri Senarathne on 2021-02-01.
//  Copyright © 2021 emp. All rights reserved.
//

import Foundation


/// SpriteData
public struct SpriteData: Codable {
    public let duration:TimeInterval
    public let timelinePosition:Int
    public let spriteImage: String
    public let frame: VttFrame
    public let startTime:TimeInterval
    public let endTime:TimeInterval
    
    
    public init(duration: TimeInterval , timelinePosition: Int,startTime: TimeInterval,endTime: TimeInterval, spriteImage: String, frame: VttFrame) {
        self.duration = duration
        self.timelinePosition = timelinePosition
        self.startTime = startTime
        self.endTime = endTime
        self.spriteImage = spriteImage
        self.frame = frame
    }
}


/// Vtt Frame
public struct VttFrame: Codable {
    public let x: Int
    public let y:Int
    public let width: Int
    public let height:Int
    
    public init(x:Int, y:Int, width:Int, height: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}
