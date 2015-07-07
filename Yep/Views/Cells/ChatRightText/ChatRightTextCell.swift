//
//  ChatRightTextCell.swift
//  Yep
//
//  Created by NIX on 15/3/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatRightTextCell: ChatRightBaseCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarImageViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var bubbleBodyImageView: UIImageView!
    @IBOutlet weak var bubbleTailImageView: UIImageView!

    @IBOutlet weak var textContentTextView: ChatTextView!
    @IBOutlet weak var textContentTextViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textContentTextViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textContentTextViewWidthConstraint: NSLayoutConstraint!

    typealias MediaTapAction = () -> Void
    var mediaTapAction: MediaTapAction?

    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageViewWidthConstraint.constant = YepConfig.chatCellAvatarSize()
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

        textContentTextView.deleteEnabled = true
        textContentTextView.deleteAction = {
            println("delete text message?")
        }

        let longPress = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        textContentTextView.addGestureRecognizer(longPress)
        
        textContentTextViewTrailingConstraint.constant = YepConfig.chatCellGapBetweenTextContentLabelAndAvatar()
        textContentTextViewLeadingConstraint.constant = YepConfig.chatTextGapBetweenWallAndContentLabel()

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

        self.mediaTapAction = mediaTapAction

        textContentTextView.text = message.textContent

        textContentTextViewWidthConstraint.constant = max(YepConfig.minMessageTextLabelWidth, textContentLabelWidth)
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
