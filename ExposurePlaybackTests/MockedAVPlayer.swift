//
//  MockedAVPlayer.swift
//  ExposurePlaybackTests
//
//  Created by Fredrik Sjöberg on 2018-02-11.
//  Copyright © 2018 emp. All rights reserved.
//

import AVFoundation

class MockedAVPlayer: AVPlayer {
    var mockedPause: () -> Void = { }
    override func pause() {
        mockedPause()
    }
    
    var mockedPlay: () -> Void = { }
    override func play() {
        mockedPlay()
    }
    
    var mockedReplaceCurrentItem: (AVPlayerItem?) -> Void = { _ in }
    override func replaceCurrentItem(with item: AVPlayerItem?) {
        mockedReplaceCurrentItem(item)
    }
    
    var mockedRate: () -> Float = { return 0}
    var mockedApplyRate: (Float) -> Void = { _ in }
    override var rate: Float {
        get {
            return mockedRate()
        }
        set {
            mockedApplyRate(newValue)
        }
    }
    
}

class MockedAVPlayerItem: AVPlayerItem {
    weak var associatedWithPlayer: MockedAVPlayer?
    
    init(mockedUrl: URL) {
        super.init(asset: AVAsset(url: mockedUrl), automaticallyLoadedAssetKeys: nil)
    }
    
    var mockedSeekToTime: (CMTime, ((Bool) -> Void)?) -> Void = { _,_ in }
    override func seek(to time: CMTime, completionHandler: ((Bool) -> Swift.Void)? = nil) {
        mockedSeekToTime(time, completionHandler)
    }
    
    var mockedSeekToDate: (Date, ((Bool) -> Void)?) -> Bool = { _,_ in return false }
    override  func seek(to date: Date, completionHandler: ((Bool) -> Swift.Void)? = nil) -> Bool {
        return mockedSeekToDate(date, completionHandler)
    }
    
    var mockedSeekableTimeRanges: [NSValue] = []
    override var seekableTimeRanges: [NSValue] {
        return mockedSeekableTimeRanges
    }
    
    var mockedLoadedTimeRanges: [NSValue] = []
    override var loadedTimeRanges: [NSValue] {
        return mockedLoadedTimeRanges
    }
    
    var mockedCurrentTime: CMTime = CMTime(milliseconds: 0)
    override func currentTime() -> CMTime {
        return mockedCurrentTime
    }
    
    var mockedCurrentDate: Date? = nil
    override func currentDate() -> Date? {
        return mockedCurrentDate
    }
    
    var mockedDuration: CMTime = CMTime(milliseconds: 0)
    override var duration: CMTime {
        return mockedDuration
    }
    
    var mockedStatus: AVPlayerItemStatus = .unknown {
        willSet {
            print("willChangeValue")
            self.willChangeValue(forKey: "status")
        }
        didSet {
            print("didChangeValue")
            self.didChangeValue(forKey: "status")
        }
    }
    override var status: AVPlayerItemStatus {
        return mockedStatus
    }
}

class MockedAVURLAsset: AVURLAsset {
    var mockedLoadValuesAsynchronously: ([String], (() -> Void)?) -> Void = { _,_ in }
    override func loadValuesAsynchronously(forKeys keys: [String], completionHandler handler: (() -> Void)? = nil) {
        DispatchQueue(label: "mockedLoadValuesAsynchronously", qos: DispatchQoS.background, attributes: DispatchQueue.Attributes.concurrent).async { [weak self] in
            print("mockedLoadValuesAsynchronously")
            self?.mockedLoadValuesAsynchronously(keys, handler)
        }
    }
    
    var mockedStatusOfValue: (String, NSErrorPointer) -> AVKeyValueStatus = { _,_ in return AVKeyValueStatus.unknown }
    override func statusOfValue(forKey key: String, error outError: NSErrorPointer) -> AVKeyValueStatus {
        return mockedStatusOfValue(key, outError)
    }
    
    var mockedIsPlayable: () -> Bool = { return true }
    override var isPlayable: Bool {
        return mockedIsPlayable()
    }
}
