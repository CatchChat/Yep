//
//  ChatLeftTextCell.swift
//  Yep
//
//  Created by NIX on 15/3/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

class ChatLeftTextCell: ChatBaseCell, Copyable {

    var tapUsernameAction: ((_ username: String) -> Void)?
    var tapFeedAction: ((_ feed: DiscoveredFeed?) -> Void)?

    lazy var bubbleTailImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.yep_bubbleLeftTail)
        imageView.tintColor = UIColor.leftBubbleTintColor()
        return imageView
    }()

    lazy var bubbleBodyShapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.backgroundColor = UIColor.leftBubbleTintColor().cgColor
        layer.fillColor = UIColor.leftBubbleTintColor().cgColor
        return layer
    }()

    lazy var textContentTextView: ChatTextView = {
        let view = ChatTextView()

        view.textContainer.lineFragmentPadding = 0
        view.font = UIFont.chatTextFont()
        view.backgroundColor = UIColor.clear
        view.textColor = UIColor.black
        view.tintColor = UIColor.black
        view.linkTextAttributes = [
            NSForegroundColorAttributeName: UIColor.yepTintColor(),
            NSUnderlineStyleAttributeName: NSNumber(value: NSUnderlineStyle.styleSingle.rawValue as Int),
        ]

        view.tapMentionAction = { [weak self] username in
            self?.tapUsernameAction?(username)
        }

        view.tapFeedAction = { [weak self] feed in
            self?.tapFeedAction?(feed: feed)
        }

        return view
    }()

    var bottomGap: CGFloat = 0

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

        contentView.addSubview(bubbleTailImageView)
        contentView.addSubview(textContentTextView)

        UIView.setAnimationsEnabled(false); do {
            makeUI()
        }
        UIView.setAnimationsEnabled(true)

        if let bubblePosition = layer.sublayers {
            contentView.layer.insertSublayer(bubbleBodyShapeLayer, at: UInt32(bubblePosition.count))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureWithMessage(_ message: Message, layoutCache: ChatTextCellLayoutCache) {

        self.user = message.fromFriend

        textContentTextView.setAttributedTextWithMessage(message)

        func adjustedTextContentTextViewWidth() -> CGFloat {

            // 用 sizeThatFits 来对比，不需要 magicWidth 的时候就可以避免了
            var textContentTextViewWidth = layoutCache.textContentTextViewWidth
            let size = textContentTextView.sizeThatFits(CGSize(width: textContentTextViewWidth, height: CGFloat.greatestFiniteMagnitude))
            
            // lineHeight 19.088, size.height 35.5 (1 line) 54.5 (2 lines)
            textContentTextView.textAlignment = ((size.height - textContentTextView.font!.lineHeight) < 20) ? .center : .left

            if ceil(size.width) != textContentTextViewWidth {
                if abs(ceil(size.width) - textContentTextViewWidth) >= YepConfig.ChatCell.magicWidth {
                    textContentTextViewWidth += YepConfig.ChatCell.magicWidth
                }
            }
            
            textContentTextViewWidth = max(textContentTextViewWidth, YepConfig.ChatCell.minTextWidth)

            return textContentTextViewWidth
        }

        UIView.setAnimationsEnabled(false); do {

            makeUI()
            
            let topOffset: CGFloat
            if inGroup {
                topOffset = YepConfig.ChatCell.marginTopForGroup
            } else {
                topOffset = 0
            }

            let textContentTextViewFrame: CGRect
            if let _textContentTextViewFrame = layoutCache.textContentTextViewFrame {
                textContentTextViewFrame = _textContentTextViewFrame

            } else {
                let textContentTextViewWidth = adjustedTextContentTextViewWidth()

                textContentTextViewFrame = CGRect(x: avatarImageView.frame.maxX + YepConfig.chatCellGapBetweenTextContentLabelAndAvatar(), y: 3 + topOffset, width: textContentTextViewWidth, height: bounds.height - topOffset - 3 * 2 - bottomGap)

                layoutCache.update(textContentTextViewFrame)
            }

            textContentTextView.frame = textContentTextViewFrame

            let bubbleBodyFrame = textContentTextView.frame.insetBy(dx: -12, dy: -3)

            bubbleBodyShapeLayer.path = UIBezierPath(roundedRect: bubbleBodyFrame, byRoundingCorners: UIRectCorner.allCorners, cornerRadii: CGSize(width: YepConfig.ChatCell.bubbleCornerRadius, height: YepConfig.ChatCell.bubbleCornerRadius)).cgPath

            bubbleTailImageView.center = CGPoint(x: bubbleBodyFrame.minX, y: avatarImageView.frame.midY)

            if inGroup {
                nameLabel.text = user?.compositedName

                let height = YepConfig.ChatCell.nameLabelHeightForGroup
                let x = textContentTextViewFrame.origin.x
                let y = textContentTextViewFrame.origin.y - height - 3
                let width = contentView.bounds.width - x - 10
                nameLabel.frame = CGRect(x: x, y: y, width: width, height: height)
            }
        }
        UIView.setAnimationsEnabled(true)

        if let sender = message.fromFriend {
            let userAvatar = UserAvatar(userID: sender.userID, avatarURLString: sender.avatarURLString, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
        }
    }

    // MARK: Copyable

    var text: String? {
        return textContentTextView.text
    }
}

