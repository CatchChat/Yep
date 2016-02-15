//
//  ChatRightVideoCell.swift
//  Yep
//
//  Created by NIX on 15/4/23.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatRightVideoCell: ChatRightBaseCell {

    lazy var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        imageView.tintColor = UIColor.rightBubbleTintColor()
        return imageView
    }()

    lazy var borderImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "right_tail_image_bubble_border"))
        return imageView
    }()

    lazy var playImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "icon_playvideo"))
        return imageView
    }()

    typealias MediaTapAction = () -> Void
    var mediaTapAction: MediaTapAction?

    func makeUI() {

        let fullWidth = UIScreen.mainScreen().bounds.width

        let halfAvatarSize = YepConfig.chatCellAvatarSize() / 2

        avatarImageView.center = CGPoint(x: fullWidth - halfAvatarSize - YepConfig.chatCellGapBetweenWallAndAvatar(), y: halfAvatarSize)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(borderImageView)
        contentView.addSubview(playImageView)

        UIView.performWithoutAnimation { [weak self] in
            self?.makeUI()
        }

        thumbnailImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tapMediaView")
        thumbnailImageView.addGestureRecognizer(tap)

        prepareForMenuAction = { otherGesturesEnabled in
            tap.enabled = otherGesturesEnabled
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

        UIView.performWithoutAnimation { [weak self] in
            self?.makeUI()
        }

        if let sender = message.fromFriend {
            let userAvatar = UserAvatar(userID: sender.userID, avatarURLString: sender.avatarURLString, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
        }

        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.thumbnailImageView.alpha = 0.0
        }

        if let (videoWidth, videoHeight) = videoMetaOfMessage(message) {

            let aspectRatio = videoWidth / videoHeight

            let messageImagePreferredWidth = max(messageImagePreferredWidth, ceil(YepConfig.ChatCell.mediaMinHeight * aspectRatio))
            let messageImagePreferredHeight = max(messageImagePreferredHeight, ceil(YepConfig.ChatCell.mediaMinWidth / aspectRatio))

            if aspectRatio >= 1 {

                let width = messageImagePreferredWidth
                
                UIView.performWithoutAnimation { [weak self] in

                    if let strongSelf = self {
                        strongSelf.thumbnailImageView.frame = CGRect(x: CGRectGetMinX(strongSelf.avatarImageView.frame) - YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble - width, y: 0, width: width, height: strongSelf.bounds.height)
                        strongSelf.playImageView.center = CGPoint(x: CGRectGetMidX(strongSelf.thumbnailImageView.frame) - YepConfig.ChatCell.playImageViewXOffset, y: CGRectGetMidY(strongSelf.thumbnailImageView.frame))
                        strongSelf.dotImageView.center = CGPoint(x: CGRectGetMinX(strongSelf.thumbnailImageView.frame) - YepConfig.ChatCell.gapBetweenDotImageViewAndBubble, y: CGRectGetMidY(strongSelf.thumbnailImageView.frame))

                        strongSelf.borderImageView.frame = strongSelf.thumbnailImageView.frame
                    }
                }

                ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredWidth, height: ceil(messageImagePreferredWidth / aspectRatio)), tailDirection: .Right, completion: { [weak self] progress, image in

                    dispatch_async(dispatch_get_main_queue()) {
                        if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                            self?.loadingWithProgress(progress, image: image)
                        }
                    }
                })

            } else {
                let width = messageImagePreferredHeight * aspectRatio
                
                UIView.performWithoutAnimation { [weak self] in

                    if let strongSelf = self {
                        strongSelf.thumbnailImageView.frame = CGRect(x: CGRectGetMinX(strongSelf.avatarImageView.frame) - YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble - width, y: 0, width: width, height: strongSelf.bounds.height)
                        strongSelf.playImageView.center = CGPoint(x: CGRectGetMidX(strongSelf.thumbnailImageView.frame) - YepConfig.ChatCell.playImageViewXOffset, y: CGRectGetMidY(strongSelf.thumbnailImageView.frame))
                        strongSelf.dotImageView.center = CGPoint(x: CGRectGetMinX(strongSelf.thumbnailImageView.frame) - YepConfig.ChatCell.gapBetweenDotImageViewAndBubble, y: CGRectGetMidY(strongSelf.thumbnailImageView.frame))

                        strongSelf.borderImageView.frame = strongSelf.thumbnailImageView.frame
                    }
                }

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
            
            UIView.performWithoutAnimation { [weak self] in

                if let strongSelf = self {
                    strongSelf.thumbnailImageView.frame = CGRect(x: CGRectGetMinX(strongSelf.avatarImageView.frame) - YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble - width, y: 0, width: width, height: strongSelf.bounds.height)
                    strongSelf.playImageView.center = CGPoint(x: CGRectGetMidX(strongSelf.thumbnailImageView.frame) - YepConfig.ChatCell.playImageViewXOffset, y: CGRectGetMidY(strongSelf.thumbnailImageView.frame))
                    strongSelf.dotImageView.center = CGPoint(x: CGRectGetMinX(strongSelf.thumbnailImageView.frame) - YepConfig.ChatCell.gapBetweenDotImageViewAndBubble, y: CGRectGetMidY(strongSelf.thumbnailImageView.frame))

                    strongSelf.borderImageView.frame = strongSelf.thumbnailImageView.frame
                }
            }

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

