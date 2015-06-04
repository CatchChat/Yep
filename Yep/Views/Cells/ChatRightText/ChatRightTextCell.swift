//
//  ChatRightTextCell.swift
//  Yep
//
//  Created by NIX on 15/3/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import TTTAttributedLabel

class ChatRightTextCell: ChatRightBaseCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarImageViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var bubbleBodyImageView: UIImageView!
    @IBOutlet weak var bubbleTailImageView: UIImageView!

    //@IBOutlet weak override var dotImageView: UIImageView!
    @IBOutlet weak var gapBetweenDotImageViewAndBubbleConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var textContentLabel: TTTAttributedLabel!
    @IBOutlet weak var textContentLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textContentLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textContentLabelWidthConstraint: NSLayoutConstraint!
    
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
    }
    
    func configureWithMessage(message: Message, textContentLabelWidth: CGFloat) {
        self.message = message
        
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
}

extension ChatRightTextCell: TTTAttributedLabelDelegate {

    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }

    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithPhoneNumber phoneNumber: String!) {
        UIApplication.sharedApplication().openURL(NSURL(string: "tel://" + phoneNumber)!)
    }
}
