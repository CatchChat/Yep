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
    
    lazy var nameLabel: UILabel = {
        let label = UILabel(frame: CGRectZero)
        label.font = UIFont.systemFontOfSize(14.0)
        label.textColor = UIColor.yepGrayColor()
        self.addSubview(label)
        return label
    }()

    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tapAvatar")
        avatarImageView.addGestureRecognizer(tap)
    }
    
    var inGroup = false

    func tapAvatar() {
        println("tapAvatar")

        if let user = user {
            tapAvatarAction?(user: user)
        }
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

