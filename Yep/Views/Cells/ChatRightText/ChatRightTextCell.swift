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
    
    @IBOutlet weak var textContentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        textContentLabel.font = UIFont.chatTextFont()

        avatarImageViewWidthConstraint.constant = YepConfig.chatCellAvatarSize()
    }

}
