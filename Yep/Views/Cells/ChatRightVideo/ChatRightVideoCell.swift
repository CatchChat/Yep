//
//  ChatRightVideoCell.swift
//  Yep
//
//  Created by NIX on 15/4/23.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatRightVideoCell: ChatRightBaseCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var thumbnailImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var playImageView: UIImageView!
    @IBOutlet weak var playImageViewCenterXConstraint: NSLayoutConstraint!

    typealias MediaTapAction = () -> Void
    var mediaTapAction: MediaTapAction?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageViewWidthConstraint.constant = YepConfig.chatCellAvatarSize()
        playImageViewCenterXConstraint.constant = YepConfig.ChatCell.centerXOffset

        thumbnailImageView.tintColor = UIColor.rightBubbleTintColor()

        thumbnailImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tapMediaView")
        thumbnailImageView.addGestureRecognizer(tap)
    }

    func tapMediaView() {
        mediaTapAction?()
    }

    var loadingProgress: Double = 0

    func loadingWithProgress(progress: Double, image: UIImage?) {

        if progress >= loadingProgress {

            if progress <= 1.0 {
                loadingProgress = progress
            } else if progress > 1.0 {
                loadingProgress = 1.0
            }

            if let image = image {

                dispatch_async(dispatch_get_main_queue()) {

                    self.thumbnailImageView.image = image

                    UIView.animateWithDuration(YepConfig.ChatCell.imageAppearDuration, delay: 0.0, options: .CurveEaseInOut, animations: { () -> Void in
                        self.thumbnailImageView.alpha = 1.0
                    }, completion: { (finished) -> Void in
                    })
                }
            }
        }
    }
    
    func configureWithMessage(message: Message, messageImagePreferredWidth: CGFloat, messageImagePreferredHeight: CGFloat, messageImagePreferredAspectRatio: CGFloat, mediaTapAction: MediaTapAction?, collectionView: UICollectionView, indexPath: NSIndexPath) {

        self.message = message
        
        self.mediaTapAction = mediaTapAction
        
        if let sender = message.fromFriend {
            AvatarCache.sharedInstance.roundAvatarOfUser(sender, withRadius: YepConfig.chatCellAvatarSize() * 0.5) { [weak self] roundImage in
                dispatch_async(dispatch_get_main_queue()) {
                    if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                        self?.avatarImageView.image = roundImage
                    }
                }
            }
        }

        thumbnailImageView.alpha = 0.0

        if let (videoWidth, videoHeight) = videoMetaOfMessage(message) {

            let aspectRatio = videoWidth / videoHeight

            let messageImagePreferredWidth = max(messageImagePreferredWidth, ceil(YepConfig.ChatCell.mediaMinHeight * aspectRatio))
            let messageImagePreferredHeight = max(messageImagePreferredHeight, ceil(YepConfig.ChatCell.mediaMinWidth / aspectRatio))

            if aspectRatio >= 1 {
                thumbnailImageViewWidthConstraint.constant = messageImagePreferredWidth

                ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredWidth, height: ceil(messageImagePreferredWidth / aspectRatio)), tailDirection: .Right, completion: { [weak self] progress, image in

                    dispatch_async(dispatch_get_main_queue()) {
                        if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                            self?.loadingWithProgress(progress, image: image)
                        }
                    }
                })

            } else {
                thumbnailImageViewWidthConstraint.constant = messageImagePreferredHeight * aspectRatio

                ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredHeight * aspectRatio, height: messageImagePreferredHeight), tailDirection: .Right, completion: { [weak self] progress, image in

                    dispatch_async(dispatch_get_main_queue()) {
                        if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                            self?.loadingWithProgress(progress, image: image)
                        }
                    }
                })
            }

        } else {
            thumbnailImageViewWidthConstraint.constant = messageImagePreferredWidth

            ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredWidth, height: ceil(messageImagePreferredWidth / messageImagePreferredAspectRatio)), tailDirection: .Right, completion: { [weak self] progress, image in

                dispatch_async(dispatch_get_main_queue()) {
                    if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                        self?.loadingWithProgress(progress, image: image)
                    }
                }
            })
        }

    }
}
