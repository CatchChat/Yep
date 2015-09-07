//
//  ChatLeftTextCell.swift
//  Yep
//
//  Created by NIX on 15/3/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatLeftTextCell: ChatBaseCell {

//    @IBOutlet weak var avatarImageViewLeadingConstraint: NSLayoutConstraint!

    @IBOutlet weak var bubbleBodyImageView: UIImageView!
    @IBOutlet weak var bubbleTailImageView: UIImageView!

    @IBOutlet weak var textContainerView: ChatTextContainerView!
    @IBOutlet weak var textContentTextView: ChatTextView!
//    @IBOutlet weak var textContentTextViewTrailingConstraint: NSLayoutConstraint!
//    @IBOutlet weak var textContentTextViewLeadingConstraint: NSLayoutConstraint!
    //@IBOutlet weak var textContentTextViewWidthConstraint: NSLayoutConstraint!

    func makeUI() {

        let fullWidth = UIScreen.mainScreen().bounds.width

        let halfAvatarSize = YepConfig.chatCellAvatarSize() / 2

        avatarImageView.center = CGPoint(x: YepConfig.chatCellGapBetweenWallAndAvatar() + halfAvatarSize, y: halfAvatarSize)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = UIColor.greenColor()

        makeUI()

//        avatarImageViewLeadingConstraint.constant = YepConfig.chatCellGapBetweenWallAndAvatar()

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

//        textContentTextViewTrailingConstraint.constant = YepConfig.chatTextGapBetweenWallAndContentLabel() - YepConfig.ChatCell.magicWidth
//        textContentTextViewLeadingConstraint.constant = YepConfig.chatCellGapBetweenTextContentLabelAndAvatar()

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

        // 用 sizeThatFits 来对比，不需要 magicWidth 的时候就可以避免了
//        let size = textContentTextView.sizeThatFits(CGSize(width: textContentLabelWidth, height: CGFloat.max))
//        if size.width == textContentLabelWidth {
//            textContentTextViewTrailingConstraint.constant = YepConfig.chatTextGapBetweenWallAndContentLabel()
//        } else {
//            textContentTextViewTrailingConstraint.constant = YepConfig.chatTextGapBetweenWallAndContentLabel() - YepConfig.ChatCell.magicWidth
//        }

//        contentView.layoutIfNeeded()

        var textContentLabelWidth = textContentLabelWidth

        let size = textContentTextView.sizeThatFits(CGSize(width: textContentLabelWidth, height: CGFloat.max))
        if size.width != textContentLabelWidth {
            textContentLabelWidth += YepConfig.ChatCell.magicWidth
        }

        textContainerView.frame = CGRect(x: CGRectGetMaxX(avatarImageView.frame) + YepConfig.chatCellGapBetweenTextContentLabelAndAvatar(), y: 3, width: textContentLabelWidth, height: bounds.height - 3 * 2)

        println(textContainerView.frame)

        bubbleBodyImageView.frame = CGRectInset(textContainerView.frame, -12, -3)

        println(bubbleBodyImageView.frame)

        bubbleTailImageView.center = CGPoint(x: CGRectGetMinX(bubbleBodyImageView.frame), y: CGRectGetMidY(avatarImageView.frame))

        println(bubbleTailImageView.frame)



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

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        return true
    }
}

