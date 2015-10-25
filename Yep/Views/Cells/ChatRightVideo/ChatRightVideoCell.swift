//
//  ChatRightVideoCell.swift
//  Yep
//
//  Created by NIX on 15/4/23.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatRightVideoCell: ChatRightBaseCell {

    @IBOutlet weak var thumbnailImageView: UIImageView!

    @IBOutlet weak var playImageView: UIImageView!

    typealias MediaTapAction = () -> Void
    var mediaTapAction: MediaTapAction?

    func makeUI() {

        let fullWidth = UIScreen.mainScreen().bounds.width

        let halfAvatarSize = YepConfig.chatCellAvatarSize() / 2

        avatarImageView.center = CGPoint(x: fullWidth - halfAvatarSize - YepConfig.chatCellGapBetweenWallAndAvatar(), y: halfAvatarSize)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

//        dispatch_async(dispatch_get_main_queue()) { [weak self] in
        makeUI()
//        }

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
        self.user = message.fromFriend

        self.mediaTapAction = mediaTapAction
        
        if let sender = message.fromFriend {
            let userAvatar = UserAvatar(userID: sender.userID, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar)
        }

//        dispatch_async(dispatch_get_main_queue()) { [weak self] in
        thumbnailImageView.alpha = 0.0
//        }

        if let (videoWidth, videoHeight) = videoMetaOfMessage(message) {

            let aspectRatio = videoWidth / videoHeight

            let messageImagePreferredWidth = max(messageImagePreferredWidth, ceil(YepConfig.ChatCell.mediaMinHeight * aspectRatio))
            let messageImagePreferredHeight = max(messageImagePreferredHeight, ceil(YepConfig.ChatCell.mediaMinWidth / aspectRatio))

            if aspectRatio >= 1 {

                let width = messageImagePreferredWidth
//                dispatch_async(dispatch_get_main_queue()) { [weak self] in
//                    if let self = self {
                        self.thumbnailImageView.frame = CGRect(x: CGRectGetMinX(self.avatarImageView.frame) - YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble - width, y: 0, width: width, height: self.bounds.height)
                        self.playImageView.center = CGPoint(x: CGRectGetMidX(self.thumbnailImageView.frame) - YepConfig.ChatCell.playImageViewXOffset, y: CGRectGetMidY(self.thumbnailImageView.frame))
                        self.dotImageView.center = CGPoint(x: CGRectGetMinX(self.thumbnailImageView.frame) - YepConfig.ChatCell.gapBetweenDotImageViewAndBubble, y: CGRectGetMidY(self.thumbnailImageView.frame))
//                    }
//                }

                ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredWidth, height: ceil(messageImagePreferredWidth / aspectRatio)), tailDirection: .Right, completion: { [weak self] progress, image in

                    dispatch_async(dispatch_get_main_queue()) {
                        if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                            self?.loadingWithProgress(progress, image: image)
                        }
                    }
                })

            } else {
                let width = messageImagePreferredHeight * aspectRatio
                
//                dispatch_async(dispatch_get_main_queue()) { [weak self] in
//                    if let self = self {
                        self.thumbnailImageView.frame = CGRect(x: CGRectGetMinX(self.avatarImageView.frame) - YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble - width, y: 0, width: width, height: self.bounds.height)
                        self.playImageView.center = CGPoint(x: CGRectGetMidX(self.thumbnailImageView.frame) - YepConfig.ChatCell.playImageViewXOffset, y: CGRectGetMidY(self.thumbnailImageView.frame))
                        self.dotImageView.center = CGPoint(x: CGRectGetMinX(self.thumbnailImageView.frame) - YepConfig.ChatCell.gapBetweenDotImageViewAndBubble, y: CGRectGetMidY(self.thumbnailImageView.frame))
//                    }
//                }

                ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredHeight * aspectRatio, height: messageImagePreferredHeight), tailDirection: .Right, completion: { [weak self] progress, image in

                    dispatch_async(dispatch_get_main_queue()) {
                        if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                            self?.loadingWithProgress(progress, image: image)
                        }
                    }
                })
            }

        } else {
            let width = messageImagePreferredWidth
            
//            dispatch_async(dispatch_get_main_queue()) { [weak self] in
//                if let self = self {
                    self.thumbnailImageView.frame = CGRect(x: CGRectGetMinX(self.avatarImageView.frame) - YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble - width, y: 0, width: width, height: self.bounds.height)
                    self.playImageView.center = CGPoint(x: CGRectGetMidX(self.thumbnailImageView.frame) - YepConfig.ChatCell.playImageViewXOffset, y: CGRectGetMidY(self.thumbnailImageView.frame))
                    self.dotImageView.center = CGPoint(x: CGRectGetMinX(self.thumbnailImageView.frame) - YepConfig.ChatCell.gapBetweenDotImageViewAndBubble, y: CGRectGetMidY(self.thumbnailImageView.frame))
//                }
//            }


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

