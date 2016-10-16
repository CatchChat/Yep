//
//  ChatLeftVideoCell.swift
//  Yep
//
//  Created by NIX on 15/4/23.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class ChatLeftVideoCell: ChatBaseCell {

    lazy var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = UIColor.leftBubbleTintColor()
        return imageView
    }()

    lazy var borderImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.yep_leftTailImageBubbleBorder)
        return imageView
    }()

    lazy var playImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.yep_iconPlayvideo)
        return imageView
    }()

    lazy var loadingProgressView: MessageLoadingProgressView = {
        let view = MessageLoadingProgressView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        view.isHidden = true
        view.backgroundColor = UIColor.clear
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

        UIView.setAnimationsEnabled(false); do {
            makeUI()
        }
        UIView.setAnimationsEnabled(true)

        thumbnailImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(ChatLeftVideoCell.tapMediaView))
        thumbnailImageView.addGestureRecognizer(tap)

        prepareForMenuAction = { otherGesturesEnabled in
            tap.isEnabled = otherGesturesEnabled
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
                loadingProgressView.isHidden = true

            } else {
                loadingProgressView.progress = newValue
                loadingProgressView.isHidden = false
            }
        }
    }

    func loadingWithProgress(_ progress: Double, image: UIImage?) {

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
                        self.thumbnailImageView.image = image
                        self.thumbnailImageView.alpha = 1.0
                    }

                    return
                }
            }

            if let image = image {

                self.thumbnailImageView.image = image

                UIView.animate(withDuration: YepConfig.ChatCell.imageAppearDuration, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
                    self?.thumbnailImageView.alpha = 1.0
                }, completion: nil )
            }
        }
    }

    func configureWithMessage(_ message: Message, mediaTapAction: MediaTapAction?) {

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

        SafeDispatch.async { [weak self] in
            if let strongSelf = self {
                strongSelf.thumbnailImageView.alpha = 0.0
            }
        }

        let videoSize = message.fixedVideoSize

        thumbnailImageView.yep_setImageOfMessage(message, withSize: videoSize, tailDirection: .left, completion: { loadingProgress, image in
            SafeDispatch.async { [weak self] in
                self?.loadingWithProgress(loadingProgress, image: image)
            }
        })

        UIView.setAnimationsEnabled(false); do {
            thumbnailImageView.frame = CGRect(x: (avatarImageView.frame).maxX + YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble, y: topOffset, width: videoSize.width, height: bounds.height - topOffset)
            playImageView.center = CGPoint(x: thumbnailImageView.frame.midX + YepConfig.ChatCell.playImageViewXOffset, y: thumbnailImageView.frame.midY)
            loadingProgressView.center = playImageView.center

            borderImageView.frame = thumbnailImageView.frame
        }
        UIView.setAnimationsEnabled(true)

        configureNameLabel()
    }

    fileprivate func configureNameLabel() {

        if inGroup {
            nameLabel.text = user?.compositedName

            UIView.setAnimationsEnabled(false); do {
                let height = YepConfig.ChatCell.nameLabelHeightForGroup
                let x = avatarImageView.frame.maxX + YepConfig.chatCellGapBetweenTextContentLabelAndAvatar()
                let y = thumbnailImageView.frame.origin.y - height
                let width = contentView.bounds.width - x - 10
                nameLabel.frame = CGRect(x: x, y: y, width: width, height: height)
            }
            UIView.setAnimationsEnabled(true)
        }
    }
}

