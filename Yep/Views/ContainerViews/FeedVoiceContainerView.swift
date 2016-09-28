//
//  FeedVoiceContainerView.swift
//  Yep
//
//  Created by nixzhu on 15/12/16.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class FeedVoiceContainerView: UIView {

    class func fullWidthWithSampleValuesCount(_ count: Int, timeLengthString: String) -> CGFloat {
        let rect = timeLengthString.boundingRect(with: CGSize(width: 320, height: CGFloat(FLT_MAX)), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: YepConfig.FeedBasicCell.voiceTimeLengthTextAttributes, context: nil)
        return 10 + 30 + 5 + CGFloat(count) * 3 + 5 + rect.width + 10
    }

    var playOrPauseAudioAction: (() -> Void)?

    var audioPlaying: Bool = false {
        willSet {
            if newValue != audioPlaying {
                if newValue {
                    playButton.setImage(UIImage.yep_iconPause, for: UIControlState())
                } else {
                    playButton.setImage(UIImage.yep_iconPlayvideo, for: UIControlState())
                }
            }
        }
    }

    lazy var bubbleImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.yep_feedAudioBubble
        imageView.tintColor = UIColor.leftBubbleTintColor()
        return imageView
    }()

    lazy var playButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.yep_iconPlayvideo, for: UIControlState())
        button.tintColor = UIColor.lightGray
        button.tintAdjustmentMode = .normal

        button.addTarget(self, action: #selector(FeedVoiceContainerView.playOrPauseAudio(_:)), for: .touchUpInside)
        return button
    }()

    weak var voiceSampleViewWidthConstraint: NSLayoutConstraint?
    lazy var voiceSampleView: SampleView = {
        let view = SampleView()
        return view
    }()

    lazy var timeLengthLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.lightGray
        label.font = UIFont.feedVoiceTimeLengthFont()
        return label
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        let tap = UITapGestureRecognizer(target: self, action: #selector(FeedVoiceContainerView.playOrPauseAudio(_:)))
        self.addGestureRecognizer(tap)
    }

    fileprivate func makeUI() {

        addSubview(bubbleImageView)
        addSubview(playButton)
        addSubview(voiceSampleView)
        addSubview(timeLengthLabel)

        bubbleImageView.translatesAutoresizingMaskIntoConstraints = false
        playButton.translatesAutoresizingMaskIntoConstraints = false
        voiceSampleView.translatesAutoresizingMaskIntoConstraints = false
        timeLengthLabel.translatesAutoresizingMaskIntoConstraints = false

        let views: [String: Any] = [
            "bubbleImageView": bubbleImageView,
            "playButton": playButton,
            "voiceSampleView": voiceSampleView,
            "timeLengthLabel": timeLengthLabel,
        ]

        let bubbleImageViewH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[bubbleImageView]|", options: [], metrics: nil, views: views)
        let bubbleImageViewV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[bubbleImageView]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activate(bubbleImageViewH)
        NSLayoutConstraint.activate(bubbleImageViewV)

        let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[playButton]-5-[voiceSampleView]-5-[timeLengthLabel]-10-|", options: [.alignAllCenterY], metrics: nil, views: views)

        playButton.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        timeLengthLabel.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)

        NSLayoutConstraint.activate(constraintsH)

        let voiceSampleViewHeight = NSLayoutConstraint(item: voiceSampleView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 50)

        NSLayoutConstraint.activate([voiceSampleViewHeight])

        let playButtonCenterY = NSLayoutConstraint(item: playButton, attribute: .centerY, relatedBy: .equal, toItem: bubbleImageView, attribute: .centerY, multiplier: 1.0, constant: 0)

        NSLayoutConstraint.activate([playButtonCenterY])
    }

    @objc fileprivate func playOrPauseAudio(_ sender: AnyObject) {
        playOrPauseAudioAction?()
    }
}

