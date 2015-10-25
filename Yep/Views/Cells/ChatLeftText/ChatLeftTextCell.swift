//
//  ChatLeftTextCell.swift
//  Yep
//
//  Created by NIX on 15/3/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatLeftTextCell: ChatBaseCell {

    @IBOutlet weak var bubbleBodyImageView: UIImageView!
    @IBOutlet weak var bubbleTailImageView: UIImageView!

    @IBOutlet weak var textContainerView: ChatTextContainerView!
    @IBOutlet weak var textContentTextView: ChatTextView!

    func makeUI() {

        let halfAvatarSize = YepConfig.chatCellAvatarSize() / 2

        avatarImageView.center = CGPoint(x: YepConfig.chatCellGapBetweenWallAndAvatar() + halfAvatarSize, y: halfAvatarSize)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

//        dispatch_async(dispatch_get_main_queue()) { [weak self] in
        makeUI()
//        }

        textContentTextView.textContainer.lineFragmentPadding = 0
        textContentTextView.font = UIFont.chatTextFont()
        textContentTextView.backgroundColor = UIColor.clearColor()
        textContentTextView.textColor = UIColor.blackColor()
        textContentTextView.tintColor = UIColor.blackColor()
        textContentTextView.linkTextAttributes = [
            NSForegroundColorAttributeName: UIColor.yepTintColor(),
            NSUnderlineStyleAttributeName: NSNumber(integer: NSUnderlineStyle.StyleSingle.rawValue),
        ]


        textContainerView.copyTextAction = { [weak self] in
            UIPasteboard.generalPasteboard().string = self?.textContentTextView.text
        }

        bubbleBodyImageView.tintColor = UIColor.leftBubbleTintColor()
        bubbleTailImageView.tintColor = UIColor.leftBubbleTintColor()
    }
    
    override func respondsToSelector(aSelector: Selector) -> Bool {
        if  ["copy:"].contains(aSelector) {
            return true
        } else {
            return super.respondsToSelector(aSelector)
        }
    }

    func configureWithMessage(message: Message, textContentLabelWidth: CGFloat, collectionView: UICollectionView, indexPath: NSIndexPath) {

        self.user = message.fromFriend

//        dispatch_async(dispatch_get_main_queue()) { [weak self] in
//            if let self = self {
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
                
                self.textContainerView.frame = CGRect(x: CGRectGetMaxX(self.avatarImageView.frame) + YepConfig.chatCellGapBetweenTextContentLabelAndAvatar(), y: 3, width: textContentLabelWidth, height: self.bounds.height - 3 * 2)
                self.bubbleBodyImageView.frame = CGRectInset(self.textContainerView.frame, -12, -3)
                self.bubbleTailImageView.center = CGPoint(x: CGRectGetMinX(self.bubbleBodyImageView.frame), y: CGRectGetMidY(self.avatarImageView.frame))

//            }
//        }

        if let sender = message.fromFriend {
            let userAvatar = UserAvatar(userID: sender.userID, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar)
        }
    }
}

