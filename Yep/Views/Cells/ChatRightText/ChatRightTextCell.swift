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
        
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.avatarImageView.center = CGPoint(x: fullWidth - halfAvatarSize - YepConfig.chatCellGapBetweenWallAndAvatar(), y: halfAvatarSize)
        }

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
        
        dispatch_async(dispatch_get_main_queue()) { [weak self] in

            if let strongSelf = self {
                strongSelf.textContentTextView.text = message.textContent
                //textContentTextView.attributedText = NSAttributedString(string: message.textContent, attributes: textAttributes)
                
                //textContentTextView.textAlignment = textContentLabelWidth < YepConfig.minMessageTextLabelWidth ? .Center : .Left
                
                // 用 sizeThatFits 来对比，不需要 magicWidth 的时候就可以避免了
                var textContentLabelWidth = textContentLabelWidth
                let size = strongSelf.textContentTextView.sizeThatFits(CGSize(width: textContentLabelWidth, height: CGFloat.max))
                
                // lineHeight 19.088, size.height 35.5 (1 line) 54.5 (2 lines)
                strongSelf.textContentTextView.textAlignment = ((size.height - strongSelf.textContentTextView.font!.lineHeight) < 20) ? .Center : .Left
                
                if size.width != textContentLabelWidth {
                    textContentLabelWidth += YepConfig.ChatCell.magicWidth
                }
                
                textContentLabelWidth = max(textContentLabelWidth, YepConfig.ChatCell.minTextWidth)
                
                strongSelf.textContainerView.frame = CGRect(x: CGRectGetMinX(strongSelf.avatarImageView.frame) - YepConfig.chatCellGapBetweenTextContentLabelAndAvatar() - textContentLabelWidth, y: 3, width: textContentLabelWidth, height: strongSelf.bounds.height - 3 * 2)
                strongSelf.bubbleBodyImageView.frame = CGRectInset(strongSelf.textContainerView.frame, -12, -3)
                strongSelf.bubbleTailImageView.center = CGPoint(x: CGRectGetMaxX(strongSelf.bubbleBodyImageView.frame), y: CGRectGetMidY(strongSelf.avatarImageView.frame))
                strongSelf.dotImageView.center = CGPoint(x: CGRectGetMinX(strongSelf.bubbleBodyImageView.frame) - YepConfig.ChatCell.gapBetweenDotImageViewAndBubble, y: CGRectGetMidY(strongSelf.bubbleBodyImageView.frame))
            }
        }

        if let sender = message.fromFriend {
            AvatarCache.sharedInstance.roundAvatarOfUser(sender, withRadius: YepConfig.chatCellAvatarSize() * 0.5) { [weak self] roundImage in
                dispatch_async(dispatch_get_main_queue()) {
                    if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                        self?.avatarImageView.image = roundImage
                    }
                }
            }
        }
    }
}

