//
//  ChatRightImageCell.swift
//  Yep
//
//  Created by NIX on 15/3/31.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatRightImageCell: ChatRightBaseCell {

    lazy var messageImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        imageView.tintColor = UIColor.rightBubbleTintColor()
        imageView.maskView = self.messageImageMaskImageView
        return imageView
    }()

    lazy var borderImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "right_tail_image_bubble_border"))
        return imageView
    }()

    lazy var loadingProgressView: MessageLoadingProgressView = {
        let view = MessageLoadingProgressView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        view.hidden = true
        view.backgroundColor = UIColor.clearColor()
        return view
    }()

    typealias MediaTapAction = () -> Void
    var mediaTapAction: MediaTapAction?

    lazy var messageImageMaskImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "right_tail_image_bubble"))
        return imageView
    }()

    func makeUI() {

        let fullWidth = UIScreen.mainScreen().bounds.width

        let halfAvatarSize = YepConfig.chatCellAvatarSize() / 2

        avatarImageView.center = CGPoint(x: fullWidth - halfAvatarSize - YepConfig.chatCellGapBetweenWallAndAvatar(), y: halfAvatarSize)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(messageImageView)
        contentView.addSubview(borderImageView)
        contentView.addSubview(loadingProgressView)

        UIView.performWithoutAnimation { [weak self] in
            self?.makeUI()
        }

        messageImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tapMediaView")
        messageImageView.addGestureRecognizer(tap)

        prepareForMenuAction = { otherGesturesEnabled in
            tap.enabled = otherGesturesEnabled
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        messageImageView.image = nil
    }

    func tapMediaView() {
        mediaTapAction?()
    }

    var loadingProgress: Double = 0 {
        willSet {
            if newValue == 1.0 {
                loadingProgressView.hidden = true

            } else {
                loadingProgressView.progress = newValue
                loadingProgressView.hidden = false
            }
        }
    }

    func loadingWithProgress(progress: Double, image: UIImage?) {

        if progress >= loadingProgress {

            if progress <= 1.0 {
                loadingProgress = progress
            }

            if let image = image {

                dispatch_async(dispatch_get_main_queue()) { [weak self] in

                    guard let strongSelf = self else {
                        return
                    }

                    UIView.transitionWithView(strongSelf, duration: imageFadeTransitionDuration, options: .TransitionCrossDissolve, animations: { () -> Void in
                        strongSelf.messageImageView.image = image
                    }, completion: nil)
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

        loadingProgress = 0

        if let (imageWidth, imageHeight) = imageMetaOfMessage(message) {

            let aspectRatio = imageWidth / imageHeight

            let messageImagePreferredWidth = max(messageImagePreferredWidth, ceil(YepConfig.ChatCell.mediaMinHeight * aspectRatio))
            let messageImagePreferredHeight = max(messageImagePreferredHeight, ceil(YepConfig.ChatCell.mediaMinWidth / aspectRatio))

            if aspectRatio >= 1 {
                let width = min(messageImagePreferredWidth, YepConfig.ChatCell.imageMaxWidth)
                
                UIView.performWithoutAnimation { [weak self] in

                    if let strongSelf = self {
                        strongSelf.messageImageView.frame = CGRect(x: CGRectGetMinX(strongSelf.avatarImageView.frame) - YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble - width, y: 0, width: width, height: strongSelf.bounds.height)
                        strongSelf.messageImageMaskImageView.frame = strongSelf.messageImageView.bounds

                        strongSelf.dotImageView.center = CGPoint(x: CGRectGetMinX(strongSelf.messageImageView.frame) - YepConfig.ChatCell.gapBetweenDotImageViewAndBubble, y: CGRectGetMidY(strongSelf.messageImageView.frame))

                        strongSelf.loadingProgressView.center = CGPoint(x: CGRectGetMidX(strongSelf.messageImageView.frame) + YepConfig.ChatCell.playImageViewXOffset, y: CGRectGetMidY(strongSelf.messageImageView.frame))

                        strongSelf.borderImageView.frame = strongSelf.messageImageView.frame
                    }
                }

                var size = CGSize(width: messageImagePreferredWidth, height: ceil(messageImagePreferredWidth / aspectRatio))
                size = size.yep_ensureMinWidthOrHeight(YepConfig.ChatCell.mediaMinHeight)
                
                ImageCache.sharedInstance.imageOfMessage(message, withSize: size, tailDirection: .Right, completion: { [weak self] progress, image in

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
                        strongSelf.messageImageView.frame = CGRect(x: CGRectGetMinX(strongSelf.avatarImageView.frame) - YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble - width, y: 0, width: width, height: strongSelf.bounds.height)
                        strongSelf.messageImageMaskImageView.frame = strongSelf.messageImageView.bounds

                        strongSelf.dotImageView.center = CGPoint(x: CGRectGetMinX(strongSelf.messageImageView.frame) - YepConfig.ChatCell.gapBetweenDotImageViewAndBubble, y: CGRectGetMidY(strongSelf.messageImageView.frame))

                        strongSelf.loadingProgressView.center = CGPoint(x: CGRectGetMidX(strongSelf.messageImageView.frame) + YepConfig.ChatCell.playImageViewXOffset, y: CGRectGetMidY(strongSelf.messageImageView.frame))

                        strongSelf.borderImageView.frame = strongSelf.messageImageView.frame
                    }
                }

                var size = CGSize(width: messageImagePreferredHeight * aspectRatio, height: messageImagePreferredHeight)
                size = size.yep_ensureMinWidthOrHeight(YepConfig.ChatCell.mediaMinHeight)

                ImageCache.sharedInstance.imageOfMessage(message, withSize: size, tailDirection: .Right, completion: { [weak self] progress, image in

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
                    strongSelf.messageImageView.frame = CGRect(x: CGRectGetMinX(strongSelf.avatarImageView.frame) - YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble - width, y: 0, width: width, height: strongSelf.bounds.height)
                    strongSelf.messageImageMaskImageView.frame = strongSelf.messageImageView.bounds

                    strongSelf.dotImageView.center = CGPoint(x: CGRectGetMinX(strongSelf.messageImageView.frame) - YepConfig.ChatCell.gapBetweenDotImageViewAndBubble, y: CGRectGetMidY(strongSelf.messageImageView.frame))

                    strongSelf.loadingProgressView.center = CGPoint(x: CGRectGetMidX(strongSelf.messageImageView.frame) + YepConfig.ChatCell.playImageViewXOffset, y: CGRectGetMidY(strongSelf.messageImageView.frame))

                    strongSelf.borderImageView.frame = strongSelf.messageImageView.frame
                }
            }

            let size = CGSize(width: messageImagePreferredWidth, height: ceil(messageImagePreferredWidth / messageImagePreferredAspectRatio))

            ImageCache.sharedInstance.imageOfMessage(message, withSize: size, tailDirection: .Right, completion: { [weak self] progress, image in

                dispatch_async(dispatch_get_main_queue()) {
                    if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                        self?.loadingWithProgress(progress, image: image)
                    }
                }
            })
        }
    }
}


