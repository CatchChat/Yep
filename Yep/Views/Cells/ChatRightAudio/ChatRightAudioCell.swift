//
//  ChatRightAudioCell.swift
//  Yep
//
//  Created by NIX on 15/4/2.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatRightAudioCell: ChatRightBaseCell {

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

    typealias AudioBubbleTapAction = () -> Void
    var audioBubbleTapAction: AudioBubbleTapAction?

    func makeUI() {

        let fullWidth = UIScreen.mainScreen().bounds.width

        let halfAvatarSize = YepConfig.chatCellAvatarSize() / 2

        avatarImageView.center = CGPoint(x: fullWidth - halfAvatarSize - YepConfig.chatCellGapBetweenWallAndAvatar(), y: halfAvatarSize)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        makeUI()

        bubbleImageView.tintColor = UIColor.rightBubbleTintColor()

        sampleView.sampleColor = UIColor.rightWaveColor()

        audioDurationLabel.textColor = UIColor.whiteColor()

        playButton.userInteractionEnabled = false

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
        
        if let sender = message.fromFriend {
            AvatarCache.sharedInstance.roundAvatarOfUser(sender, withRadius: YepConfig.chatCellAvatarSize() * 0.5) { [weak self] roundImage in
                dispatch_async(dispatch_get_main_queue()) {
                    if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                        self?.avatarImageView.image = roundImage
                    }
                }
            }
        }

        updateAudioInfoViews()
    }

    func updateAudioInfoViews() {

        if let message = message {

            if let (audioDuration, audioSamples) = audioMetaOfMessage(message) {

                var simpleViewWidth = CGFloat(audioSamples.count) * (YepConfig.audioSampleWidth() + YepConfig.audioSampleGap()) - YepConfig.audioSampleGap() // 最后最后一个 gap 不要
                simpleViewWidth = max(YepConfig.minMessageSampleViewWidth, simpleViewWidth)
                let width = 60 + simpleViewWidth
                audioContainerView.frame = CGRect(x: CGRectGetMinX(avatarImageView.frame) - 5 - width, y: 0, width: width, height: bounds.height)
                dotImageView.center = CGPoint(x: CGRectGetMinX(audioContainerView.frame) - 5, y: CGRectGetMidY(audioContainerView.frame))


                sampleView.samples = audioSamples

                audioDurationLabel.text = NSString(format: "%.1f\"", audioDuration) as String

                sampleView.progress = CGFloat(audioPlayedDuration / audioDuration)

            } else {
                sampleView.progress = 0

                let width = 60 + 15 * (YepConfig.audioSampleWidth() + YepConfig.audioSampleGap())
                audioContainerView.frame = CGRect(x: CGRectGetMinX(avatarImageView.frame) - 5 - width, y: 0, width: width, height: bounds.height)

                dotImageView.center = CGPoint(x: CGRectGetMinX(audioContainerView.frame) - 5, y: CGRectGetMidY(audioContainerView.frame))

                println(dotImageView.frame)

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

