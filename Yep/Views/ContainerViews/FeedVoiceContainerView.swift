//
//  FeedVoiceContainerView.swift
//  Yep
//
//  Created by nixzhu on 15/12/16.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedVoiceContainerView: UIView {

    class func fullWidthWithSampleValuesCount(count: Int, timeLengthString: String) -> CGFloat {
        let rect = timeLengthString.boundingRectWithSize(CGSize(width: 320, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedBasicCell.voiceTimeLengthTextAttributes, context: nil)
        return 10 + 30 + 5 + CGFloat(count) * 3 + 5 + rect.width + 10
    }

    var playOrPauseAudioAction: (() -> Void)?

    var audioPlaying: Bool = false {
        willSet {
            if newValue != audioPlaying {
                if newValue {
                    playButton.setImage(UIImage(named: "icon_pause"), forState: .Normal)
                } else {
                    playButton.setImage(UIImage(named: "icon_playvideo"), forState: .Normal)
                }
            }
        }
    }

    lazy var bubbleImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "feed_audio_bubble")
        imageView.tintColor = UIColor.leftBubbleTintColor()
        return imageView
    }()

    lazy var playButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "icon_playvideo"), forState: .Normal)
        button.tintColor = UIColor.lightGrayColor()
        button.tintAdjustmentMode = .Normal

        button.addTarget(self, action: "playOrPauseAudio:", forControlEvents: .TouchUpInside)
        return button
    }()

    weak var voiceSampleViewWidthConstraint: NSLayoutConstraint?
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

        let tap = UITapGestureRecognizer(target: self, action: "playOrPauseAudio:")
        self.addGestureRecognizer(tap)
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

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-10-[playButton]-5-[voiceSampleView]-5-[timeLengthLabel]-10-|", options: [.AlignAllCenterY], metrics: nil, views: views)

        playButton.setContentHuggingPriority(UILayoutPriorityDefaultHigh, forAxis: .Horizontal)
        timeLengthLabel.setContentHuggingPriority(UILayoutPriorityDefaultHigh, forAxis: .Horizontal)

        NSLayoutConstraint.activateConstraints(constraintsH)

        let voiceSampleViewHeight = NSLayoutConstraint(item: voiceSampleView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 50)

        NSLayoutConstraint.activateConstraints([voiceSampleViewHeight])

        let playButtonCenterY = NSLayoutConstraint(item: playButton, attribute: .CenterY, relatedBy: .Equal, toItem: bubbleImageView, attribute: .CenterY, multiplier: 1.0, constant: 0)

        NSLayoutConstraint.activateConstraints([playButtonCenterY])
    }

    @objc private func playOrPauseAudio(sender: AnyObject) {
        playOrPauseAudioAction?()
    }
}

