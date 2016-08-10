//
//  ChatRightImageCell.swift
//  Yep
//
//  Created by NIX on 15/3/31.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class ChatRightImageCell: ChatRightBaseCell {

    lazy var messageImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        imageView.tintColor = UIColor.rightBubbleTintColor()
        imageView.maskView = self.messageImageMaskImageView
        imageView.clipsToBounds = true
        return imageView
    }()

    lazy var borderImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.yep_rightTailImageBubbleBorder)
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
        let imageView = UIImageView(image: UIImage.yep_rightTailImageBubble)
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

        UIView.setAnimationsEnabled(false); do {
            makeUI()
        }
        UIView.setAnimationsEnabled(true)

        messageImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(ChatRightImageCell.tapMediaView))
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

                if progress == 1 {
                    if let image = image {
                        self.messageImageView.image = image
                    }
                    return
                }
            }

            if let image = image {
                UIView.transitionWithView(self, duration: imageFadeTransitionDuration, options: .TransitionCrossDissolve, animations: { [weak self] in
                    self?.messageImageView.image = image
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

        loadingProgress = 0

        let imageSize = message.fixedImageSize

        messageImageView.yep_setImageOfMessage(message, withSize: imageSize, tailDirection: .Right, completion: { loadingProgress, image in
            SafeDispatch.async { [weak self] in
                self?.loadingWithProgress(loadingProgress, image: image)
            }
        })

        UIView.setAnimationsEnabled(false); do {
            let width = min(imageSize.width, YepConfig.ChatCell.imageMaxWidth)

            messageImageView.frame = CGRect(x: CGRectGetMinX(avatarImageView.frame) - YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble - width, y: 0, width: width, height: bounds.height)
            messageImageMaskImageView.frame = messageImageView.bounds

            dotImageView.center = CGPoint(x: CGRectGetMinX(messageImageView.frame) - YepConfig.ChatCell.gapBetweenDotImageViewAndBubble, y: CGRectGetMidY(messageImageView.frame))

            loadingProgressView.center = CGPoint(x: CGRectGetMidX(messageImageView.frame) + YepConfig.ChatCell.playImageViewXOffset, y: CGRectGetMidY(messageImageView.frame))

            borderImageView.frame = messageImageView.frame
        }
        UIView.setAnimationsEnabled(true)
    }
}

