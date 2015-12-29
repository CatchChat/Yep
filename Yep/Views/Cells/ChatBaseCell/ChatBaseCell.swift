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
    
    var longpress: UILongPressGestureRecognizer!
    
    var user: User?
    var tapAvatarAction: ((user: User) -> Void)?
    
    var deleteMessageAction: (() -> Void)?
    
    lazy var nameLabel: UILabel = {
        let label = UILabel(frame: CGRectZero)
        label.font = UIFont.systemFontOfSize(10)
        label.textColor = UIColor.yepGrayColor()
        label.numberOfLines = 1
        self.addSubview(label)
        return label
    }()

    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tapAvatar")
        avatarImageView.addGestureRecognizer(tap)
        longpress = UILongPressGestureRecognizer(target: self, action: "doNothing")
        longpress.minimumPressDuration = 0.5
    }
    
    func doNothing() {
        
    }
    
    var inGroup = false

    func tapAvatar() {
        println("tapAvatar")

        if let user = user {
            tapAvatarAction?(user: user)
        }
    }
    
    override func respondsToSelector(aSelector: Selector) -> Bool {
        if ["deleteMessage:", "copy:"].contains(aSelector) {
            return true
        } else {
            return super.respondsToSelector(aSelector)
        }
    }
    
    func deleteMessage(object: UIMenuController?) {
        deleteMessageAction?()
    }
}

extension ChatBaseCell: UIGestureRecognizerDelegate {

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

