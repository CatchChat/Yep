//
//  ChatLeftImageCell.swift
//  Yep
//
//  Created by NIX on 15/4/1.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatLeftImageCell: UICollectionViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!

    @IBOutlet weak var messageImageView: UIImageView!
    
    @IBOutlet weak var messageImageViewAspectRatioConstrint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        messageImageViewAspectRatioConstrint.active = false

        let newMessageImageViewAspectRatioConstraint = NSLayoutConstraint(item: messageImageView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: messageImageView, attribute: NSLayoutAttribute.Height, multiplier: YepConfig.messageImageViewAspectRatio(), constant: 0.0)
        NSLayoutConstraint.activateConstraints([newMessageImageViewAspectRatioConstraint])
    }

}
