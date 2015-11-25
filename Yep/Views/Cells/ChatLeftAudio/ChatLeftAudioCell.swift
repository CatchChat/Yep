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

    var audioPlayedDuration: Double = 0 {
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

    @IBOutlet weak var audioContainerView: UIView!

    @IBOutlet weak var bubbleImageView: UIImageView!
    
    @IBOutlet weak var sampleView: SampleView!

    @IBOutlet weak var audioDurationLabel: UILabel!

    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var loadingProgressView: MessageLoadingProgressView!
    
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

        //let fullWidth = UIScreen.mainScreen().bounds.width

        let halfAvatarSize = YepConfig.chatCellAvatarSize() / 2
        
        var topOffset: CGFloat = 0
        
        if inGroup {
            topOffset = YepConfig.ChatCell.marginTopForGroup
        } else {
            topOffset = 0
        }
        

        avatarImageView.center = CGPoint(x: YepConfig.chatCellGapBetweenWallAndAvatar() + halfAvatarSize, y: halfAvatarSize + topOffset)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        UIView.performWithoutAnimation { [weak self] in
            self?.makeUI()
        }

        bubbleImageView.tintColor = UIColor.leftBubbleTintColor()

        sampleView.sampleColor = UIColor.leftWaveColor()

        audioDurationLabel.textColor = UIColor.blackColor()

        playButton.userInteractionEnabled = false
        playButton.tintColor = UIColor.darkGrayColor()
        playButton.tintAdjustmentMode = .Normal

        bubbleImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tapMediaView")
        bubbleImageView.addGestureRecognizer(tap)
        
        bubbleImageView.addGestureRecognizer(longpress)
        
        tap.requireGestureRecognizerToFail(longpress)
    }

    func tapMediaView() {
        audioBubbleTapAction?()
    }
    
    func configureWithMessage(message: Message, audioPlayedDuration: Double, audioBubbleTapAction: AudioBubbleTapAction?, collectionView: UICollectionView, indexPath: NSIndexPath) {

        self.message = message
        self.user = message.fromFriend

        self.audioBubbleTapAction = audioBubbleTapAction

        self.audioPlayedDuration = audioPlayedDuration
        
        YepDownloader.downloadAttachmentsOfMessage(message, reportProgress: { [weak self] progress in
            dispatch_async(dispatch_get_main_queue()) {
                self?.loadingWithProgress(progress)
            }
        })

        UIView.performWithoutAnimation { [weak self] in
            self?.makeUI()
        }

        if let sender = message.fromFriend {
            let userAvatar = UserAvatar(userID: sender.userID, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar)
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
            nameLabel.text = user?.nickname

            let height = YepConfig.ChatCell.nameLabelHeightForGroup
            let x = CGRectGetMaxX(avatarImageView.frame) + YepConfig.chatCellGapBetweenTextContentLabelAndAvatar()
            let y = audioContainerView.frame.origin.y - height
            let width = contentView.bounds.width - x - 10
            nameLabel.frame = CGRect(x: x, y: y, width: width, height: height)
        }
    }
}

