//
//  ChatRightTextCell.swift
//  Yep
//
//  Created by NIX on 15/3/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import TTTAttributedLabel

class ChatRightTextCell: UICollectionViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarImageViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var bubbleBodyImageView: UIImageView!
    @IBOutlet weak var bubbleTailImageView: UIImageView!

    @IBOutlet weak var dotImageView: UIImageView!
    @IBOutlet weak var gapBetweenDotImageViewAndBubbleConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var textContentLabel: TTTAttributedLabel!
    @IBOutlet weak var textContentLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textContentLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textContentLabelWidthConstraint: NSLayoutConstraint!
    
    private var messageStateChangeContent = 0
    
    var messageData: Message!
    
    let sendingAnimationName = "RotationOnStateAnimation"

    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageViewWidthConstraint.constant = YepConfig.chatCellAvatarSize()
        avatarImageViewTrailingConstraint.constant = YepConfig.chatCellGapBetweenWallAndAvatar()

        textContentLabel.linkAttributes = [
            kCTForegroundColorAttributeName: UIColor.whiteColor(),
            kCTUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue,
        ]
        textContentLabel.activeLinkAttributes = [
            kCTForegroundColorAttributeName: UIColor.greenColor(),
            kCTUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue,
        ]
        textContentLabel.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue | NSTextCheckingType.PhoneNumber.rawValue

        textContentLabel.delegate = self

        textContentLabel.font = UIFont.chatTextFont()

        textContentLabelTrailingConstraint.constant = YepConfig.chatCellGapBetweenTextContentLabelAndAvatar()
        textContentLabelLeadingConstraint.constant = YepConfig.chatTextGapBetweenWallAndContentLabel()

        bubbleBodyImageView.tintColor = UIColor.rightBubbleTintColor()
        bubbleTailImageView.tintColor = UIColor.rightBubbleTintColor()

        gapBetweenDotImageViewAndBubbleConstraint.constant = YepConfig.ChatCell.gapBetweenDotImageViewAndBubble
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "messageStateUpdated", name: MessageNotification.MessageStateChanged, object: nil)
    }
    
    func messageStateUpdated() {
        changeStateImage(messageData.sendState)
    }

    func configureWithMessage(message: Message, textContentLabelWidth: CGFloat) {
        messageData = message
        
        textContentLabel.text = message.textContent
        changeStateImage(message.sendState)
        
        textContentLabelWidthConstraint.constant = max(YepConfig.minMessageTextLabelWidth, textContentLabelWidth)
        textContentLabel.textAlignment = textContentLabelWidth < YepConfig.minMessageTextLabelWidth ? .Center : .Left

        if let sender = message.fromFriend {
            AvatarCache.sharedInstance.roundAvatarOfUser(sender, withRadius: YepConfig.chatCellAvatarSize() * 0.5) { roundImage in
                dispatch_async(dispatch_get_main_queue()) {
                    self.avatarImageView.image = roundImage
                }
            }
        }
    }
    
    
    func changeStateImage(state: MessageSendState.RawValue) {
        switch state {
        case MessageSendState.NotSend.rawValue:
            dotImageView.hidden = false
            dotImageView.image = UIImage(named: "icon_dot_sending")
            rotationAnimationOnImageView()
        case MessageSendState.Successed.rawValue:
            dotImageView.hidden = false
            dotImageView.image = UIImage(named: "icon_dot_unread")
            removeSendingAnimation()
        case MessageSendState.Read.rawValue:
            removeSendingAnimation()
            dotImageView.hidden = true
        case MessageSendState.Failed.rawValue:
            removeSendingAnimation()
            dotImageView.hidden = true
        default:
            removeSendingAnimation()
            break
        }
    }
    
    func rotationAnimationOnImageView() {
        var animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0.0
        animation.toValue = 2*M_PI
        animation.duration = 3.0
        animation.repeatCount = MAXFLOAT
        dotImageView.layer.addAnimation(animation, forKey: sendingAnimationName)
    }
    
    func removeSendingAnimation() {
        dotImageView.layer.removeAnimationForKey(sendingAnimationName)
    }
    
    
}

extension ChatRightTextCell: TTTAttributedLabelDelegate {

    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }

    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithPhoneNumber phoneNumber: String!) {
        UIApplication.sharedApplication().openURL(NSURL(string: "tel://" + phoneNumber)!)
    }
}
