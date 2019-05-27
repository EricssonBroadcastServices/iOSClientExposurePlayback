//
//  PlayerControls.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2018-11-30.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit

class PlayerControls: UIView {
    
    var paused: Bool = false
    
    /// Main StackView holding other views
    let playerControlsView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.spacing = 4.0
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    
    /// ProgramInfo View : 1st row
    let startTimeLabel = RBMPlayerControlLabel(labelText: "")
    let endTimeLabel = RBMPlayerControlLabel(labelText: "")
    let programIdLabel: RBMPlayerControlLabel = RBMPlayerControlLabel(labelText: "")
    
    /// Seek info view : 2nd row
    let seekableRangeLabel = RBMPlayerControlLabel(labelText: "Seekable Range")
    let seekableStartTimeLabel = RBMPlayerControlLabel(labelText: "")
    let seekableEndTimeLabel = RBMPlayerControlLabel(labelText: "")
    let seekableStartLabel = RBMPlayerControlLabel(labelText: "")
    let seekableEndLabel: RBMPlayerControlLabel = RBMPlayerControlLabel(labelText: "")
    
    /// buffered time holder : 3rd row
    let bufferedRangeLabel = RBMPlayerControlLabel(labelText: "Buffered Range")
    let bufferedStartTimeLabel = RBMPlayerControlLabel(labelText: "")
    let bufferedEndTimeLabel = RBMPlayerControlLabel(labelText: "")
    let bufferedStartLabel = RBMPlayerControlLabel(labelText: "")
    let bufferedEndLabel = RBMPlayerControlLabel(labelText: "")
    
    // Time labels View Holder : 4th row
    let wallClockTimeLabel = RBMPlayerControlLabel(labelText: "Wallclock time")
    let PlayHeadTimeLabel = RBMPlayerControlLabel(labelText: "Playheadtime")
    let playHeadPositionLabel = RBMPlayerControlLabel(labelText: "Playheadposition")
    
    // Time values View Holder : 5th row
    let wallClockTimeValueLabel = RBMPlayerControlLabel(labelText: "00:00")
    let PlayHeadTimeValueLabel = RBMPlayerControlLabel(labelText: "00")
    let playHeadPositionValueLabel = RBMPlayerControlLabel(labelText: "00")
    
    // RW Enabled Content View : 6th row
    let rwEnabledLabel = RBMPlayerControlLabel(labelText: "RW Enabled")
    let timeShiftEnabledLabel = RBMPlayerControlLabel(labelText: "timeShift Enable")
    let ffEnabledLabel = RBMPlayerControlLabel(labelText: "FF Enabled")
    
    // Buttons : 7th row
    let startOverButton = RBMPlayerControlButton(titleText: "STARTOVER", target: self, action: #selector(startOverAction))
    let ccButton = RBMPlayerControlButton(titleText: "CC", target: self, action: #selector(ccAction))
    let goLiveButton = RBMPlayerControlButton(titleText: "GO Live",target: self, action: #selector(goLiveAction))
    let pausePlayButton = RBMPlayerControlButton(titleText: "PAUSE",target: self, action: #selector(pauseResumeAction))
    
    // RW/ FW Pos : 8th row
    let rwPOSButton = RBMPlayerControlButton(titleText: "<< RW Pos",target: self, action: #selector(rewindAction))
    let ffPOSButton = RBMPlayerControlButton(titleText: "FF Pos >>",target: self, action: #selector(fastForwardAction))
    let manageTimeShift: RBMTextField = {
        let textField = RBMTextField(placeHolderText: "10")
        textField.text = "10"
        textField.keyboardType = .numberPad
        return textField
    }()

    // RW/ FW Time _ 9th row
    let rwTimeButton = RBMPlayerControlButton(titleText: "<< RW Time",target: self, action: #selector(rewindTimeAction))
    let ffTimeButton = RBMPlayerControlButton(titleText: "FF Time >>",target: self, action: #selector(fastForwardTimeAction))
    let manageTimeShiftLabel: RBMTextField = {
        let textField = RBMTextField(placeHolderText: "10")
        textField.text = "10"
        textField.keyboardType = .numberPad
        return textField
    }()
    
    let nextProgramButton = RBMPlayerControlButton(titleText: "Next Program", target: self, action: #selector(nextProgram))
    let previousProgramButton = RBMPlayerControlButton(titleText: "Previous Program", target: self, action: #selector(previousProgram))
    
    var onSeekingTime: (Int64) -> Void = { _ in }
    var onSeeking: (Int64) -> Void = { _ in }
    var onTimeTick: () -> Void = { }
    var onViewDidLoad: () -> Void = { }
    var onPauseResumed: (Bool) -> Void = { _ in }
    var onGoLive: () -> Void = { }
    var onStartOver: () -> Void = { }
    var onCC: () -> Void = { }
    var onNextProgram: () -> Void  = {}
    var onPreviousProgram: ()-> Void = {}
    
    fileprivate let queue = DispatchQueue(label: "com.emp.refApp.timestamp",
                                          qos: DispatchQoS.background,
                                          attributes: DispatchQueue.Attributes.concurrent)
    
    fileprivate var timer: DispatchSourceTimer?
    
    deinit {
        timer?.setEventHandler{}
        timer?.cancel()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupLayout()
        
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now() + .seconds(1), repeating: .seconds(1))
        timer?.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.onTimeTick()
            }
        }
        timer?.resume()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


// MARK: - Layout
extension PlayerControls {
    
    fileprivate func setupLayout() {
        addSubview(playerControlsView)
        
        playerControlsView.anchor(top: topAnchor, bottom: nil, leading: leadingAnchor, trailing: trailingAnchor)
        playerControlsView.heightAnchor.constraint(equalTo: self.heightAnchor , multiplier: 0.7).isActive = true
        
        let programInfoView: UIStackView = UIStackView(arrangedSubviews: [startTimeLabel, programIdLabel, endTimeLabel])
        programInfoView.distribution = .equalSpacing
        playerControlsView.addArrangedSubview(programInfoView)
        
        let seekableRangeView: UIStackView = UIStackView(arrangedSubviews: [seekableRangeLabel, bufferedRangeLabel, seekableStartTimeLabel, seekableEndTimeLabel, seekableStartLabel, seekableEndLabel])
        seekableRangeView.distribution = .equalSpacing
        playerControlsView.addArrangedSubview(seekableRangeView)
        
        let bufferedView: UIStackView = UIStackView(arrangedSubviews: [bufferedRangeLabel, bufferedStartTimeLabel, bufferedEndTimeLabel, bufferedStartLabel, bufferedEndLabel])
        bufferedView.distribution = .equalSpacing
        playerControlsView.addArrangedSubview(bufferedView)
        
        let timeInfoLabelHolderView: UIStackView = UIStackView(arrangedSubviews: [wallClockTimeLabel, PlayHeadTimeLabel, playHeadPositionLabel])
        timeInfoLabelHolderView.distribution = .equalSpacing
        playerControlsView.addArrangedSubview(timeInfoLabelHolderView)
        
        let timeInfoHolderView: UIStackView = UIStackView(arrangedSubviews: [wallClockTimeValueLabel, PlayHeadTimeValueLabel, playHeadPositionValueLabel])
        timeInfoHolderView.distribution = .equalSpacing
        playerControlsView.addArrangedSubview(timeInfoHolderView)
        
        let rwEnabledHolderView: UIStackView = UIStackView(arrangedSubviews: [rwEnabledLabel, timeShiftEnabledLabel, ffEnabledLabel])
        rwEnabledHolderView.distribution = .equalSpacing
        playerControlsView.addArrangedSubview(rwEnabledHolderView)
        
        let buttonsHolderView: UIStackView = UIStackView(arrangedSubviews: [startOverButton, ccButton, goLiveButton, pausePlayButton])
        buttonsHolderView.distribution = .equalSpacing
        playerControlsView.addArrangedSubview(buttonsHolderView)
        
        let manageTimeShiftHolderView: UIStackView = UIStackView(arrangedSubviews: [rwPOSButton, manageTimeShift, ffPOSButton])
        manageTimeShiftHolderView.distribution = .fillProportionally
        playerControlsView.addArrangedSubview(manageTimeShiftHolderView)
        
        let manageTimeShiftHolder : UIStackView = UIStackView(arrangedSubviews:[rwTimeButton, manageTimeShiftLabel, ffTimeButton])
        manageTimeShiftHolder.distribution = .fillProportionally
        playerControlsView.addArrangedSubview(manageTimeShiftHolder)
    
        manageTimeShift.heightAnchor.constraint(equalTo: playerControlsView.heightAnchor, multiplier: 1/9).isActive = true

        manageTimeShiftLabel.heightAnchor.constraint(equalTo: playerControlsView.heightAnchor, multiplier: 1/9).isActive = true
        
        playerControlsView.addArrangedSubview(nextProgramButton)
        playerControlsView.addArrangedSubview(previousProgramButton)
    }
}



// MARK: - Actions
extension PlayerControls {
    
    @objc func pauseResumeAction() {
        let value = paused
        paused = !value
        pausePlayButton.setTitle(paused ? "PLAY" : "PAUSE", for: [])
        onPauseResumed(value)
    }
    
    @objc func fastForwardAction() {
        guard let text = manageTimeShift.text, let value = Int64(text) else { return }
        onSeeking(value)
    }
    
    @objc func rewindAction() {
        guard let text = manageTimeShift.text, let value = Int64(text) else { return }
        onSeeking(-value)
    }
    
    @objc func fastForwardTimeAction() {
        guard let text = manageTimeShiftLabel.text, let value = Int64(text) else { return }
        onSeekingTime(value)
    }
    
    @objc func rewindTimeAction() {
        guard let text = manageTimeShiftLabel.text, let value = Int64(text) else { return }
        onSeekingTime(-value)
    }
    
    @objc func startOverAction() {
        onStartOver()
    }
    
    @objc func goLiveAction() {
        onGoLive()
    }
    
    @objc func ccAction() {
        onCC()
    }
    
    @objc func nextProgram() {
        onNextProgram()
    }
    
    @objc func previousProgram() {
        onPreviousProgram()
    }
    
}
