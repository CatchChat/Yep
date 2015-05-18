//
//  ChatLeftLocationCell.swift
//  Yep
//
//  Created by NIX on 15/5/5.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatLeftLocationCell: UICollectionViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var mapImageView: UIImageView!


    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageViewWidthConstraint.constant = YepConfig.chatCellAvatarSize()

        mapImageView.tintColor = UIColor.leftBubbleTintColor()
    }

    func configureWithMessage(message: Message) {

        if let sender = message.fromFriend {
            AvatarCache.sharedInstance.roundAvatarOfUser(sender, withRadius: YepConfig.chatCellAvatarSize() * 0.5) { roundImage in
                dispatch_async(dispatch_get_main_queue()) {
                    self.avatarImageView.image = roundImage
                }
            }
        }

        ImageCache.sharedInstance.mapImageOfMessage(message, withSize: CGSize(width: 192, height: 108), tailDirection: .Left) { mapImage in
            self.mapImageView.image = mapImage
        }
    }
}
