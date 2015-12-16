//
//  FeedVoiceContainerView.swift
//  Yep
//
//  Created by nixzhu on 15/12/16.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedVoiceContainerView: UIView {

    var playOrPauseAudioAction: (() -> Void)?

    var audioPlaying: Bool = false {
        willSet {
            if newValue != audioPlaying {
                if newValue {
                    playButton.setImage(UIImage(named: "icon_pause"), forState: .Normal)
                } else {
                    playButton.setImage(UIImage(named: "icon_play"), forState: .Normal)
                }
            }
        }
    }

    lazy var bubbleImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "bubble_body")
        imageView.tintColor = UIColor.leftBubbleTintColor()
        return imageView
    }()

    lazy var playButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "icon_play"), forState: .Normal)
        button.tintColor = UIColor.lightGrayColor()
        button.tintAdjustmentMode = .Normal

        button.addTarget(self, action: "playOrPauseAudio:", forControlEvents: .TouchUpInside)
        return button
    }()

    lazy var voiceSampleView: SampleView = {
        let view = SampleView()
        return view
    }()

    lazy var timeLengthLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.lightGrayColor()
        label.font = UIFont.feedVoiceTimeLengthFont()
        return label
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    private func makeUI() {

        addSubview(bubbleImageView)
        addSubview(playButton)
        addSubview(voiceSampleView)
        addSubview(timeLengthLabel)

        bubbleImageView.translatesAutoresizingMaskIntoConstraints = false
        playButton.translatesAutoresizingMaskIntoConstraints = false
        voiceSampleView.translatesAutoresizingMaskIntoConstraints = false
        timeLengthLabel.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "bubbleImageView": bubbleImageView,
            "playButton": playButton,
            "voiceSampleView": voiceSampleView,
            "timeLengthLabel": timeLengthLabel,
        ]

        let bubbleImageViewH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[bubbleImageView]|", options: [], metrics: nil, views: views)
        let bubbleImageViewV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[bubbleImageView]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activateConstraints(bubbleImageViewH)
        NSLayoutConstraint.activateConstraints(bubbleImageViewV)

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-7-[playButton]-5-[voiceSampleView]-5-[timeLengthLabel]-5-|", options: [.AlignAllCenterY], metrics: nil, views: views)

        playButton.setContentHuggingPriority(UILayoutPriorityDefaultHigh, forAxis: .Horizontal)
        timeLengthLabel.setContentHuggingPriority(UILayoutPriorityDefaultHigh, forAxis: .Horizontal)

        NSLayoutConstraint.activateConstraints(constraintsH)

        let voiceSampleViewHeight = NSLayoutConstraint(item: voiceSampleView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 40)

        NSLayoutConstraint.activateConstraints([voiceSampleViewHeight])

        let playButtonCenterY = NSLayoutConstraint(item: playButton, attribute: .CenterY, relatedBy: .Equal, toItem: bubbleImageView, attribute: .CenterY, multiplier: 1.0, constant: 0)

        NSLayoutConstraint.activateConstraints([playButtonCenterY])
    }

    @objc private func playOrPauseAudio(sender: UIButton) {
        playOrPauseAudioAction?()
    }
}

