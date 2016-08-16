//
//  ChatRightVideoCell.swift
//  Yep
//
//  Created by NIX on 15/4/23.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class ChatRightVideoCell: ChatRightBaseCell {

    lazy var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        imageView.tintColor = UIColor.rightBubbleTintColor()
        return imageView
    }()

    lazy var borderImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.yep_rightTailImageBubbleBorder)
        return imageView
    }()

    lazy var playImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.yep_iconPlayvideo)
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

        UIView.setAnimationsEnabled(false); do {
            makeUI()
        }
        UIView.setAnimationsEnabled(true)

        thumbnailImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(ChatRightVideoCell.tapMediaView))
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

                self.thumbnailImageView.image = image

                UIView.animateWithDuration(YepConfig.ChatCell.imageAppearDuration, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
                    self?.thumbnailImageView.alpha = 1.0
                }, completion: nil)
            }
        }
    }
    
    func configureWithMessage(message: Message, mediaTapAction: MediaTapAction?) {

        self.message = message
        self.user = message.fromFriend

        self.mediaTapAction = mediaTapAction

        UIView.setAnimationsEnabled(false); do {
            makeUI()
        }
        UIView.setAnimationsEnabled(true)

        if let sender = message.fromFriend {
            let userAvatar = UserAvatar(userID: sender.userID, avatarURLString: sender.avatarURLString, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
        }

        SafeDispatch.async { [weak self] in
            self?.thumbnailImageView.alpha = 0.0
        }

        let videoSize = message.fixedVideoSize

        thumbnailImageView.yep_setImageOfMessage(message, withSize: videoSize, tailDirection: .Right, completion: { loadingProgress, image in
            SafeDispatch.async { [weak self] in
                self?.loadingWithProgress(loadingProgress, image: image)
            }
        })

        UIView.setAnimationsEnabled(false); do {
            let width = videoSize.width
            thumbnailImageView.frame = CGRect(x: CGRectGetMinX(avatarImageView.frame) - YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble - width, y: 0, width: width, height: bounds.height)
            playImageView.center = CGPoint(x: CGRectGetMidX(thumbnailImageView.frame) - YepConfig.ChatCell.playImageViewXOffset, y: CGRectGetMidY(thumbnailImageView.frame))
            dotImageView.center = CGPoint(x: CGRectGetMinX(thumbnailImageView.frame) - YepConfig.ChatCell.gapBetweenDotImageViewAndBubble, y: CGRectGetMidY(thumbnailImageView.frame))

            borderImageView.frame = thumbnailImageView.frame
        }
        UIView.setAnimationsEnabled(true)
    }
}

