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

        avatarImageView.center = CGPoint(x: YepConfig.chatCellGapBetweenWallAndAvatar() + halfAvatarSize, y: halfAvatarSize)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        dispatch_async(dispatch_get_main_queue()) { [weak self] in
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

        if let sender = message.fromFriend {
            AvatarCache.sharedInstance.roundAvatarOfUser(sender, withRadius: YepConfig.chatCellAvatarSize() * 0.5) { [weak self] roundImage in
                dispatch_async(dispatch_get_main_queue()) {
                    if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                        self?.avatarImageView.image = roundImage
                    }
                }
            }
        }

        layoutIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.updateAudioInfoViews()
        }
    }

    func updateAudioInfoViews() {
        
        if let message = message {

            if let (audioDuration, audioSamples) = audioMetaOfMessage(message) {

                var simpleViewWidth = CGFloat(audioSamples.count) * (YepConfig.audioSampleWidth() + YepConfig.audioSampleGap()) - YepConfig.audioSampleGap() // 最后最后一个 gap 不要
                simpleViewWidth = max(YepConfig.minMessageSampleViewWidth, simpleViewWidth)
                let width = 60 + simpleViewWidth
                audioContainerView.frame = CGRect(x: CGRectGetMaxX(avatarImageView.frame) + YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble, y: 0, width: width, height: bounds.height)

                sampleView.samples = audioSamples

                audioDurationLabel.text = NSString(format: "%.1f\"", audioDuration) as String

                sampleView.progress = CGFloat(audioPlayedDuration / audioDuration)

            } else {
                sampleView.progress = 0

                let width = 60 + 15 * (YepConfig.audioSampleWidth() + YepConfig.audioSampleGap())
                audioContainerView.frame = CGRect(x: CGRectGetMaxX(avatarImageView.frame) + YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble, y: 0, width: width, height: bounds.height)

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

        playing = false
    }
}

