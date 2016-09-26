//
//  ChatLeftAudioCell.swift
//  Yep
//
//  Created by NIX on 15/4/2.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class ChatLeftAudioCell: ChatBaseCell {

    var message: Message?

    var audioPlayedDuration: TimeInterval = 0 {
        willSet {
            updateAudioInfoViews()
        }
    }

    var playing: Bool = false {
        willSet {
            if newValue != playing {
                if newValue {
                    playButton.setImage(UIImage.yep_iconPause, for: UIControlState())
                } else {
                    playButton.setImage(UIImage.yep_iconPlay, for: UIControlState())
                }
            }
        }
    }

    lazy var audioContainerView: UIView = {
        let view = UIView()
        return view
    }()

    lazy var bubbleImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.yep_leftTailBubble)
        imageView.tintColor = UIColor.leftBubbleTintColor()
        return imageView
    }()

    lazy var sampleView: SampleView = {
        let view = SampleView()
        view.sampleColor = UIColor.leftWaveColor()
        view.isUserInteractionEnabled = false
        return view
    }()

    lazy var audioDurationLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.black
        return label
    }()

    lazy var playButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.yep_iconPlay, for: UIControlState())

        button.isUserInteractionEnabled = false
        button.tintColor = UIColor.darkGray
        button.tintAdjustmentMode = .normal

        return button
    }()

    lazy var loadingProgressView: MessageLoadingProgressView = {
        let view = MessageLoadingProgressView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        view.isHidden = true
        view.backgroundColor = UIColor.clear
        return view
    }()

    typealias AudioBubbleTapAction = () -> Void
    var audioBubbleTapAction: AudioBubbleTapAction?

    func loadingWithProgress(_ progress: Double) {
        
        //println("audio loadingWithProgress \(progress)")
        
        if progress == 1.0 {
            loadingProgressView.isHidden = true
            
        } else {
            loadingProgressView.progress = progress
            loadingProgressView.isHidden = false
        }
    }

    func makeUI() {

        let halfAvatarSize = YepConfig.chatCellAvatarSize() / 2
        
        var topOffset: CGFloat = 0
        
        if inGroup {
            topOffset = YepConfig.ChatCell.marginTopForGroup
        } else {
            topOffset = 0
        }

        avatarImageView.center = CGPoint(x: YepConfig.chatCellGapBetweenWallAndAvatar() + halfAvatarSize, y: halfAvatarSize + topOffset)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(audioContainerView)
        audioContainerView.addSubview(bubbleImageView)
        audioContainerView.addSubview(playButton)
        audioContainerView.addSubview(loadingProgressView)
        audioContainerView.addSubview(sampleView)
        audioContainerView.addSubview(audioDurationLabel)

        UIView.setAnimationsEnabled(false); do {
            makeUI()
        }
        UIView.setAnimationsEnabled(true)

        bubbleImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(ChatLeftAudioCell.tapMediaView))
        bubbleImageView.addGestureRecognizer(tap)

        prepareForMenuAction = { otherGesturesEnabled in
            tap.isEnabled = otherGesturesEnabled
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tapMediaView() {
        audioBubbleTapAction?()
    }
    
    func configureWithMessage(_ message: Message, audioPlayedDuration: Double, audioBubbleTapAction: AudioBubbleTapAction?) {

        self.message = message
        self.user = message.fromFriend

        self.audioBubbleTapAction = audioBubbleTapAction

        self.audioPlayedDuration = audioPlayedDuration
        
        YepDownloader.downloadAttachmentsOfMessage(message, reportProgress: { [weak self] progress, _ in
            SafeDispatch.async {
                self?.loadingWithProgress(progress)
            }
        })

        UIView.setAnimationsEnabled(false); do {
            makeUI()
        }
        UIView.setAnimationsEnabled(true)

        if let sender = message.fromFriend {
            let userAvatar = UserAvatar(userID: sender.userID, avatarURLString: sender.avatarURLString, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
        }

        layoutIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        UIView.setAnimationsEnabled(false); do {
            updateAudioInfoViews()
        }
        UIView.setAnimationsEnabled(true)
    }

    func updateAudioInfoViews() {
        
        var topOffset: CGFloat = 0
        
        if inGroup {
            topOffset = YepConfig.ChatCell.marginTopForGroup
        } else {
            topOffset = 0
        }
        
        if let message = message {

            if let (audioDuration, audioSamples) = audioMetaOfMessage(message) {

                var simpleViewWidth = CGFloat(audioSamples.count) * (YepConfig.audioSampleWidth() + YepConfig.audioSampleGap()) - YepConfig.audioSampleGap() // 最后最后一个 gap 不要
                simpleViewWidth = max(YepConfig.minMessageSampleViewWidth, simpleViewWidth)
                let width = 60 + simpleViewWidth
                audioContainerView.frame = CGRect(x: (avatarImageView.frame).maxX + YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble, y: topOffset, width: width, height: bounds.height - topOffset)

                sampleView.samples = audioSamples

                audioDurationLabel.text = NSString(format: "%.1f\"", audioDuration) as String

                sampleView.progress = CGFloat(audioPlayedDuration / audioDuration)

            } else {
                sampleView.progress = 0

                let width = 60 + 15 * (YepConfig.audioSampleWidth() + YepConfig.audioSampleGap())
                audioContainerView.frame = CGRect(x: avatarImageView.frame.maxX + YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble, y: topOffset, width: width, height: bounds.height - topOffset)

                audioDurationLabel.text = ""
            }

            bubbleImageView.frame = audioContainerView.bounds
            playButton.frame = CGRect(x: 13, y: 5, width: 30, height: 30)
            loadingProgressView.frame = playButton.frame
            sampleView.frame = CGRect(x: 48, y: 0, width: audioContainerView.bounds.width - 60, height: audioContainerView.bounds.height)
            audioDurationLabel.frame = sampleView.frame
            
            if let audioPlayer = YepAudioService.sharedManager.audioPlayer {
                if audioPlayer.isPlaying {
                    if let playingMessage = YepAudioService.sharedManager.playingMessage {
                        if message.messageID == playingMessage.messageID {
                            playing = true
                            
                            return
                        }
                    }
                }
            }
        }

        audioContainerView.sendSubview(toBack: bubbleImageView)

        configureNameLabel()

        playing = false
    }
    
    fileprivate func configureNameLabel() {

        if inGroup {
            UIView.setAnimationsEnabled(false); do {
                nameLabel.text = user?.compositedName

                let height = YepConfig.ChatCell.nameLabelHeightForGroup
                let x = avatarImageView.frame.maxX + YepConfig.chatCellGapBetweenTextContentLabelAndAvatar()
                let y = audioContainerView.frame.origin.y - height
                let width = contentView.bounds.width - x - 10
                nameLabel.frame = CGRect(x: x, y: y, width: width, height: height)
            }
            UIView.setAnimationsEnabled(true)
        }
    }
}

