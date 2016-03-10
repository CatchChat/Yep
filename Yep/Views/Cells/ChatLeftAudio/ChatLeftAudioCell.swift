//
//  ChatLeftAudioCell.swift
//  Yep
//
//  Created by NIX on 15/4/2.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatLeftAudioCell: ChatBaseCell {

    var message: Message?

    var audioPlayedDuration: NSTimeInterval = 0 {
        willSet {
            updateAudioInfoViews()
        }
    }

    var playing: Bool = false {
        willSet {
            if newValue != playing {
                if newValue {
                    playButton.setImage(UIImage(named: "icon_pause"), forState: .Normal)
                } else {
                    playButton.setImage(UIImage(named: "icon_play"), forState: .Normal)
                }
            }
        }
    }

    lazy var audioContainerView: UIView = {
        let view = UIView()
        return view
    }()

    lazy var bubbleImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "left_tail_bubble"))
        imageView.tintColor = UIColor.leftBubbleTintColor()
        return imageView
    }()

    lazy var sampleView: SampleView = {
        let view = SampleView()
        view.sampleColor = UIColor.leftWaveColor()
        view.userInteractionEnabled = false
        return view
    }()

    lazy var audioDurationLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .Center
        label.textColor = UIColor.blackColor()
        return label
    }()

    lazy var playButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "icon_play"), forState: .Normal)

        button.userInteractionEnabled = false
        button.tintColor = UIColor.darkGrayColor()
        button.tintAdjustmentMode = .Normal

        return button
    }()

    lazy var loadingProgressView: MessageLoadingProgressView = {
        let view = MessageLoadingProgressView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        view.hidden = true
        view.backgroundColor = UIColor.clearColor()
        return view
    }()

    typealias AudioBubbleTapAction = () -> Void
    var audioBubbleTapAction: AudioBubbleTapAction?

    func loadingWithProgress(progress: Double) {
        
        //println("audio loadingWithProgress \(progress)")
        
        if progress == 1.0 {
            loadingProgressView.hidden = true
            
        } else {
            loadingProgressView.progress = progress
            loadingProgressView.hidden = false
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

        UIView.performWithoutAnimation { [weak self] in
            self?.makeUI()
        }

        bubbleImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tapMediaView")
        bubbleImageView.addGestureRecognizer(tap)

        prepareForMenuAction = { otherGesturesEnabled in
            tap.enabled = otherGesturesEnabled
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tapMediaView() {
        audioBubbleTapAction?()
    }
    
    func configureWithMessage(message: Message, audioPlayedDuration: Double, audioBubbleTapAction: AudioBubbleTapAction?, collectionView: UICollectionView, indexPath: NSIndexPath) {

        self.message = message
        self.user = message.fromFriend

        self.audioBubbleTapAction = audioBubbleTapAction

        self.audioPlayedDuration = audioPlayedDuration
        
        YepDownloader.downloadAttachmentsOfMessage(message, reportProgress: { [weak self] progress, _ in
            dispatch_async(dispatch_get_main_queue()) {
                self?.loadingWithProgress(progress)
            }
        })

        UIView.performWithoutAnimation { [weak self] in
            self?.makeUI()
        }

        if let sender = message.fromFriend {
            let userAvatar = UserAvatar(userID: sender.userID, avatarURLString: sender.avatarURLString, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
        }

        layoutIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        UIView.performWithoutAnimation { [weak self] in
            self?.updateAudioInfoViews()
        }
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
                audioContainerView.frame = CGRect(x: CGRectGetMaxX(avatarImageView.frame) + YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble, y: topOffset, width: width, height: bounds.height - topOffset)

                sampleView.samples = audioSamples

                audioDurationLabel.text = NSString(format: "%.1f\"", audioDuration) as String

                sampleView.progress = CGFloat(audioPlayedDuration / audioDuration)

            } else {
                sampleView.progress = 0

                let width = 60 + 15 * (YepConfig.audioSampleWidth() + YepConfig.audioSampleGap())
                audioContainerView.frame = CGRect(x: CGRectGetMaxX(avatarImageView.frame) + YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble, y: topOffset, width: width, height: bounds.height - topOffset)

                audioDurationLabel.text = ""
            }

            bubbleImageView.frame = audioContainerView.bounds
            playButton.frame = CGRect(x: 13, y: 5, width: 30, height: 30)
            loadingProgressView.frame = playButton.frame
            sampleView.frame = CGRect(x: 48, y: 0, width: audioContainerView.bounds.width - 60, height: audioContainerView.bounds.height)
            audioDurationLabel.frame = sampleView.frame
            
            if let audioPlayer = YepAudioService.sharedManager.audioPlayer {
                if audioPlayer.playing {
                    if let playingMessage = YepAudioService.sharedManager.playingMessage {
                        if message.messageID == playingMessage.messageID {
                            playing = true
                            
                            return
                        }
                    }
                }
            }
        }

        audioContainerView.sendSubviewToBack(bubbleImageView)

        configureNameLabel()

        playing = false
    }
    
    private func configureNameLabel() {

        if inGroup {
            nameLabel.text = user?.chatCellCompositedName

            let height = YepConfig.ChatCell.nameLabelHeightForGroup
            let x = CGRectGetMaxX(avatarImageView.frame) + YepConfig.chatCellGapBetweenTextContentLabelAndAvatar()
            let y = audioContainerView.frame.origin.y - height
            let width = contentView.bounds.width - x - 10
            nameLabel.frame = CGRect(x: x, y: y, width: width, height: height)
        }
    }
}

