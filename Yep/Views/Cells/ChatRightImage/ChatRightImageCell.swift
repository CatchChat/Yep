//
//  ChatRightImageCell.swift
//  Yep
//
//  Created by NIX on 15/3/31.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatRightImageCell: UICollectionViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var messageImageView: UIImageView!

    @IBOutlet weak var messageImageViewWidthConstrint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageViewWidthConstraint.constant = YepConfig.chatCellAvatarSize()
    }

    func configureWithMessage(message: Message, messageImagePreferredWidth: CGFloat, messageImagePreferredHeight: CGFloat, messageImagePreferredAspectRatio: CGFloat) {
        if
            let myUserID = YepUserDefaults.userID(),
            let me = userWithUserID(myUserID) {
                AvatarCache.sharedInstance.roundAvatarOfUser(me, withRadius: YepConfig.chatCellAvatarSize() * 0.5) { roundImage in
                    dispatch_async(dispatch_get_main_queue()) {
                        self.avatarImageView.image = roundImage
                    }
                }
        }

        messageImageView.alpha = 0.0

        if message.metaData.isEmpty {
            messageImageViewWidthConstrint.constant = messageImagePreferredWidth

            ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredWidth, height: ceil(messageImagePreferredWidth / messageImagePreferredAspectRatio)), tailDirection: .Right) { image in
                dispatch_async(dispatch_get_main_queue()) {
                    self.messageImageView.image = image

                    UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                        self.messageImageView.alpha = 1.0
                        }, completion: { (finished) -> Void in
                    })
                }
            }

        } else {
            if let data = message.metaData.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                if let metaDataDict = decodeJSON(data) {
                    if
                        let imageWidth = metaDataDict["image_width"] as? CGFloat,
                        let imageHeight = metaDataDict["image_height"] as? CGFloat {

                            let aspectRatio = imageWidth / imageHeight

                            if aspectRatio >= 1 {
                                messageImageViewWidthConstrint.constant = messageImagePreferredWidth

                                ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredWidth, height: ceil(messageImagePreferredWidth / aspectRatio)), tailDirection: .Right) { image in
                                    dispatch_async(dispatch_get_main_queue()) {
                                        self.messageImageView.image = image

                                        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                                            self.messageImageView.alpha = 1.0
                                            }, completion: { (finished) -> Void in
                                        })
                                    }
                                }

                            } else {
                                messageImageViewWidthConstrint.constant = messageImagePreferredHeight * aspectRatio

                                ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredHeight * aspectRatio, height: messageImagePreferredHeight), tailDirection: .Right) { image in
                                    dispatch_async(dispatch_get_main_queue()) {
                                        self.messageImageView.image = image

                                        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                                            self.messageImageView.alpha = 1.0
                                            }, completion: { (finished) -> Void in
                                        })
                                    }
                                }
                            }
                    }
                }
            }
        }
    }

}
