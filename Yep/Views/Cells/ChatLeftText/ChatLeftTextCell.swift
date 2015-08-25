//
//  ChatLeftTextCell.swift
//  Yep
//
//  Created by NIX on 15/3/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatLeftTextCell: ChatBaseCell {

    @IBOutlet weak var avatarImageViewLeadingConstraint: NSLayoutConstraint!

    @IBOutlet weak var bubbleBodyImageView: UIImageView!
    @IBOutlet weak var bubbleTailImageView: UIImageView!

    @IBOutlet weak var textContainerView: ChatTextContainerView!
    @IBOutlet weak var textContentTextView: ChatTextView!
    @IBOutlet weak var textContentTextViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textContentTextViewLeadingConstraint: NSLayoutConstraint!
    //@IBOutlet weak var textContentTextViewWidthConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageViewLeadingConstraint.constant = YepConfig.chatCellGapBetweenWallAndAvatar()

        textContentTextView.textContainer.lineFragmentPadding = 0
        textContentTextView.font = UIFont.chatTextFont()
        textContentTextView.backgroundColor = UIColor.clearColor()
        textContentTextView.textColor = UIColor.blackColor()
        textContentTextView.tintColor = UIColor.blackColor()
        textContentTextView.linkTextAttributes = [
            NSForegroundColorAttributeName: UIColor.yepTintColor(),
            NSUnderlineStyleAttributeName: NSNumber(integer: NSUnderlineStyle.StyleSingle.rawValue),
        ]

        let longPress = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        textContainerView.addGestureRecognizer(longPress)
        longPress.delegate = self

        textContainerView.copyTextAction = { [weak self] in
            UIPasteboard.generalPasteboard().string = self?.textContentTextView.text
        }

        textContentTextViewTrailingConstraint.constant = YepConfig.chatTextGapBetweenWallAndContentLabel() - YepConfig.ChatCell.magicWidth
        textContentTextViewLeadingConstraint.constant = YepConfig.chatCellGapBetweenTextContentLabelAndAvatar()
        
        bubbleBodyImageView.tintColor = UIColor.leftBubbleTintColor()
        bubbleTailImageView.tintColor = UIColor.leftBubbleTintColor()
    }

    func handleLongPress(longPress: UILongPressGestureRecognizer) {
        if longPress.state == .Began {

            if let view = longPress.view, superview = view.superview {

                view.becomeFirstResponder()

                let menu = UIMenuController.sharedMenuController()
                let copyItem = UIMenuItem(title: NSLocalizedString("Copy", comment: ""), action:"copyText")
                menu.menuItems = [copyItem]
                menu.setTargetRect(view.frame, inView: superview)
                menu.setMenuVisible(true, animated: true)
            }
        }
    }

    func configureWithMessage(message: Message, textContentLabelWidth: CGFloat, collectionView: UICollectionView, indexPath: NSIndexPath) {

        self.user = message.fromFriend
        
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

extension ChatLeftTextCell: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

