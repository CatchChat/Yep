//
//  ChatLeftVideoCell.swift
//  Yep
//
//  Created by NIX on 15/4/23.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatLeftVideoCell: ChatBaseCell {

    @IBOutlet weak var thumbnailImageView: UIImageView!
//    @IBOutlet weak var thumbnailImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var playImageView: UIImageView!
//    @IBOutlet weak var playImageViewCenterXConstraint: NSLayoutConstraint!

    @IBOutlet weak var loadingProgressView: MessageLoadingProgressView!
    
    typealias MediaTapAction = () -> Void
    var mediaTapAction: MediaTapAction?

    func makeUI() {

        let fullWidth = UIScreen.mainScreen().bounds.width

        let halfAvatarSize = YepConfig.chatCellAvatarSize() / 2

        avatarImageView.center = CGPoint(x: YepConfig.chatCellGapBetweenWallAndAvatar() + halfAvatarSize, y: halfAvatarSize)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = UIColor.yellowColor()

        makeUI()

//        playImageViewCenterXConstraint.constant = YepConfig.ChatCell.centerXOffset

        thumbnailImageView.tintColor = UIColor.leftBubbleTintColor()

        thumbnailImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tapMediaView")
        thumbnailImageView.addGestureRecognizer(tap)
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

        self.user = message.fromFriend

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

        loadingProgress = 0

        thumbnailImageView.alpha = 0.0

        if let (videoWidth, videoHeight) = videoMetaOfMessage(message) {

            let aspectRatio = videoWidth / videoHeight

            let messageImagePreferredWidth = max(messageImagePreferredWidth, ceil(YepConfig.ChatCell.mediaMinHeight * aspectRatio))
            let messageImagePreferredHeight = max(messageImagePreferredHeight, ceil(YepConfig.ChatCell.mediaMinWidth / aspectRatio))

            if aspectRatio >= 1 {
//                thumbnailImageViewWidthConstraint.constant = messageImagePreferredWidth

                let width = messageImagePreferredWidth

                thumbnailImageView.frame = CGRect(x: CGRectGetMaxX(avatarImageView.frame) + 5, y: 0, width: width, height: bounds.height)

                playImageView.center = CGPoint(x: CGRectGetMidX(thumbnailImageView.frame) + 3, y: CGRectGetMidY(thumbnailImageView.frame))

                println("playImageView.frame: \(playImageView.frame)")

                loadingProgressView.center = playImageView.center


                ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredWidth, height: ceil(messageImagePreferredWidth / aspectRatio)), tailDirection: .Left, completion: { [weak self] progress, image in

                    dispatch_async(dispatch_get_main_queue()) {
                        if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                            self?.loadingWithProgress(progress, image: image)
                        }
                    }
                })

            } else {
//                thumbnailImageViewWidthConstraint.constant = messageImagePreferredHeight * aspectRatio

                let width = messageImagePreferredHeight * aspectRatio

                thumbnailImageView.frame = CGRect(x: CGRectGetMaxX(avatarImageView.frame) + 5, y: 0, width: width, height: bounds.height)

                playImageView.center = CGPoint(x: CGRectGetMidX(thumbnailImageView.frame) + 3, y: CGRectGetMidY(thumbnailImageView.frame))

                println("playImageView.frame: \(playImageView.frame)")

                loadingProgressView.center = playImageView.center


                ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredHeight * aspectRatio, height: messageImagePreferredHeight), tailDirection: .Left, completion: { [weak self] progress, image in

                    dispatch_async(dispatch_get_main_queue()) {
                        if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                            self?.loadingWithProgress(progress, image: image)
                        }
                    }
                })
            }

        } else {
//            thumbnailImageViewWidthConstraint.constant = messageImagePreferredWidth

            let width = messageImagePreferredWidth

            thumbnailImageView.frame = CGRect(x: CGRectGetMaxX(avatarImageView.frame) + 5, y: 0, width: width, height: bounds.height)

            playImageView.center = CGPoint(x: CGRectGetMidX(thumbnailImageView.frame) + 3, y: CGRectGetMidY(thumbnailImageView.frame))

            println("playImageView.frame: \(playImageView.frame)")

            loadingProgressView.center = playImageView.center


            ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredWidth, height: ceil(messageImagePreferredWidth / messageImagePreferredAspectRatio)), tailDirection: .Left, completion: { [weak self] progress, image in

                dispatch_async(dispatch_get_main_queue()) {
                    if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                        self?.loadingWithProgress(progress, image: image)
                    }
                }
            })
        }
    }

}
