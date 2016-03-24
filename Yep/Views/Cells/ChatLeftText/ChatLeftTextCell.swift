//
//  ChatLeftTextCell.swift
//  Yep
//
//  Created by NIX on 15/3/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatLeftTextCell: ChatBaseCell {

    var tapUsernameAction: ((username: String) -> Void)?

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

    func configureWithMessage(message: Message, textContentLabelWidth: CGFloat, collectionView: UICollectionView, indexPath: NSIndexPath) {

        self.user = message.fromFriend

        textContentTextView.text = message.textContent

        //textContentTextView.attributedText = NSAttributedString(string: message.textContent, attributes: textAttributes)
        
        //textContentTextView.textAlignment = textContentLabelWidth < YepConfig.minMessageTextLabelWidth ? .Center : .Left
        
        // 用 sizeThatFits 来对比，不需要 magicWidth 的时候就可以避免了
        var textContentLabelWidth = textContentLabelWidth
        let size = textContentTextView.sizeThatFits(CGSize(width: textContentLabelWidth, height: CGFloat.max))
        
        // lineHeight 19.088, size.height 35.5 (1 line) 54.5 (2 lines)
        textContentTextView.textAlignment = ((size.height - textContentTextView.font!.lineHeight) < 20) ? .Center : .Left

        if ceil(size.width) != textContentLabelWidth {
            //println("left ceil(size.width): \(ceil(size.width)), textContentLabelWidth: \(textContentLabelWidth)")
            //println(">>>\(message.textContent)<<<")

            //textContentLabelWidth += YepConfig.ChatCell.magicWidth
            if abs(ceil(size.width) - textContentLabelWidth) >= YepConfig.ChatCell.magicWidth {
                textContentLabelWidth += YepConfig.ChatCell.magicWidth
            }
        }
        
        textContentLabelWidth = max(textContentLabelWidth, YepConfig.ChatCell.minTextWidth)

        UIView.performWithoutAnimation { [weak self] in

            if let strongSelf = self {
                
                strongSelf.makeUI()
                
                let topOffset: CGFloat
                if strongSelf.inGroup {
                    topOffset = YepConfig.ChatCell.marginTopForGroup
                } else {
                    topOffset = 0
                }

                let textContentTextViewFrame = CGRect(x: CGRectGetMaxX(strongSelf.avatarImageView.frame) + YepConfig.chatCellGapBetweenTextContentLabelAndAvatar(), y: 3 + topOffset, width: textContentLabelWidth, height: strongSelf.bounds.height - topOffset - 3 * 2 - strongSelf.bottomGap)

                strongSelf.textContentTextView.frame = textContentTextViewFrame

                let bubbleBodyFrame = CGRectInset(textContentTextViewFrame, -12, -3)
                
                strongSelf.bubbleBodyShapeLayer.path = UIBezierPath(roundedRect: bubbleBodyFrame, byRoundingCorners: UIRectCorner.AllCorners, cornerRadii: CGSize(width: YepConfig.ChatCell.bubbleCornerRadius, height: YepConfig.ChatCell.bubbleCornerRadius)).CGPath
                
                if strongSelf.inGroup {
                    strongSelf.nameLabel.text = strongSelf.user?.chatCellCompositedName

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

