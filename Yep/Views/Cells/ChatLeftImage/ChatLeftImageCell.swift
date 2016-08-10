//
//  ChatLeftImageCell.swift
//  Yep
//
//  Created by NIX on 15/4/1.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class ChatLeftImageCell: ChatBaseCell {

    lazy var messageImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        imageView.tintColor = UIColor.leftBubbleTintColor()
        imageView.maskView = self.messageImageMaskImageView
        imageView.clipsToBounds = true
        return imageView
    }()

    lazy var borderImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.yep_leftTailImageBubbleBorder)
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
        let imageView = UIImageView(image: UIImage.yep_leftTailImageBubble)
        return imageView
    }()

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

        contentView.addSubview(messageImageView)
        contentView.addSubview(borderImageView)
        contentView.addSubview(loadingProgressView)

        UIView.setAnimationsEnabled(false); do {
            makeUI()
        }
        UIView.setAnimationsEnabled(true)

        messageImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(ChatLeftImageCell.tapMediaView))
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

            if loadingProgress == 1.0 {
                if progress < 1.0 {
                    return
                }
            }
            
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

        self.user = message.fromFriend
        
        self.mediaTapAction = mediaTapAction
        
        var topOffset: CGFloat = 0
        
        if inGroup {
            topOffset = YepConfig.ChatCell.marginTopForGroup
        } else {
            topOffset = 0
        }

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

        messageImageView.yep_setImageOfMessage(message, withSize: imageSize, tailDirection: .Left, completion: { loadingProgress, image in
            SafeDispatch.async { [weak self] in
                self?.loadingWithProgress(loadingProgress, image: image)
            }
        })

        UIView.setAnimationsEnabled(false); do {
            let width = min(imageSize.width, YepConfig.ChatCell.imageMaxWidth)

            messageImageView.frame = CGRect(x: CGRectGetMaxX(avatarImageView.frame) + YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble, y: topOffset, width: width, height: bounds.height - topOffset)
            messageImageMaskImageView.frame = messageImageView.bounds

            loadingProgressView.center = CGPoint(x: CGRectGetMidX(messageImageView.frame) + YepConfig.ChatCell.playImageViewXOffset, y: CGRectGetMidY(messageImageView.frame))

            borderImageView.frame = messageImageView.frame
        }
        UIView.setAnimationsEnabled(true)

        configureNameLabel()
    }
    
    private func configureNameLabel() {
        
        if inGroup {
            nameLabel.text = user?.compositedName

            UIView.setAnimationsEnabled(false); do {
                let height = YepConfig.ChatCell.nameLabelHeightForGroup
                let x = CGRectGetMaxX(avatarImageView.frame) + YepConfig.chatCellGapBetweenTextContentLabelAndAvatar()
                let y = messageImageView.frame.origin.y - height
                let width = contentView.bounds.width - x - 10
                nameLabel.frame = CGRect(x: x, y: y, width: width, height: height)
            }
            UIView.setAnimationsEnabled(true)
        }
    }
}

