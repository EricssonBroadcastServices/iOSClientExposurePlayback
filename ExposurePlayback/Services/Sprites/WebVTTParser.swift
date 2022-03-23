//
//  WebVTTParser.swift
//  ExposurePlayback
//
//  Created by Udaya Sri Senarathne on 2021-01-21.
//  Copyright © 2021 emp. All rights reserved.
//

import Foundation
import iOSClientExposure

public enum WebVTTError: Error {
    case invalidSignature
}

public class WebVTTParser {
    fileprivate let scanner: CustomScanner
    
    fileprivate static let spaceDelimiterSet = CharacterSet(charactersIn: "\u{0020}\u{0009}\u{000A}")
    fileprivate static let newlineSet = CharacterSet(charactersIn: "\u{000A}")
    
    private var seenCue = false
    
    let vttUrl: URL
    
    public init(string: String, vttUrl: URL) {
        self.vttUrl = vttUrl
            let string = string
                .replacingOccurrences(of: "\u{0000}", with: "\u{FFFD}")
                .replacingOccurrences(of: "\u{000D}\u{000A}", with: "\u{000A}")
                .replacingOccurrences(of: "\u{000D}", with: "\u{000A}")
            scanner = CustomScanner(string: string)
        }
    
    public func parse() throws -> WebVTT {
        guard
            let signature = scanner.scanUpToCharacters(from: WebVTTParser.spaceDelimiterSet),
            signature == "WEBVTT"
            else { throw WebVTTError.invalidSignature }
        
        scanner.scanUpToCharacters(from: WebVTTParser.newlineSet, thenSkip: 1)
        
        guard !scanner.isAtEnd else { return WebVTT(cues: []) }
        
        if scanner.peekCharacter() != "\u{000A}" {
            _ = parseBlock(inHeader: true)
        } else {
            scanner.skip(1)
        }
        
        scanner.scanCharacters(from: WebVTTParser.newlineSet)
        
        var cues: [WebVTT.Cue] = []
        while !scanner.isAtEnd {
            let block = parseBlock(inHeader: false)
            
            if case .cue(let start, let end, let text)? = block {
                
               
                let imageUrl = CueTextParser(string: text, vttUrl: self.vttUrl ).parseImageUrl()
                let frame = CueTextParser(string: text, vttUrl: self.vttUrl).parseFrame()
                let timing = WebVTT.Timing(start: start, end: end)
                cues.append(WebVTT.Cue(timing: timing, imageUrl: imageUrl, frame: frame ))
            }
            
            scanner.scanCharacters(from: WebVTTParser.newlineSet)
        }
        return WebVTT(cues: cues)
    }
    
    fileprivate enum Block {
        case unknown(String)
        case stylesheet(String)
        case region(String)
        case cue(Int, Int, String)
    }
    
    private func parseBlock(inHeader: Bool) -> Block? {
        
        enum BlockType {
            case cue
        }
        
        var lineCount = 0
        var prevPosition = scanner.scanLocation
        var buffer = ""
        var seenEOF = false
        var seenArrow = false
        var cueTiming: (Int, Int)? = nil
        var blockType: BlockType? = nil
        
        while !seenEOF {
            let line = scanner.scanUpToCharacters(from: WebVTTParser.newlineSet, thenSkip: 1)
            lineCount += 1
            seenEOF = scanner.isAtEnd
            if line?.contains("-->") == true {
                if !inHeader, (lineCount == 1 || (lineCount == 2 && !seenArrow)) {
                    seenArrow = true
                    prevPosition = scanner.scanLocation
                    cueTiming = CueInfoParser(string: line!).parse()
                    blockType = .cue
                    buffer = ""
                    seenCue = true
                } else {
                    scanner.scanLocation = prevPosition
                    break
                }
            } else if line == nil || line!.isEmpty {
                break
            } else {
                if !inHeader, lineCount == 2 {
                    if !seenCue, buffer.hasPrefix("STYLE") {
                        // create css
//                        blockType = .stylesheet
                        buffer = ""
                    } else if !seenCue, buffer.hasPrefix("REGION") {
                        // create region
//                        blockType = .region
                        buffer = ""
                    }
                }
                if !buffer.isEmpty { buffer += "\u{000A}" }
                buffer += line ?? ""
                prevPosition = scanner.scanLocation
            }
        }
        guard blockType != nil else { return .unknown(buffer) }
        switch blockType! {
        case .cue:
            guard cueTiming != nil else { return nil }
            return .cue(cueTiming!.0, cueTiming!.1, buffer)
        }
    }
}

fileprivate class CueInfoParser {
    let scanner: CustomScanner
    init(string: String) {
        scanner = CustomScanner(string: string)
    }
    
    fileprivate static let separatorSet = CharacterSet(charactersIn: ":.")
    
    func parse() -> (Int, Int)? {
        guard let from = parseTiming() else { return nil }
        scanner.scanCharacters(from: WebVTTParser.spaceDelimiterSet)
        guard scanner.peek(3) == "-->" else { return nil }
        scanner.skip(3)
        scanner.scanCharacters(from: WebVTTParser.spaceDelimiterSet)
        guard let to = parseTiming() else { return nil }
        // followed by optional (whitespace+, settings)
        return (from, to)
    }
    
    func parseTiming() -> Int? {
        guard let value1 = scanner.scanInt(), scanner.peekCharacter() == ":" else { return nil }
        var totalTime: Int = value1 * 60 * 1000
        scanner.skip(1)
        guard let value2 = scanner.scanInt(), let separator = scanner.scanCharacters(from: CueInfoParser.separatorSet) else { return nil }
        if separator == ":" {
            totalTime *= 60
            totalTime += value2 * 60 * 1000
            guard let value3 = scanner.scanInt(), scanner.peekCharacter() == "." else { return nil }
            totalTime += value3 * 1000
            scanner.skip(1)
        } else {
            totalTime += value2 * 1000
        }
        guard let milliseconds = scanner.scanInt() else { return nil }
        totalTime += milliseconds
        
        return totalTime
    }
}


fileprivate class CueTextParser {
    let text: String
    let vttUrl: URL
    init(string: String, vttUrl: URL) {
        self.text = string
        self.vttUrl = vttUrl
    }
    
    func parseImageUrl() -> String? {
        
        guard let imageNameText = text.components(separatedBy: "#").first else { return nil }
        // Absolute sprite url return it : ex: = http://www.spritegenerator.com/sprite.jpg
        if (imageNameText.starts(with: "http://")) {
            return imageNameText
        }
        
        // Root relative vtt url : ex := /L23/…/sprite.jpg
        else if imageNameText.starts(with: "/") {
            
            var components = URLComponents()
            components.scheme = self.vttUrl.scheme
            components.host = self.vttUrl.host
            
            if let baseUrl = components.url {
                return (baseUrl.appendingPathComponent(imageNameText)).absoluteString
            } else {
                return nil
            }
        }
        // Relative url : ex: = sprite.jpg
        else {
            return (self.vttUrl.deletingLastPathComponent().appendingPathComponent(imageNameText)).absoluteString
        }
    }
    
    func parseFrame() -> VttFrame? {
        let frameText =  text.components(separatedBy: "#xywh=").last
        if let frames = frameText?.components(separatedBy: ","), let x = Int(frames[0]) , let y = Int(frames[1]) , let width = Int(frames[2]) , let height = Int(frames[3]) {
            return VttFrame(x: x, y: y, width: width, height: height)
        } else {
            return nil
        }
    }
    
}
