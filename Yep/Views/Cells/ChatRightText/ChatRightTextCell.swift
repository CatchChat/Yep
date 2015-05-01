//
//  ChatRightTextCell.swift
//  Yep
//
//  Created by NIX on 15/3/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

let minTextLabelWidth: CGFloat = 20.0

class ChatRightTextCell: UICollectionViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarImageViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var bubbleBodyImageView: UIImageView!
    @IBOutlet weak var bubbleTailImageView: UIImageView!

    @IBOutlet weak var textContentLabel: UILabel!
    @IBOutlet weak var textContentLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textContentLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textContentLabelWidthConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageViewWidthConstraint.constant = YepConfig.chatCellAvatarSize()
        avatarImageViewTrailingConstraint.constant = YepConfig.chatCellGapBetweenWallAndAvatar()

        textContentLabel.font = UIFont.chatTextFont()
        textContentLabel.textAlignment = NSTextAlignment.Center
        textContentLabelTrailingConstraint.constant = YepConfig.chatCellGapBetweenTextContentLabelAndAvatar()
        textContentLabelLeadingConstraint.constant = YepConfig.chatTextGapBetweenWallAndContentLabel()

        bubbleBodyImageView.tintColor = UIColor.rightBubbleTintColor()
        bubbleTailImageView.tintColor = UIColor.rightBubbleTintColor()


    }

    func configureWithMessage(message: Message, textContentLabelWidth: CGFloat) {
        textContentLabel.text = message.textContent

        if textContentLabelWidth < minTextLabelWidth {
            textContentLabelWidthConstraint.constant = minTextLabelWidth
        }else{
            textContentLabelWidthConstraint.constant = textContentLabelWidth
        }


        if let sender = message.fromFriend {
            AvatarCache.sharedInstance.roundAvatarOfUser(sender, withRadius: YepConfig.chatCellAvatarSize() * 0.5) { roundImage in
                dispatch_async(dispatch_get_main_queue()) {
                    self.avatarImageView.image = roundImage
                }
            }
        }
    }
}
