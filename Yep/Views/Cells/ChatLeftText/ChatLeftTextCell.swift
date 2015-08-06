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

    @IBOutlet weak var textContentTextView: ChatTextView!
    @IBOutlet weak var textContentTextViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textContentTextViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textContentTextViewWidthConstraint: NSLayoutConstraint!

    var longPressAction: (ChatLeftTextCell -> Void)?

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
        textContentTextView.addGestureRecognizer(longPress)

        textContentTextViewTrailingConstraint.constant = YepConfig.chatTextGapBetweenWallAndContentLabel()
        textContentTextViewLeadingConstraint.constant = YepConfig.chatCellGapBetweenTextContentLabelAndAvatar()
        
        bubbleBodyImageView.tintColor = UIColor.leftBubbleTintColor()
        bubbleTailImageView.tintColor = UIColor.leftBubbleTintColor()
    }

    func handleLongPress(longPress: UILongPressGestureRecognizer) {
        if longPress.state == .Began {
            longPressAction?(self)
        }
    }

    func configureWithMessage(message: Message, textContentLabelWidth: CGFloat, collectionView: UICollectionView, indexPath: NSIndexPath) {

        self.user = message.fromFriend
        
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

