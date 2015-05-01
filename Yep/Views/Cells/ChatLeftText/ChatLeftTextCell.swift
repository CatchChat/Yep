//
//  ChatLeftTextCell.swift
//  Yep
//
//  Created by NIX on 15/3/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatLeftTextCell: UICollectionViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarImageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var bubbleBodyImageView: UIImageView!
    @IBOutlet weak var bubbleTailImageView: UIImageView!

    @IBOutlet weak var textContentLabel: UILabel!
    @IBOutlet weak var textContentLabelLeadingConstaint: NSLayoutConstraint!
    @IBOutlet weak var textContentLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textContentLabelWidthConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageViewLeadingConstraint.constant = YepConfig.chatCellGapBetweenWallAndAvatar()
        avatarImageViewWidthConstraint.constant = YepConfig.chatCellAvatarSize()

        textContentLabel.font = UIFont.chatTextFont()
        textContentLabel.textAlignment = NSTextAlignment.Center
        textContentLabelLeadingConstaint.constant = YepConfig.chatCellGapBetweenTextContentLabelAndAvatar()
        textContentLabelTrailingConstraint.constant = YepConfig.chatTextGapBetweenWallAndContentLabel()

        bubbleBodyImageView.tintColor = UIColor.leftBubbleTintColor()
        bubbleTailImageView.tintColor = UIColor.leftBubbleTintColor()
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
