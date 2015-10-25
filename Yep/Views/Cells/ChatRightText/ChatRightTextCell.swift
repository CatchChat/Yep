//
//  ChatRightTextCell.swift
//  Yep
//
//  Created by NIX on 15/3/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatRightTextCell: ChatRightBaseCell {

    @IBOutlet weak var bubbleBodyImageView: UIImageView!
    @IBOutlet weak var bubbleTailImageView: UIImageView!

    @IBOutlet weak var textContainerView: ChatTextContainerView!
    @IBOutlet weak var textContentTextView: ChatTextView!

    typealias MediaTapAction = () -> Void
    var mediaTapAction: MediaTapAction?

    var longPressAction: (() -> Void)?

    func makeUI() {

        let fullWidth = UIScreen.mainScreen().bounds.width

        let halfAvatarSize = YepConfig.chatCellAvatarSize() / 2
        
//        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self.avatarImageView.center = CGPoint(x: fullWidth - halfAvatarSize - YepConfig.chatCellGapBetweenWallAndAvatar(), y: halfAvatarSize)
//        }

    }
    
    override func respondsToSelector(aSelector: Selector) -> Bool {
        if  ["deleteMessage:" ,"copy:"].contains(aSelector) {
            return true
        } else {
            return super.respondsToSelector(aSelector)
        }
    }
    
    func deleteMessage(object: UIMenuController?) {
        if let longPressAction = longPressAction {
            longPressAction()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        makeUI()
        
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.mainScreen().scale

        textContentTextView.textContainer.lineFragmentPadding = 0
        textContentTextView.font = UIFont.chatTextFont()
        

        textContentTextView.backgroundColor = UIColor.clearColor()
        textContentTextView.textColor = UIColor.whiteColor()
        textContentTextView.tintColor = UIColor.whiteColor()
        textContentTextView.linkTextAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSUnderlineStyleAttributeName: NSNumber(integer: NSUnderlineStyle.StyleSingle.rawValue),
        ]

        textContainerView.copyTextAction = { [weak self] in
            UIPasteboard.generalPasteboard().string = self?.textContentTextView.text
        }

        textContainerView.deleteTextMessageAction = { [weak self] in
            self?.longPressAction?()
        }
        
        bubbleBodyImageView.tintColor = UIColor.rightBubbleTintColor()
        bubbleTailImageView.tintColor = UIColor.rightBubbleTintColor()

        bubbleBodyImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tapMediaView")
        bubbleBodyImageView.addGestureRecognizer(tap)
    }


    func tapMediaView() {
        mediaTapAction?()
    }

    func configureWithMessage(message: Message, textContentLabelWidth: CGFloat, mediaTapAction: MediaTapAction?, collectionView: UICollectionView, indexPath: NSIndexPath) {

        self.message = message
        self.user = message.fromFriend

        self.mediaTapAction = mediaTapAction
        
//        dispatch_async(dispatch_get_main_queue()) { [weak self] in

//            let self = self {
                self.textContentTextView.text = message.textContent
                //textContentTextView.attributedText = NSAttributedString(string: message.textContent, attributes: textAttributes)
                
                //textContentTextView.textAlignment = textContentLabelWidth < YepConfig.minMessageTextLabelWidth ? .Center : .Left
                
                // 用 sizeThatFits 来对比，不需要 magicWidth 的时候就可以避免了
                var textContentLabelWidth = textContentLabelWidth
                let size = self.textContentTextView.sizeThatFits(CGSize(width: textContentLabelWidth, height: CGFloat.max))
                
                // lineHeight 19.088, size.height 35.5 (1 line) 54.5 (2 lines)
                self.textContentTextView.textAlignment = ((size.height - self.textContentTextView.font!.lineHeight) < 20) ? .Center : .Left
                
                if size.width != textContentLabelWidth {
                    textContentLabelWidth += YepConfig.ChatCell.magicWidth
                }
                
                textContentLabelWidth = max(textContentLabelWidth, YepConfig.ChatCell.minTextWidth)
                
                self.textContainerView.frame = CGRect(x: CGRectGetMinX(self.avatarImageView.frame) - YepConfig.chatCellGapBetweenTextContentLabelAndAvatar() - textContentLabelWidth, y: 3, width: textContentLabelWidth, height: self.bounds.height - 3 * 2)
                self.bubbleBodyImageView.frame = CGRectInset(self.textContainerView.frame, -12, -3)
                self.bubbleTailImageView.center = CGPoint(x: CGRectGetMaxX(self.bubbleBodyImageView.frame), y: CGRectGetMidY(self.avatarImageView.frame))
                self.dotImageView.center = CGPoint(x: CGRectGetMinX(self.bubbleBodyImageView.frame) - YepConfig.ChatCell.gapBetweenDotImageViewAndBubble, y: CGRectGetMidY(self.bubbleBodyImageView.frame))
//            }
//        }

        if let sender = message.fromFriend {
            let userAvatar = UserAvatar(userID: sender.userID, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar)
        }
    }
}

