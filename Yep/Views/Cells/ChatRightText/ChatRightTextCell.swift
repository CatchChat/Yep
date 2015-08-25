//
//  ChatRightTextCell.swift
//  Yep
//
//  Created by NIX on 15/3/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatRightTextCell: ChatRightBaseCell {

    @IBOutlet weak var avatarImageViewTrailingConstraint: NSLayoutConstraint!

    @IBOutlet weak var bubbleBodyImageView: UIImageView!
    @IBOutlet weak var bubbleTailImageView: UIImageView!

    @IBOutlet weak var textContainerView: ChatTextContainerView!
    @IBOutlet weak var textContentTextView: ChatTextView!
    @IBOutlet weak var textContentTextViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textContentTextViewLeadingConstraint: NSLayoutConstraint!
    //@IBOutlet weak var textContentTextViewWidthConstraint: NSLayoutConstraint!

    typealias MediaTapAction = () -> Void
    var mediaTapAction: MediaTapAction?

    var longPressAction: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageViewTrailingConstraint.constant = YepConfig.chatCellGapBetweenWallAndAvatar()

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
        
        textContentTextViewTrailingConstraint.constant = YepConfig.chatCellGapBetweenTextContentLabelAndAvatar()
        textContentTextViewLeadingConstraint.constant = YepConfig.chatTextGapBetweenWallAndContentLabel() - YepConfig.ChatCell.magicWidth

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

        //textContentTextViewWidthConstraint.constant = max(YepConfig.minMessageTextLabelWidth, textContentLabelWidth)
        textContentTextView.textAlignment = textContentLabelWidth < YepConfig.minMessageTextLabelWidth ? .Center : .Left

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

