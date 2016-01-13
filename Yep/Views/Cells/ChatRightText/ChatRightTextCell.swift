//
//  ChatRightTextCell.swift
//  Yep
//
//  Created by NIX on 15/3/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatRightTextCell: ChatRightBaseCell {

    @IBOutlet weak var bubbleTailImageView: UIImageView!
    
    var bubbleBodyShapeLayer: CAShapeLayer!

    @IBOutlet weak var textContainerView: UIView!
    @IBOutlet weak var textContentTextView: ChatTextView!

//    lazy var textContentTextView: ChatTextView = {
//        let textView = ChatTextView()
//        return textView
//    }()

    typealias MediaTapAction = () -> Void
    var mediaTapAction: MediaTapAction?

    func makeUI() {

        let fullWidth = UIScreen.mainScreen().bounds.width

        let halfAvatarSize = YepConfig.chatCellAvatarSize() / 2

        avatarImageView.center = CGPoint(x: fullWidth - halfAvatarSize - YepConfig.chatCellGapBetweenWallAndAvatar(), y: halfAvatarSize)

        //contentView.addSubview(textContentTextView)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        UIView.performWithoutAnimation { [weak self] in
            self?.makeUI()
        }
        
        bubbleBodyShapeLayer = CAShapeLayer()
        bubbleBodyShapeLayer.backgroundColor = UIColor.rightBubbleTintColor().CGColor
        bubbleBodyShapeLayer.fillColor = UIColor.rightBubbleTintColor().CGColor

        textContentTextView.textContainer.lineFragmentPadding = 0
        textContentTextView.font = UIFont.chatTextFont()
        
        textContentTextView.backgroundColor = UIColor.clearColor()
        textContentTextView.textColor = UIColor.whiteColor()
        textContentTextView.tintColor = UIColor.whiteColor()
        textContentTextView.linkTextAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSUnderlineStyleAttributeName: NSNumber(integer: NSUnderlineStyle.StyleSingle.rawValue),
        ]

        textContainerView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tapMediaView")
        textContainerView.addGestureRecognizer(tap)

        prepareForMenuAction = { otherGesturesEnabled in
            tap.enabled = otherGesturesEnabled
        }

        bubbleTailImageView.tintColor = UIColor.rightBubbleTintColor()
        
        if let bubblePosition = layer.sublayers {
            contentView.layer.insertSublayer(bubbleBodyShapeLayer, atIndex: UInt32(bubblePosition.count))
        }
    }

    func tapMediaView() {
        mediaTapAction?()
    }

    func configureWithMessage(message: Message, textContentLabelWidth: CGFloat, mediaTapAction: MediaTapAction?, collectionView: UICollectionView, indexPath: NSIndexPath) {

        self.message = message
        self.user = message.fromFriend

        self.mediaTapAction = mediaTapAction

        textContentTextView.text = message.textContent
        //textContentTextView.attributedText = NSAttributedString(string: message.textContent, attributes: textAttributes)

        //textContentTextView.textAlignment = textContentLabelWidth < YepConfig.minMessageTextLabelWidth ? .Center : .Left

        // 用 sizeThatFits 来对比，不需要 magicWidth 的时候就可以避免了
        var textContentLabelWidth = textContentLabelWidth
        let size = textContentTextView.sizeThatFits(CGSize(width: textContentLabelWidth, height: CGFloat.max))

        // lineHeight 19.088, size.height 35.5 (1 line) 54.5 (2 lines)
        textContentTextView.textAlignment = ((size.height - textContentTextView.font!.lineHeight) < 20) ? .Center : .Left

        if ceil(size.width) != textContentLabelWidth {

            //println("right ceil(size.width): \(ceil(size.width)), textContentLabelWidth: \(textContentLabelWidth)")
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
                
                strongSelf.textContainerView.frame = CGRect(x: CGRectGetMinX(strongSelf.avatarImageView.frame) - YepConfig.chatCellGapBetweenTextContentLabelAndAvatar() - textContentLabelWidth, y: 3, width: textContentLabelWidth, height: strongSelf.bounds.height - 3 * 2)

                strongSelf.textContentTextView.frame = strongSelf.textContainerView.bounds
                
                let bubbleBodyFrame = CGRectInset(strongSelf.textContainerView.frame, -12, -3)
                
                strongSelf.bubbleBodyShapeLayer.path = UIBezierPath(roundedRect: bubbleBodyFrame, byRoundingCorners: UIRectCorner.AllCorners, cornerRadii: CGSize(width: YepConfig.ChatCell.bubbleCornerRadius, height: YepConfig.ChatCell.bubbleCornerRadius)).CGPath

                strongSelf.bubbleTailImageView.center = CGPoint(x: CGRectGetMaxX(bubbleBodyFrame), y: CGRectGetMidY(strongSelf.avatarImageView.frame))
                
                strongSelf.dotImageView.center = CGPoint(x: CGRectGetMinX(bubbleBodyFrame) - YepConfig.ChatCell.gapBetweenDotImageViewAndBubble, y: CGRectGetMidY(strongSelf.textContainerView.frame))
            }
        }

        //println("textContentTextView.frame: \(textContentTextView.frame)")

        if let sender = message.fromFriend {
            let userAvatar = UserAvatar(userID: sender.userID, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
        }
    }
}

