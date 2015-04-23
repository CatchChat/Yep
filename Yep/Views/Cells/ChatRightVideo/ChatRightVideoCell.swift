//
//  ChatRightVideoCell.swift
//  Yep
//
//  Created by NIX on 15/4/23.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatRightVideoCell: UICollectionViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var thumbnailImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var playImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageViewWidthConstraint.constant = YepConfig.chatCellAvatarSize()
    }

    func configureWithMessage(message: Message, messageImagePreferredWidth: CGFloat, messageImagePreferredHeight: CGFloat, messageImagePreferredAspectRatio: CGFloat) {
        if let sender = message.fromFriend {
            AvatarCache.sharedInstance.roundAvatarOfUser(sender, withRadius: YepConfig.chatCellAvatarSize() * 0.5) { roundImage in
                dispatch_async(dispatch_get_main_queue()) {
                    self.avatarImageView.image = roundImage
                }
            }
        }

        thumbnailImageView.alpha = 0.0

        if message.metaData.isEmpty {
            thumbnailImageViewWidthConstraint.constant = messageImagePreferredWidth

            ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredWidth, height: ceil(messageImagePreferredWidth / messageImagePreferredAspectRatio)), tailDirection: .Right) { image in
                dispatch_async(dispatch_get_main_queue()) {
                    self.thumbnailImageView.image = image

                    UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                        self.thumbnailImageView.alpha = 1.0
                        }, completion: { (finished) -> Void in
                    })
                }
            }

        } else {
            if let data = message.metaData.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                if let metaDataDict = decodeJSON(data) {
                    if
                        let imageWidth = metaDataDict["video_width"] as? CGFloat,
                        let imageHeight = metaDataDict["video_height"] as? CGFloat {

                            let aspectRatio = imageWidth / imageHeight

                            if aspectRatio >= 1 {
                                thumbnailImageViewWidthConstraint.constant = messageImagePreferredWidth

                                ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredWidth, height: ceil(messageImagePreferredWidth / aspectRatio)), tailDirection: .Right) { image in
                                    dispatch_async(dispatch_get_main_queue()) {
                                        self.thumbnailImageView.image = image

                                        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                                            self.thumbnailImageView.alpha = 1.0
                                            }, completion: { (finished) -> Void in
                                        })
                                    }
                                }

                            } else {
                                thumbnailImageViewWidthConstraint.constant = messageImagePreferredHeight * aspectRatio

                                ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredHeight * aspectRatio, height: messageImagePreferredHeight), tailDirection: .Right) { image in
                                    dispatch_async(dispatch_get_main_queue()) {
                                        self.thumbnailImageView.image = image

                                        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                                            self.thumbnailImageView.alpha = 1.0
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
