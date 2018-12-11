//
//  VodBasedTimeline.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2018-11-23.
//  Copyright © 2018 amp. All rights reserved.
//

import UIKit
import Exposure
import AVFoundation

class VodBasedTimeline: UIView {
    
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
        label.font = label.font.withSize(11)
        label.textColor = ColorState.active.button
        return label
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
    
    // Views related to right side
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
        button.addTarget(self, action: #selector(startOverAction), for: .touchUpInside)
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
    
    fileprivate var isSliding: Bool = false
    fileprivate var lastPlayheadSliderValue: Float?
    
    fileprivate var timerQueue = DispatchQueue(label: "com.emp.refApp.vodBasedTimeLine",
                                               qos: DispatchQoS.background,
                                               attributes: DispatchQueue.Attributes.concurrent)
    
    fileprivate var timer: DispatchSourceTimer?
    
    
    /// MARK: Configuration
    var currentPlayheadPosition: () -> Int64? = { return nil }
    var currentDuration: () -> Int64? = { return nil }
    
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
    
    var startOverTrigger: () -> Void = { }
    var onSeek: (Int64) -> Void = { _ in }
}

// MARK: - Timeline Updates
extension VodBasedTimeline {
    
    @objc func startOverAction() {
        startOverTrigger()
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
    
    fileprivate func updateLoop() {
        let playHeadPosition = currentPlayheadPosition()
        let duration = currentDuration()
        
        if let playhead = playHeadPosition, let duration = duration, duration > 0 {
            isHidden = false
            playheadSlider.isHidden = false
            updateTimelabels(playhead: playhead, duration: duration)
            updatePlayheadSlider(playhead: playhead, duration: duration)
        }
        else {
            isHidden = true
        }
    }
    
    fileprivate func updateTimelabels(playhead: Int64, duration: Int64) {
        if playhead <= duration {
            rightTimeLabel.text = timeFormat(time: duration - playhead)
        }
        guard !isSliding else { return }
        leftTimeLabel.text = timeFormat(time: playhead)
    }
    
    fileprivate func updatePlayheadSlider(playhead: Int64, duration: Int64) {
        guard !isSliding else { return }
        if playhead <= duration {
            let progress = Float(playhead) / Float(duration)
            lastPlayheadSliderValue = progress
            playheadSlider.setValue(progress, animated: false)
        }
        else {
            lastPlayheadSliderValue = 1
            playheadSlider.setValue(1, animated: false)
        }
    }
    
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
            
            if let duration = currentDuration() {
                let sliderPosition = Int64(sender.value * Float(duration))
                leftTimeLabel.text = timeFormat(time: sliderPosition)
            }
        }
    }
    
    @objc func seekAction(_ sender: UISlider) {
        isSliding = false
        guard let duration = currentDuration() else { return }
        let rawOffset = Int64(sender.value * Float(duration))
        let seekOffset = min(duration - 1000, rawOffset)
        onSeek(seekOffset)
    }
}


// MARK: - Layout
extension VodBasedTimeline {
    
    fileprivate func setupLayout() {
        addSubview(contentView)
        addSubview(blurView)
        
        addSubview(leftContainerView)
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
        
        // Middle container
        middleContainerView.anchor(top: blurView.topAnchor, bottom: blurView.bottomAnchor, leading: leftContainerView.trailingAnchor, trailing: nil, padding: .init(top: 0, left: 4, bottom: 0, right: -4))
        
        middleContainerView.widthAnchor.constraint(equalTo: blurView.widthAnchor, multiplier: 6/10).isActive = true
        middleContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        // Right Container
        rightContainerView.anchor(top: blurView.topAnchor, bottom: blurView.bottomAnchor, leading: nil, trailing: contentView.trailingAnchor, padding: .init(top: 0, left:0, bottom: 0, right: -4))
        
        startOverButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
        
    }
}

extension VodBasedTimeline {
    fileprivate func timeFormat(time: Int64) -> String {
        return time.timeFormat()
    }
}
