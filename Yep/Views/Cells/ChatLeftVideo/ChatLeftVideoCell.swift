//
//  ChatLeftVideoCell.swift
//  Yep
//
//  Created by NIX on 15/4/23.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatLeftVideoCell: ChatBaseCell {

    lazy var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        imageView.tintColor = UIColor.leftBubbleTintColor()
        return imageView
    }()

    lazy var borderImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "left_tail_image_bubble_border"))
        return imageView
    }()

    lazy var playImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "icon_playvideo"))
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

    func makeUI() {

        let halfAvatarSize = YepConfig.chatCellAvatarSize() / 2
        
        var topOffset: CGFloat = 0
        
        if inGroup {
            topOffset = YepConfig.ChatCell.marginTopForGroup
        } else {
            topOffset = 0
        }
        
        avatarImageView.center = CGPoint(x: YepConfig.chatCellGapBetweenWallAndAvatar() + halfAvatarSize, y: halfAvatarSize + topOffset)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(borderImageView)
        contentView.addSubview(playImageView)
        contentView.addSubview(loadingProgressView)

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
            
            if loadingProgress == 1.0 {
                if progress < 1.0 {
                    return
                }
            }

            if progress <= 1.0 {
                loadingProgress = progress
                
                if progress == 1 {
                    
                    dispatch_async(dispatch_get_main_queue()) { [weak self] in
                        
                        if let image = image {
                            self?.thumbnailImageView.image = image
                            
                            self?.thumbnailImageView.alpha = 1.0
                        }
                    }
                    
                    return
                }
            }

            if let image = image {

                dispatch_async(dispatch_get_main_queue()) { [weak self] in

                    self?.thumbnailImageView.image = image

                    UIView.animateWithDuration(YepConfig.ChatCell.imageAppearDuration, delay: 0.0, options: .CurveEaseInOut, animations: { () -> Void in
                        self?.thumbnailImageView.alpha = 1.0
                    }, completion: nil )
                }
            }
        }
    }

    func configureWithMessage(message: Message, messageImagePreferredWidth: CGFloat, messageImagePreferredHeight: CGFloat, messageImagePreferredAspectRatio: CGFloat, mediaTapAction: MediaTapAction?, collectionView: UICollectionView, indexPath: NSIndexPath) {

        self.user = message.fromFriend

        self.mediaTapAction = mediaTapAction
        
        var topOffset: CGFloat = 0
        
        if inGroup {
            topOffset = YepConfig.ChatCell.marginTopForGroup
        } else {
            topOffset = 0
        }

        UIView.performWithoutAnimation { [weak self] in
            self?.makeUI()
        }

        if let sender = message.fromFriend {
            let userAvatar = UserAvatar(userID: sender.userID, avatarURLString: sender.avatarURLString, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
        }

        loadingProgress = 0

        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            if let strongSelf = self {
                strongSelf.thumbnailImageView.alpha = 0.0
            }
        }

        if let (videoWidth, videoHeight) = videoMetaOfMessage(message) {

            let aspectRatio = videoWidth / videoHeight

            let messageImagePreferredWidth = max(messageImagePreferredWidth, ceil(YepConfig.ChatCell.mediaMinHeight * aspectRatio))
            let messageImagePreferredHeight = max(messageImagePreferredHeight, ceil(YepConfig.ChatCell.mediaMinWidth / aspectRatio))

            if aspectRatio >= 1 {

                let width = messageImagePreferredWidth
                
                UIView.performWithoutAnimation { [weak self] in

                    if let strongSelf = self {
                        strongSelf.thumbnailImageView.frame = CGRect(x: CGRectGetMaxX(strongSelf.avatarImageView.frame) + YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble, y: topOffset, width: width, height: strongSelf.bounds.height - topOffset)
                        strongSelf.playImageView.center = CGPoint(x: CGRectGetMidX(strongSelf.thumbnailImageView.frame) + YepConfig.ChatCell.playImageViewXOffset, y: CGRectGetMidY(strongSelf.thumbnailImageView.frame))
                        strongSelf.loadingProgressView.center = strongSelf.playImageView.center

                        strongSelf.borderImageView.frame = strongSelf.thumbnailImageView.frame
                    }
                }

                ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredWidth, height: ceil(messageImagePreferredWidth / aspectRatio)), tailDirection: .Left, completion: { [weak self] progress, image in

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
                        strongSelf.thumbnailImageView.frame = CGRect(x: CGRectGetMaxX(strongSelf.avatarImageView.frame) + YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble, y: topOffset, width: width, height: strongSelf.bounds.height - topOffset)
                        strongSelf.playImageView.center = CGPoint(x: CGRectGetMidX(strongSelf.thumbnailImageView.frame) + YepConfig.ChatCell.playImageViewXOffset, y: CGRectGetMidY(strongSelf.thumbnailImageView.frame))
                        strongSelf.loadingProgressView.center = strongSelf.playImageView.center

                        strongSelf.borderImageView.frame = strongSelf.thumbnailImageView.frame
                    }
                }

                ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredHeight * aspectRatio, height: messageImagePreferredHeight), tailDirection: .Left, completion: { [weak self] progress, image in

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
                    strongSelf.thumbnailImageView.frame = CGRect(x: CGRectGetMaxX(strongSelf.avatarImageView.frame) + YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble, y: topOffset, width: width, height: strongSelf.bounds.height - topOffset)
                    strongSelf.playImageView.center = CGPoint(x: CGRectGetMidX(strongSelf.thumbnailImageView.frame) + YepConfig.ChatCell.playImageViewXOffset, y: CGRectGetMidY(strongSelf.thumbnailImageView.frame))
                    strongSelf.loadingProgressView.center = strongSelf.playImageView.center

                    strongSelf.borderImageView.frame = strongSelf.thumbnailImageView.frame
                }
            }

            ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredWidth, height: ceil(messageImagePreferredWidth / messageImagePreferredAspectRatio)), tailDirection: .Left, completion: { [weak self] progress, image in

                dispatch_async(dispatch_get_main_queue()) {
                    if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                        self?.loadingWithProgress(progress, image: image)
                    }
                }
            })
        }
        
        configureNameLabel()
    }

    private func configureNameLabel() {

        if inGroup {
            nameLabel.text = user?.chatCellCompositedName

            let height = YepConfig.ChatCell.nameLabelHeightForGroup
            let x = CGRectGetMaxX(avatarImageView.frame) + YepConfig.chatCellGapBetweenTextContentLabelAndAvatar()
            let y = thumbnailImageView.frame.origin.y - height
            let width = contentView.bounds.width - x - 10
            nameLabel.frame = CGRect(x: x, y: y, width: width, height: height)
        }
    }
}

