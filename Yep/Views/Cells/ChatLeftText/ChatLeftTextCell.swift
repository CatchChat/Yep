//
//  ChatLeftTextCell.swift
//  Yep
//
//  Created by NIX on 15/3/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

class ChatLeftTextCell: ChatBaseCell {

    var tapUsernameAction: ((username: String) -> Void)?
    var tapFeedAction: ((feed: DiscoveredFeed?) -> Void)?

    lazy var bubbleTailImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "bubble_left_tail"))
        imageView.tintColor = UIColor.leftBubbleTintColor()
        return imageView
    }()

    lazy var bubbleBodyShapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.backgroundColor = UIColor.leftBubbleTintColor().CGColor
        layer.fillColor = UIColor.leftBubbleTintColor().CGColor
        return layer
    }()

    lazy var textContentTextView: ChatTextView = {
        let view = ChatTextView()

        view.textContainer.lineFragmentPadding = 0
        view.font = UIFont.chatTextFont()
        view.backgroundColor = UIColor.clearColor()
        view.textColor = UIColor.blackColor()
        view.tintColor = UIColor.blackColor()
        view.linkTextAttributes = [
            NSForegroundColorAttributeName: UIColor.yepTintColor(),
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

        UIView.performWithoutAnimation { [weak self] in
            self?.makeUI()
        }

        if let bubblePosition = layer.sublayers {
            contentView.layer.insertSublayer(bubbleBodyShapeLayer, atIndex: UInt32(bubblePosition.count))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureWithMessage(message: Message, layoutCache: ChatTextCellLayoutCache) {

        self.user = message.fromFriend

        textContentTextView.text = message.textContent

        //textContentTextView.attributedText = NSAttributedString(string: message.textContent, attributes: textAttributes)
        
        //textContentTextView.textAlignment = textContentLabelWidth < YepConfig.minMessageTextLabelWidth ? .Center : .Left

        func adjustedTextContentTextViewWidth() -> CGFloat {

            // 用 sizeThatFits 来对比，不需要 magicWidth 的时候就可以避免了
            var textContentTextViewWidth = layoutCache.textContentTextViewWidth
            let size = textContentTextView.sizeThatFits(CGSize(width: textContentTextViewWidth, height: CGFloat.max))
            
            // lineHeight 19.088, size.height 35.5 (1 line) 54.5 (2 lines)
            textContentTextView.textAlignment = ((size.height - textContentTextView.font!.lineHeight) < 20) ? .Center : .Left

            if ceil(size.width) != textContentTextViewWidth {
                //println("left ceil(size.width): \(ceil(size.width)), textContentLabelWidth: \(textContentLabelWidth)")
                //println(">>>\(message.textContent)<<<")

                //textContentLabelWidth += YepConfig.ChatCell.magicWidth
                if abs(ceil(size.width) - textContentTextViewWidth) >= YepConfig.ChatCell.magicWidth {
                    textContentTextViewWidth += YepConfig.ChatCell.magicWidth
                }
            }
            
            textContentTextViewWidth = max(textContentTextViewWidth, YepConfig.ChatCell.minTextWidth)

            return textContentTextViewWidth
        }

        UIView.performWithoutAnimation { [weak self] in

            if let strongSelf = self {
                
                strongSelf.makeUI()
                
                let topOffset: CGFloat
                if strongSelf.inGroup {
                    topOffset = YepConfig.ChatCell.marginTopForGroup
                } else {
                    topOffset = 0
                }

                let textContentTextViewFrame: CGRect
                if let _textContentTextViewFrame = layoutCache.textContentTextViewFrame {
                    textContentTextViewFrame = _textContentTextViewFrame

                } else {
                    let textContentTextViewWidth = adjustedTextContentTextViewWidth()

                    textContentTextViewFrame = CGRect(x: CGRectGetMaxX(strongSelf.avatarImageView.frame) + YepConfig.chatCellGapBetweenTextContentLabelAndAvatar(), y: 3 + topOffset, width: textContentTextViewWidth, height: strongSelf.bounds.height - topOffset - 3 * 2 - strongSelf.bottomGap)

                    layoutCache.update(textContentTextViewFrame: textContentTextViewFrame)
                }

                strongSelf.textContentTextView.frame = textContentTextViewFrame

                let bubbleBodyFrame = CGRectInset(textContentTextViewFrame, -12, -3)
                
                strongSelf.bubbleBodyShapeLayer.path = UIBezierPath(roundedRect: bubbleBodyFrame, byRoundingCorners: UIRectCorner.AllCorners, cornerRadii: CGSize(width: YepConfig.ChatCell.bubbleCornerRadius, height: YepConfig.ChatCell.bubbleCornerRadius)).CGPath
                
                if strongSelf.inGroup {
                    strongSelf.nameLabel.text = strongSelf.user?.compositedName

                    let height = YepConfig.ChatCell.nameLabelHeightForGroup
                    let x = textContentTextViewFrame.origin.x
                    let y = textContentTextViewFrame.origin.y - height - 3
                    let width = strongSelf.contentView.bounds.width - x - 10
                    strongSelf.nameLabel.frame = CGRect(x: x, y: y, width: width, height: height)
                }
                
                strongSelf.bubbleTailImageView.center = CGPoint(x: CGRectGetMinX(bubbleBodyFrame), y: CGRectGetMidY(strongSelf.avatarImageView.frame))
            }
        }

        if let sender = message.fromFriend {
            let userAvatar = UserAvatar(userID: sender.userID, avatarURLString: sender.avatarURLString, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
        }
    }
}

