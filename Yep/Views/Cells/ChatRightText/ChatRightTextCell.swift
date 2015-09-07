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

        avatarImageView.center = CGPoint(x: fullWidth - halfAvatarSize - YepConfig.chatCellGapBetweenWallAndAvatar(), y: halfAvatarSize)
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

        let longPress = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        textContainerView.addGestureRecognizer(longPress)
        longPress.delegate = self

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

    func handleLongPress(longPress: UILongPressGestureRecognizer) {
        if longPress.state == .Began {

            if let view = longPress.view, superview = view.superview {

                view.becomeFirstResponder()

                let menu = UIMenuController.sharedMenuController()
                let copyItem = UIMenuItem(title: NSLocalizedString("Copy", comment: ""), action:"copyText")
                let deleteItem = UIMenuItem(title: NSLocalizedString("Delete", comment: ""), action:"deleteTextMessage")
                menu.menuItems = [copyItem, deleteItem]
                menu.setTargetRect(view.frame, inView: superview)
                menu.setMenuVisible(true, animated: true)
            }
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

        textContentTextView.textAlignment = textContentLabelWidth < YepConfig.minMessageTextLabelWidth ? .Center : .Left

        // 用 sizeThatFits 来对比，不需要 magicWidth 的时候就可以避免了
        var textContentLabelWidth = textContentLabelWidth
        let size = textContentTextView.sizeThatFits(CGSize(width: textContentLabelWidth, height: CGFloat.max))
        if size.width != textContentLabelWidth {
            textContentLabelWidth += YepConfig.ChatCell.magicWidth
        }

        textContainerView.frame = CGRect(x: CGRectGetMinX(avatarImageView.frame) - YepConfig.chatCellGapBetweenTextContentLabelAndAvatar() - textContentLabelWidth, y: 3, width: textContentLabelWidth, height: bounds.height - 3 * 2)
        bubbleBodyImageView.frame = CGRectInset(textContainerView.frame, -12, -3)
        bubbleTailImageView.center = CGPoint(x: CGRectGetMaxX(bubbleBodyImageView.frame), y: CGRectGetMidY(avatarImageView.frame))
        dotImageView.center = CGPoint(x: CGRectGetMinX(bubbleBodyImageView.frame) - 5, y: CGRectGetMidY(bubbleBodyImageView.frame))

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

extension ChatRightTextCell: UIGestureRecognizerDelegate {

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        return true
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        return true
    }
}

