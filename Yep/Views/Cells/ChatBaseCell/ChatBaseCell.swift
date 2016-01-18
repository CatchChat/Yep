//
//  ChatBaseCell.swift
//  Yep
//
//  Created by nixzhu on 15/8/6.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatBaseCell: UICollectionViewCell {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    
    var user: User?
    var tapAvatarAction: ((user: User) -> Void)?
    
    var deleteMessageAction: (() -> Void)?
    
    lazy var nameLabel: UILabel = {
        let label = UILabel(frame: CGRectZero)
        label.font = UIFont.systemFontOfSize(10)
        label.textColor = UIColor.yepGrayColor()
        label.numberOfLines = 1
        self.contentView.addSubview(label)
        return label
    }()

    deinit {
        NSNotificationCenter.defaultCenter()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tapAvatar")
        avatarImageView.addGestureRecognizer(tap)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "menuWillShow:", name: UIMenuControllerWillShowMenuNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "menuWillHide:", name: UIMenuControllerWillHideMenuNotification, object: nil)
    }

    var prepareForMenuAction: ((otherGesturesEnabled: Bool) -> Void)?

    @objc func menuWillShow(notification: NSNotification) {
        prepareForMenuAction?(otherGesturesEnabled: false)
    }

    @objc func menuWillHide(notification: NSNotification) {
        prepareForMenuAction?(otherGesturesEnabled: true)
    }

    var inGroup = false

    func tapAvatar() {
        println("tapAvatar")

        if let user = user {
            tapAvatarAction?(user: user)
        }
    }

    func deleteMessage(object: UIMenuController?) {
        deleteMessageAction?()
    }
}

extension ChatBaseCell: UIGestureRecognizerDelegate {

    // 让触发 Menu 和 Tap Media 能同时工作，不然 Tap 会让 Menu 不能弹出

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        return true
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        // iOS 9 在长按链接时不弹出 menu

        if isOperatingSystemAtLeastMajorVersion(9) {

            if let longPressGestureRecognizer = otherGestureRecognizer as? UILongPressGestureRecognizer {
                if longPressGestureRecognizer.minimumPressDuration == 0.75 {
                    return true
                }
            }

            return false
        }
        
        return true
    }
}

