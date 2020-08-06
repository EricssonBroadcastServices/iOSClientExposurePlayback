//
//  Player.swift
//  RefApp
//
//  Created by Karl Holmlöv on 11/1/18.
//  Copyright © 2018 amp. All rights reserved.
//

import UIKit
import Exposure
import ExposurePlayback
import Player
import AVFoundation.AVFAudio.AVAudioSession

class PlayerViewController: UIViewController {
    
    var environment: Environment!
    var sessionToken: SessionToken!
    
    var playable: Playable?
    var program: Program?
    var channel: Asset?
    
    let audioSession = AVAudioSession.sharedInstance()
    var offlineMediaPlayable: OfflineMediaPlayable?
    var playbackProperties = PlaybackProperties()
    fileprivate(set) var player: Player<HLSNative<ExposureContext>>!
    
    /// Main ContentView which holds player view & player control views
    let mainContentView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    let pausePlayButton: UIButton = {
        let button = UIButton()
        button.tintColor = ColorState.active.button
        button.addTarget(self, action: #selector(actionPausePlay(_:)), for: .touchUpInside)
        return button
    }()
    
    let playerView = UIView()
    let programBasedTimeline = ProgramBasedTimeline()
    let vodBasedTimeline = VodBasedTimeline()
    let controls  = PlayerControls()
    
    override func loadView() {
        super.loadView()
        
        setUpLayout()
        setupPlayerControls()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = channel?.assetId
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dissmissKeyboard))
        view.addGestureRecognizer(tapGesture)
        view.bindToKeyboard()
        
        guard let environment = environment, let sessionToken = sessionToken else {
            return
        }
        
        setupPlayer(environment, sessionToken)
        self.enableAudioSeesionForPlayer()
    }
    
    override func didMove(toParent parent: UIViewController?) {
        if let player = self.player, player.tech.isPlaying {
            if playable is ProgramPlayable || playable is ChannelPlayable {
                programBasedTimeline.stopLoop()
            } else if playable is AssetPlayable {
                vodBasedTimeline.stopLoop()
            }
            player.stop()
        }
    }
    
    @objc func dissmissKeyboard() {
        view.endEditing(true)
    }
    
    deinit {
        // view.unbindToKeyboard()
    }
}



// MARK: - Setup Player
extension PlayerViewController {
    
    fileprivate func setupPlayer(_ environment: Environment, _ sessionToken: SessionToken) {
        /// This will configure the player with the `SessionToken` acquired in the specified `Environment`
        player = Player(environment: environment, sessionToken: sessionToken)
        player.configure(playerView: playerView)
        
        // The preparation and loading process can be followed by listening to associated events.
        player
            .onPlaybackCreated{ [weak self] player, source in
                // Fires once the associated MediaSource has been created.
                // Playback is not ready to start at this point.
                self?.updateTimeLine(streamingInfo: source.streamingInfo)
        }
        .onPlaybackPrepared{ player, source in
            // Published when the associated MediaSource completed asynchronous loading of relevant properties.
            // Playback is not ready to start at this point.
        }
        .onPlaybackReady{ player, source in
            // When this event fires starting playback is possible (playback can optionally be set to autoplay instead)
            player.play()
        }
        
        // Once playback is in progress the Player continuously publishes events related media status and user interaction.
        player
            .onPlaybackStarted{ [weak self] player, source in
                // Published once the playback starts for the first time.
                // This is a one-time event.
                guard let `self` = self else { return }
                self.togglePlayPauseButton(paused: false)
        }
        .onPlaybackPaused{ [weak self] player, source in
            // Fires when the playback pauses for some reason
            guard let `self` = self else { return }
            self.togglePlayPauseButton(paused: true)
        }
        .onPlaybackResumed{ [weak self] player, source in
            // Fires when the playback resumes from a paused state
            guard let `self` = self else { return }
            self.togglePlayPauseButton(paused: false)
        }
        .onPlaybackAborted{ player, source in
            // Published once the player.stop() method is called.
            // This is considered a user action
        }
        .onPlaybackCompleted{ player, source in
            // Published when playback reached the end of the current media.
        }
        
        // Besides playback control events Player also publishes several status related events.
        player
            .onProgramChanged { [weak self] player, source, program in
                // Update user facing program information
                guard let `self` = self else { return }
                self.update(withProgram: program)
        }
        .onEntitlementResponse { [weak self] player, source, entitlement in
            // Fires when a new entitlement is received, such as after attempting to start playback
            guard let `self` = self else { return }
            self.update(contractRestrictions: entitlement)
        }
        .onBitrateChanged{ player, source, bitrate in
            // Published whenever the current bitrate changes
            //self?.updateQualityIndicator(with: bitrate)
        }
        .onBufferingStarted{ player, source in
            // Fires whenever the buffer is unable to keep up with playback
        }
        .onBufferingStopped{ player, source in
            // Fires when buffering is no longer needed
        }
        .onDurationChanged{ player, source in
            // Published when the active media received an update to its duration property
        }
        
        // Error handling can be done by listening to associated event.
        player
            .onError{ [weak self] player, source, error in
                guard let `self` = self else { return }
                let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: {
                    (alert: UIAlertAction!) -> Void in
                })
                
                let message = "\(error.code) " + error.message + "\n" + (error.info ?? "")
                self.popupAlert(title: error.domain , message: message, actions: [okAction], preferedStyle: .alert)
        }
            
        .onWarning{ [weak self] player, source, warning in
            guard let `self` = self else { return }
            self.showToastMessage(message: warning.message, duration: 5)
        }
        
        // Playback Progress
        programBasedTimeline.onSeek = { [weak self] offset in
            self?.player.seek(toTime: offset)
        }
        
        programBasedTimeline.currentPlayheadTime = { [weak self] in
            return self?.player.playheadTime
        }
        
        programBasedTimeline.timeBehindLiveEdge = { [weak self] in
            return self?.player.timeBehindLive
        }
        programBasedTimeline.goLiveTrigger = { [weak self] in
            self?.player.seekToLive()
        }
        programBasedTimeline.startOverTrigger = { [weak self] in
            if let programStartTime = self?.player.currentProgram?.startDate?.millisecondsSince1970 {
                self?.player.seek(toTime: programStartTime)
            }
        }
        
        vodBasedTimeline.onSeek = { [weak self] offset in
            self?.player.seek(toPosition: offset)
        }
        vodBasedTimeline.currentPlayheadPosition = { [weak self] in
            return self?.player.playheadPosition
        }
        vodBasedTimeline.currentDuration = { [weak self] in
            return self?.player.duration
        }
        
        vodBasedTimeline.startOverTrigger = { [weak self] in
            self?.player.seek(toPosition:0)
        }
        
        // Start the playback
        self.startPlayBack(properties: playbackProperties)
    }
    
    /// Start the playback with given properties
    ///
    /// - Parameter properties: playback properties
    func startPlayBack(properties: PlaybackProperties = PlaybackProperties() ) {
        
        if let offlineMediaPlayable = offlineMediaPlayable {
            player.startPlayback(offlineMediaPlayable: offlineMediaPlayable)
        } else {
            if let playable = playable {
                vodBasedTimeline.isHidden = true
                programBasedTimeline.isHidden = true
                
                player.startPlayback(playable: playable, properties: properties)
            }
        }
        
        
        
        
    }
    
    func updateTimeLine(streamingInfo: StreamInfo?) {
        
        guard let streamingInfo = streamingInfo else {
            // print("Streaming Info is empty :: Using PlayV1 ")
            // let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: {
            //     (alert: UIAlertAction!) -> Void in
            // })
            
            // let message = "Streaming Info is missing in the play response : You are using a older version of the SDK"
            // self.popupAlert(title: "Error" , message: message, actions: [okAction], preferedStyle: .alert)
            
            vodBasedTimeline.isHidden = false
            vodBasedTimeline.startLoop()
            programBasedTimeline.isHidden = true
            programBasedTimeline.stopLoop()
            
            return
        }
        if streamingInfo.live == true && streamingInfo.staticProgram == false {
            vodBasedTimeline.isHidden = true
            vodBasedTimeline.stopLoop()
            programBasedTimeline.isHidden = false
            programBasedTimeline.startLoop()
        }
            
            // This is a catchup program
        else if streamingInfo.live == false && streamingInfo.staticProgram == false {
            vodBasedTimeline.isHidden = true
            vodBasedTimeline.stopLoop()
            programBasedTimeline.isHidden = false
            programBasedTimeline.startLoop()
        }
            // This is a vod asset
        else if streamingInfo.staticProgram == true {
            vodBasedTimeline.isHidden = false
            vodBasedTimeline.startLoop()
            programBasedTimeline.isHidden = true
            programBasedTimeline.stopLoop()
        }
        else {
            print("something else")
        }
    }
    
    func update(withProgram program: Program?) {
        self.program = program
        controls.programIdLabel.text = (program?.programId ?? self.channel?.assetId) ?? "Unknown"
        controls.startTimeLabel.text = program?.startDate?.dateString(format: "HH:mm") ?? "n/a"
        controls.endTimeLabel.text = program?.endDate?.dateString(format: "HH:mm") ?? "n/a"
        programBasedTimeline.currentProgram = program
    }
    
    func update(contractRestrictions entitlement: PlaybackEntitlement) {
        controls.ffEnabledLabel.text = entitlement.ffEnabled ? "FF enabled" : "FF disabled"
        controls.ffEnabledLabel.textColor = entitlement.ffEnabled ? UIColor.green : UIColor.red
        
        controls.rwEnabledLabel.text = entitlement.rwEnabled ? "RW enabled" : "RW disabled"
        controls.rwEnabledLabel.textColor = entitlement.rwEnabled ? UIColor.green : UIColor.red
        
        controls.timeShiftEnabledLabel.text = entitlement.timeshiftEnabled ? "Timeshift enabled" : "Timeshift disabled"
        controls.timeShiftEnabledLabel.textColor = entitlement.timeshiftEnabled ? UIColor.green : UIColor.red
        
        programBasedTimeline.canFastForward = entitlement.ffEnabled
        programBasedTimeline.canRewind = entitlement.rwEnabled
    }
}


// MARK: - Actions
extension PlayerViewController {
    
    /// Play - Pause Action
    ///
    /// - Parameter sender: pausePlayButton
    @objc fileprivate func actionPausePlay(_ sender: UIButton) {
        if player.isPlaying {
            player.pause()
        }
        else {
            player.play()
        }
    }
    
    /// Change play - pause image depending on user action
    ///
    /// - Parameter paused: user paused or not
    fileprivate func togglePlayPauseButton(paused: Bool) {
        if !paused {
            pausePlayButton.setImage(UIImage(named: "pause"), for: .normal)
        }
        else {
            pausePlayButton.setImage(UIImage(named: "play"), for: .normal)
        }
    }
}



// MARK: - Player Controls
extension PlayerViewController {
    
    func setupPlayerControls() {
        controls.onTimeTick = { [weak self] in
            guard let `self` = self else { return }
            if let currentTime = self.player.serverTime {
                let date = Date(milliseconds: currentTime)
                self.controls.wallClockTimeValueLabel.text = date.dateString(format: "HH:mm:ss")
            }
            else {
                self.controls.wallClockTimeValueLabel.text = "n/a"
            }
            
            let seekableRange = self.player.seekableRanges.map{ ($0.start.seconds, $0.end.seconds) }.first
            let bufferedRange = self.player.bufferedRanges.map{ ($0.start.seconds, $0.end.seconds) }.first
            if let seekable = seekableRange, !seekable.0.isNaN, !seekable.1.isNaN {
                self.controls.seekableStartLabel.text = String(Int64(seekable.0))
                self.controls.seekableEndLabel.text = String(Int64(seekable.1))
            }
            if let buffered = bufferedRange, !buffered.0.isNaN, !buffered.1.isNaN {
                self.controls.bufferedStartLabel.text = String(Int64(buffered.0))
                self.controls.bufferedEndLabel.text = String(Int64(buffered.1))
            }
            
            let seekableTimeRange = self.player.seekableTimeRanges.first
            let bufferedTimeRange = self.player.bufferedTimeRanges.first
            if let seekableTime = seekableTimeRange, let start = seekableTime.start.milliseconds, let end = seekableTime.end.milliseconds {
                let start = Date(milliseconds: start).dateString(format: "HH:mm:ss")
                let end = Date(milliseconds: end).dateString(format: "HH:mm:ss")
                self.controls.seekableStartTimeLabel.text = start
                self.controls.seekableEndTimeLabel.text = end
            }
            else {
                self.controls.seekableStartTimeLabel.text = "n/a"
                self.controls.seekableEndTimeLabel.text = "n/a"
            }
            
            if let bufferedTime = bufferedTimeRange, let start = bufferedTime.start.milliseconds, let end = bufferedTime.end.milliseconds  {
                let start = Date(milliseconds: start).dateString(format: "HH:mm:ss")
                let end = Date(milliseconds: end).dateString(format: "HH:mm:ss")
                self.controls.bufferedStartTimeLabel.text = start
                self.controls.bufferedEndTimeLabel.text = end
            }
            else {
                self.controls.bufferedStartTimeLabel.text = "n/a"
                self.controls.bufferedEndTimeLabel.text = "n/a"
            }
            
            if let playheadTime = self.player.playheadTime {
                let date = Date(milliseconds: playheadTime)
                self.controls.PlayHeadTimeValueLabel.text = date.dateString(format: "HH:mm:ss")
            }
            else {
                self.controls.PlayHeadTimeValueLabel.text = "n/a"
            }
            
            self.controls.playHeadPositionValueLabel.text = String(self.player.playheadPosition/1000)
            
            
        }
        
        controls.onStartOver = { [weak self] in
            guard let `self` = self else { return }
            if let programStartTime = self.player.currentProgram?.startDate?.millisecondsSince1970 {
                self.player.seek(toTime: programStartTime)
            }
            
            if self.playable is AssetPlayable {
                self.player.seek(toPosition:0)
            }
        }
        
        controls.onPauseResumed = { [weak self] paused in
            guard let `self` = self else { return }
            let _ = paused ? self.player.play(): self.player.pause()
        }
        
        controls.onGoLive = { [weak self] in
            guard let `self` = self else { return }
            self.player.seekToLive()
        }
        
        controls.onSeeking = { [weak self] seekDelta in
            guard let `self` = self else { return }
            let currentTime = self.player.playheadPosition
            self.player.seek(toPosition: currentTime + seekDelta * 1000)
        }
        
        controls.onSeekingTime = { [weak self] seekDelta in
            guard let `self` = self else { return }
            if let currentTime = self.player.playheadTime {
                self.player.seek(toTime: currentTime + seekDelta * 1000)
            }
        }
        
        controls.onCC = { [weak self] in
            guard let `self` = self else { return }
            let trackSelectionVC = TrackSelectionViewController()
            trackSelectionVC.assign(audio: self.player.audioGroup)
            trackSelectionVC.assign(text: self.player.textGroup)
            
            trackSelectionVC.onDidSelectAudio = { [weak self] track in
                guard let `self` = self, let track = track as? MediaTrack else { return }
                self.player.selectAudio(track: track)
            }
            trackSelectionVC.onDidSelectText = { [weak self] track in
                guard let `self` = self, let track = track as? MediaTrack else { return }
                self.player.selectText(track: track)
            }
            trackSelectionVC.onDismissed = { [weak trackSelectionVC] in
                trackSelectionVC?.dismiss(animated: true)
            }
            
            self.present(trackSelectionVC, animated: false, completion: nil)
            
        }
        
        controls.onNextProgram = { [weak self] in
            guard let `self` = self else { return }
            self.player.nextProgram()
        }
        
        controls.onPreviousProgram = { [weak self] in
            guard let `self` = self else { return }
            self.player.previousProgram()
        }
    }
}


// MARK: - Layout
extension PlayerViewController {
    fileprivate func setUpLayout() {
        
        view.addSubview(mainContentView)
        mainContentView.addArrangedSubview(playerView)
        
        if #available(iOS 11, *) {
            mainContentView.anchor(top: view.safeAreaLayoutGuide.topAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor)
        } else {
            mainContentView.anchor(top: view.topAnchor, bottom: view.bottomAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor)
        }
        
        playerView.addSubview(programBasedTimeline)
        playerView.addSubview(vodBasedTimeline)
        
        programBasedTimeline.anchor(top: nil, bottom: playerView.bottomAnchor, leading: playerView.leadingAnchor, trailing: playerView.trailingAnchor, padding: .init(top: 0, left: 4, bottom: -10, right: -4))
        
        vodBasedTimeline.anchor(top: nil, bottom: playerView.bottomAnchor, leading: playerView.leadingAnchor, trailing: playerView.trailingAnchor, padding: .init(top: 0, left: 4, bottom: -10, right: -4))
        
        playerView.addSubview(pausePlayButton)
        
        pausePlayButton.anchor(top: nil, bottom: nil, leading: playerView.leadingAnchor, trailing: playerView.trailingAnchor)
        pausePlayButton.centerXAnchor.constraint(equalTo: playerView.centerXAnchor).isActive = true
        pausePlayButton.centerYAnchor.constraint(equalTo: playerView.centerYAnchor).isActive = true
        
        mainContentView.addArrangedSubview(controls)
        
    }
}

extension PlayerViewController {
    /// Enable the audio session for player
    fileprivate func enableAudioSeesionForPlayer() {
        do {
            if #available(iOS 11.0, *) {
                try audioSession.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.moviePlayback, policy: .longForm)
            }
            else {
                try audioSession.setCategory(AVAudioSession.Category.playback)
            }
            try audioSession.setActive(true)
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
    }
    
    
    /// Disable player audio session & continue the background playback
    fileprivate func resumeBackgroundAudio() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print ("setActive(false) ERROR : \(error)")
        }
    }
}



