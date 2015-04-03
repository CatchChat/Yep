//
//  ChatRightTextCell.swift
//  Yep
//
//  Created by NIX on 15/3/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatRightTextCell: UICollectionViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var bubbleBodyImageView: UIImageView!
    @IBOutlet weak var bubbleTailImageView: UIImageView!

    @IBOutlet weak var textContentLabel: UILabel!
    @IBOutlet weak var textContentLabelTrailingConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()

        textContentLabel.font = UIFont.chatTextFont()
        textContentLabelTrailingConstraint.constant = YepConfig.chatCellGapBetweenTextContentLabelAvatar()

        bubbleBodyImageView.tintColor = UIColor.rightBubbleTintColor()
        bubbleTailImageView.tintColor = UIColor.rightBubbleTintColor()

        avatarImageViewWidthConstraint.constant = YepConfig.chatCellAvatarSize()
    }

}
