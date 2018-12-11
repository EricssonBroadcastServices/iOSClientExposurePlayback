//
//  ProgramBasedTimeline.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2018-11-30.
//  Copyright © 2018 amp. All rights reserved.
//

import UIKit
import Exposure
import AVFoundation

class ProgramBasedTimeline: UIView {
    
    // Main content view which holds the blur view
    let contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    // Blur View which holds all the elements
    let blurView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black
        view.layer.opacity = 0.5
        view.layer.borderColor = ColorState.active.textFieldPlaceholder.cgColor
        view.layer.cornerRadius = 5
        view.layer.borderWidth = 0.2
        return view
    }()
    
    // Three container stack views to hold content
    let leftContainerView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.alignment = .center
        return stackView
    }()
    
    let middleContainerView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.alignment = .center
        return stackView
    }()
    
    let rightContainerView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fill
        stackView.axis = .horizontal
        return stackView
    }()
    
    
    // Views related to left
    let leftTimeLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = ColorState.active.button
        label.font = label.font.withSize(11)
        return label
    }()
    let goLiveIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = ColorState.active.accent
        return view
    }()
    
    let goLiveButton: UIButton = {
        let button = UIButton()
        button.setTitle("LIVE", for: .normal)
        button.titleLabel?.font = UIFont(name: "OpenSans-Light", size: 09)
        button.setTitleColor(ColorState.active.button, for: .normal)
        button.addTarget(self, action: #selector(goLiveAction), for: .touchUpInside)
        button.titleLabel?.font = button.titleLabel?.font.withSize(11)
        return button
    }()
    
    
    // Views related to middle
    let playheadSlider: UISlider = {
        let slider = UISlider()
        slider.minimumTrackTintColor = ColorState.active.accent
        slider.thumbTintColor = ColorState.active.text
        slider.maximumTrackTintColor = ColorState.active.accent
        slider.addTarget(self, action: #selector(seekAction(_:)), for: .touchUpInside)
        slider.addTarget(self, action: #selector(seekAction(_:)), for: .touchUpOutside)
        slider.addTarget(self, action: #selector(playheadSliderAction(_:)), for: .valueChanged)
        return slider
    }()
    
    let liveEdgeIndicator: UIProgressView = {
        let progressview = UIProgressView()
        progressview.progressTintColor = ColorState.active.accent
        progressview.trackTintColor = ColorState.active.accent
        return progressview
    }()
    
    
    // Views related right side
    let rightTimeLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = label.font.withSize(11)
        label.textColor = ColorState.active.button
        return label
    }()
    
    let startOverButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.init(named: "undo"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = ColorState.active.button
        button.addTarget(self, action: #selector(startOverAction(_:)), for: .touchUpInside)
        return button
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        stopLoop()
    }
    
    public func startLoop() {
        timer = DispatchSource.makeTimerSource(queue: self.timerQueue)
        timer?.schedule(wallDeadline: .now(), repeating: .milliseconds(1000))
        timer?.setEventHandler { [weak self] in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                self.updateLoop()
            }
        }
        timer?.resume()
    }
    
    public func stopLoop() {
        timer?.setEventHandler{}
        timer?.cancel()
    }
    
    @objc func goLiveAction(_ sender: UIButton) {
        goLiveTrigger()
    }
    
    @objc func startOverAction(_ sender: UIButton) {
        startOverTrigger()
    }
    
    fileprivate var isSliding: Bool = false
    fileprivate var lastPlayheadSliderValue: Float?
    
    @objc func playheadSliderAction(_ sender: UISlider) {
        isSliding = true
        if let previousValue = lastPlayheadSliderValue {
            if sender.value > previousValue && !canFastForward {
                sender.value = previousValue
                return
            }
            
            if sender.value < previousValue && !canRewind {
                sender.value = previousValue
                return
            }
        }
        
        if !liveEdgeIndicator.isHidden {
            if sender.value > liveEdgeIndicator.progress {
                sender.value = liveEdgeIndicator.progress
                return
            }
        }
        
        guard let startTime = currentProgram?.startDate?.millisecondsSince1970, let endTime = currentProgram?.endDate?.millisecondsSince1970 else { return }
        let seekDelta = Int64(sender.value * Float(endTime-startTime))
        leftTimeLabel.text = timeFormat(time: seekDelta)
    }
    
    @objc func seekAction(_ sender: UISlider) {
        isSliding = false
        guard let startTime = currentProgram?.startDate?.millisecondsSince1970, let endTime = currentProgram?.endDate?.millisecondsSince1970 else { return }
        let seekDelta = Int64(sender.value * Float(endTime-startTime))
        onSeek(startTime + seekDelta)
    }
    
    fileprivate var timerQueue = DispatchQueue(label: "com.emp.refApp.programBasedTimeLine", qos: DispatchQoS.background, attributes: DispatchQueue.Attributes.concurrent)
    fileprivate var timer: DispatchSourceTimer?
    fileprivate func updateLoop() {
        if let program = currentProgram {
            epgUpdateLoop(program: program)
        }
        else {
            noEpgUpdateLoop()
        }
    }
    
    /// MARK: Configuration
    var currentPlayheadTime: () -> Int64? = { return nil }
    var timeBehindLiveEdge: () -> Int64? = { return nil }
    var currentProgram: Program?
    var canFastForward: Bool = true {
        didSet {
            // Update UI restrictions
            if !canFastForward && !canRewind {
                playheadSlider.isUserInteractionEnabled = false
            }
            else {
                playheadSlider.isUserInteractionEnabled = true
            }
        }
    }
    var canRewind: Bool = true {
        didSet {
            // Update UI restrictions
            if !canFastForward && !canRewind {
                playheadSlider.isUserInteractionEnabled = false
            }
            else {
                playheadSlider.isUserInteractionEnabled = true
            }
        }
    }
    
    /// MARK: Actions
    var goLiveTrigger: () -> Void = { }
    var startOverTrigger: () -> Void = { }
    var onSeek: (Int64) -> Void = { _ in }
}



// MARK: - Timeline Updates
extension ProgramBasedTimeline {
    
    fileprivate func epgUpdateLoop(program: Program) {
        startOverButton.isHidden = false
        
        let playheadTime = currentPlayheadTime()
        let timeBehindLive = timeBehindLiveEdge()
        let liveTime = playheadTime != nil && timeBehindLive != nil ? playheadTime! - timeBehindLive! : nil
        
        let programStart = program.startDate?.millisecondsSince1970
        let programEnd = program.endDate?.millisecondsSince1970
        
        // Indicate time left
        updateLeftTimelabel(playheadTime: playheadTime, programEnd: programEnd)
        
        // Indicate current offset
        if let startTime = programStart, let playhead = playheadTime {
            if playhead >= startTime {
                leftTimeLabel.isHidden = false
                leftTimeLabel.text = timeFormat(time: playhead - startTime)
            }
            else {
                // Warning. Program has not started, request new program
                leftTimeLabel.isHidden = true
            }
        }
        else {
            leftTimeLabel.isHidden = true
        }
        
        /// Update playheadSlider
        updatePlayheadSlider(startTime: programStart, playheadTime: playheadTime, endTime: programEnd)
        
        /// Update liveEdge indicator
        updateLiveEdgeIndicator(startTime: programStart, liveTime: liveTime, endTime: programEnd)
        
        // Update live indicator
        updateGoLiveIndicator(playheadTime: playheadTime, liveTime: liveTime)
    }
    
    fileprivate func noEpgUpdateLoop() {
        playheadSlider.isHidden = true
        startOverButton.isHidden = true
        
        rightTimeLabel.isHidden = true
        
        let playheadTime = currentPlayheadTime()
        let timeBehindLive = timeBehindLiveEdge()
        let liveTime = playheadTime != nil && timeBehindLive != nil ? playheadTime! - timeBehindLive! : nil
        
        updatePlayheadSlider(startTime: nil, playheadTime: playheadTime, endTime: nil)
        updateLiveEdgeIndicator(startTime: nil, liveTime: liveTime, endTime: nil)
        updateGoLiveIndicator(playheadTime: playheadTime, liveTime: liveTime)
    }
    
    private func updateLeftTimelabel(playheadTime: Int64?, programEnd: Int64?) {
        guard !isSliding else { return }
        if let endTime = programEnd, let playhead = playheadTime {
            if endTime >= playhead {
                rightTimeLabel.isHidden = false
                rightTimeLabel.text = timeFormat(time: endTime - playhead)
            }
            else {
                // Warning. Program has ended, request new program
                rightTimeLabel.isHidden = true
            }
        }
        else {
            rightTimeLabel.isHidden = true
        }
    }
    
    private func updateGoLiveIndicator(playheadTime: Int64?, liveTime: Int64?) {
        if let playhead = playheadTime, let live = liveTime {
            if isLive(playhead: playhead, live: live) {
                goLiveIndicator.backgroundColor = ColorState.active.accent
            }
            else {
                /// Indicate the time behind live
                goLiveIndicator.backgroundColor = ColorState.active.accentedBackground
            }
        }
        else {
            goLiveIndicator.backgroundColor = ColorState.active.background
            leftTimeLabel.isHidden = true
        }
    }
    
    private func updateLiveEdgeIndicator(startTime: Int64?, liveTime: Int64?, endTime: Int64?) {
        if let live = liveTime, let start = startTime, let end = endTime {
            liveEdgeIndicator.isHidden = false
            if start <= live {
                let progress = live <= end ? Float(live - start) / Float(end - start) : 1
                liveEdgeIndicator.setProgress(Float(progress), animated: false)
            }
            else {
                /// Warning, the program has not started yet
                liveEdgeIndicator.setProgress(0, animated: false)
            }
        }
        else {
            liveEdgeIndicator.isHidden = true
        }
    }
    
    private func updatePlayheadSlider(startTime: Int64?, playheadTime: Int64?, endTime: Int64?) {
        guard !isSliding else { return }
        if let playhead = playheadTime, let start = startTime, let end = endTime {
            playheadSlider.isHidden = false
            if start <= playhead && playhead <= end {
                let progress = Float(playhead - start) / Float(end - start)
                lastPlayheadSliderValue = Float(progress)
                playheadSlider.setValue(Float(progress), animated: false)
            }
            else {
                /// Warning, the program has ended
                lastPlayheadSliderValue = 1
                playheadSlider.setValue(1, animated: false)
            }
        }
        else {
            playheadSlider.isHidden = true
            lastPlayheadSliderValue = nil
        }
    }
}


// MARK: - Timeformat
extension ProgramBasedTimeline {
    fileprivate func timeFormat(time: Int64) -> String {
        return time.timeFormat()
    }
    
    fileprivate func isLive(playhead: Int64, live: Int64) -> Bool {
        let closeEnough: Int64 = 2 * 6000
        let delta = playhead - live
        return abs(delta) < closeEnough
    }
}


// MARK: - Layout
extension ProgramBasedTimeline {
    fileprivate func setupLayout() {
        
        addSubview(contentView)
        addSubview(blurView)
        
        addSubview(leftContainerView)
        
        leftContainerView.addArrangedSubview(goLiveIndicator)
        leftContainerView.addArrangedSubview(goLiveButton)
        leftContainerView.addArrangedSubview(leftTimeLabel)
        
        addSubview(middleContainerView)
        middleContainerView.addArrangedSubview(playheadSlider)
        
        addSubview(rightContainerView)
        rightContainerView.addArrangedSubview(rightTimeLabel)
        rightContainerView.addArrangedSubview(startOverButton)
        
        // Main View
        contentView.anchor(top: self.topAnchor, bottom: self.bottomAnchor, leading: self.leadingAnchor, trailing: self.trailingAnchor)
        
        blurView.anchor(top: contentView.topAnchor, bottom: contentView.bottomAnchor, leading: contentView.leadingAnchor, trailing: contentView.trailingAnchor)
        
        // Left ContainerView
        leftContainerView.anchor(top: blurView.topAnchor, bottom: blurView.bottomAnchor, leading: blurView.leadingAnchor, trailing: nil, padding: .init(top: 0, left: 4, bottom: 0, right: -4))

        goLiveIndicator.anchor(top: nil, bottom: nil, leading: nil, trailing: nil, padding: .init(top: 0, left: 4, bottom: 0, right: 0), size: .init(width: 4, height: 4))
        goLiveIndicator.centerYAnchor.constraint(equalTo: leftContainerView.centerYAnchor).isActive = true

        // Middle container
        middleContainerView.anchor(top: blurView.topAnchor, bottom: blurView.bottomAnchor, leading: leftContainerView.trailingAnchor, trailing: nil, padding: .init(top: 0, left: 4, bottom: 0, right: -4))
        
        middleContainerView.widthAnchor.constraint(equalTo: blurView.widthAnchor, multiplier: 6/10).isActive = true
        middleContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        // Right Container
        rightContainerView.anchor(top: blurView.topAnchor, bottom: blurView.bottomAnchor, leading: nil, trailing: contentView.trailingAnchor, padding: .init(top: 0, left:0, bottom: 0, right: -4))
        
        startOverButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
        
        self.setupAppearance()
    }
    
    func setupAppearance() {
        startOverButton.tintColor = ColorState.active.button
        goLiveButton.tintColor = ColorState.active.button
        leftTimeLabel.textColor = ColorState.active.button
        rightTimeLabel.textColor = ColorState.active.button
        
        playheadSlider.minimumTrackTintColor = ColorState.active.accent
        playheadSlider.thumbTintColor = ColorState.active.text
        playheadSlider.maximumTrackTintColor = .clear
        liveEdgeIndicator.progressTintColor = ColorState.active.accent
        liveEdgeIndicator.trackTintColor = ColorState.active.accent
    }
}

