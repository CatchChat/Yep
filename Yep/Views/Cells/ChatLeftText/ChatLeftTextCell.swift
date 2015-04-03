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
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var bubbleBodyImageView: UIImageView!
    @IBOutlet weak var bubbleTailImageView: UIImageView!

    @IBOutlet weak var textContentLabel: UILabel!
    @IBOutlet weak var textContentLabelLeadingConstaint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()

        textContentLabel.font = UIFont.chatTextFont()
        textContentLabelLeadingConstaint.constant = YepConfig.chatCellGapBetweenTextContentLabelAvatar()

        bubbleBodyImageView.tintColor = UIColor.leftBubbleTintColor()
        bubbleTailImageView.tintColor = UIColor.leftBubbleTintColor()

        avatarImageViewWidthConstraint.constant = YepConfig.chatCellAvatarSize()
    }

}
