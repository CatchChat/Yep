//
//  ChatRightTextCell.swift
//  Yep
//
//  Created by NIX on 15/3/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

class ChatRightTextCell: ChatRightBaseCell {

    var tapUsernameAction: ((username: String) -> Void)?
    var tapFeedAction: ((feed: DiscoveredFeed?) -> Void)?

    lazy var bubbleTailImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.yep_bubbleRightTail)
        imageView.tintColor = UIColor.rightBubbleTintColor()
        return imageView
    }()

    lazy var bubbleBodyShapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.backgroundColor = UIColor.rightBubbleTintColor().CGColor
        layer.fillColor = UIColor.rightBubbleTintColor().CGColor
        return layer
    }()

    lazy var textContainerView: UIView = {
        let view = UIView()
        return view
    }()

    lazy var textContentTextView: ChatTextView = {
        let view = ChatTextView()

        view.textContainer.lineFragmentPadding = 0
        view.font = UIFont.chatTextFont()
        view.backgroundColor = UIColor.clearColor()
        view.textColor = UIColor.whiteColor()
        view.tintColor = UIColor.whiteColor()
        view.linkTextAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSUnderlineStyleAttributeName: NSNumber(integer: NSUnderlineStyle.StyleSingle.rawValue),
        ]

        view.tapMentionAction = { [weak self] username in
            self?.tapUsernameAction?(username: username)
        }

        view.tapFeedAction = { [weak self] feed in
            self?.tapFeedAction?(feed: feed)
        }

        return view
    }()

    var bottomGap: CGFloat = 0

    typealias MediaTapAction = () -> Void
    var mediaTapAction: MediaTapAction?

    func makeUI() {

        let fullWidth = UIScreen.mainScreen().bounds.width

        let halfAvatarSize = YepConfig.chatCellAvatarSize() / 2

        avatarImageView.center = CGPoint(x: fullWidth - halfAvatarSize - YepConfig.chatCellGapBetweenWallAndAvatar(), y: halfAvatarSize)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(bubbleTailImageView)
        contentView.addSubview(textContainerView)
        textContainerView.addSubview(textContentTextView)

        if let bubblePosition = layer.sublayers {
            contentView.layer.insertSublayer(bubbleBodyShapeLayer, atIndex: UInt32(bubblePosition.count))
        }

        UIView.setAnimationsEnabled(false); do {
            makeUI()
        }
        UIView.setAnimationsEnabled(true)

        textContainerView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(ChatRightTextCell.tapMediaView))
        textContainerView.addGestureRecognizer(tap)

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

    func configureWithMessage(message: Message, layoutCache: ChatTextCellLayoutCache, mediaTapAction: MediaTapAction?) {

        self.message = message
        self.user = message.fromFriend

        self.mediaTapAction = mediaTapAction

        textContentTextView.setAttributedTextWithMessage(message)

        func adjustedTextContentTextViewWidth() -> CGFloat {
            
            // 用 sizeThatFits 来对比，不需要 magicWidth 的时候就可以避免了
            var textContentTextViewWidth = layoutCache.textContentTextViewWidth
            let size = textContentTextView.sizeThatFits(CGSize(width: textContentTextViewWidth, height: CGFloat.max))

            // lineHeight 19.088, size.height 35.5 (1 line) 54.5 (2 lines)
            textContentTextView.textAlignment = ((size.height - textContentTextView.font!.lineHeight) < 20) ? .Center : .Left

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

            let textContentTextViewFrame: CGRect
            if let _textContentTextViewFrame = layoutCache.textContentTextViewFrame {
                textContentTextViewFrame = _textContentTextViewFrame

            } else {
                let textContentTextViewWidth = adjustedTextContentTextViewWidth()

                textContentTextViewFrame = CGRect(x: CGRectGetMinX(avatarImageView.frame) - YepConfig.chatCellGapBetweenTextContentLabelAndAvatar() - textContentTextViewWidth, y: 3, width: textContentTextViewWidth, height: bounds.height - 3 * 2 - bottomGap)

                layoutCache.update(textContentTextViewFrame: textContentTextViewFrame)
            }
            
            textContainerView.frame = textContentTextViewFrame
            textContentTextView.frame = textContainerView.bounds

            let bubbleBodyFrame = CGRectInset(textContainerView.frame, -12, -3)

            bubbleBodyShapeLayer.path = UIBezierPath(roundedRect: bubbleBodyFrame, byRoundingCorners: UIRectCorner.AllCorners, cornerRadii: CGSize(width: YepConfig.ChatCell.bubbleCornerRadius, height: YepConfig.ChatCell.bubbleCornerRadius)).CGPath

            bubbleTailImageView.center = CGPoint(x: CGRectGetMaxX(bubbleBodyFrame), y: CGRectGetMidY(avatarImageView.frame))

            dotImageView.center = CGPoint(x: CGRectGetMinX(bubbleBodyFrame) - YepConfig.ChatCell.gapBetweenDotImageViewAndBubble, y: CGRectGetMidY(textContainerView.frame))
        }
        UIView.setAnimationsEnabled(true)

        if let sender = message.fromFriend {
            let userAvatar = UserAvatar(userID: sender.userID, avatarURLString: sender.avatarURLString, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
        }
    }
}

