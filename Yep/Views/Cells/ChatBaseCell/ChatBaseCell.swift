//
//  ChatBaseCell.swift
//  Yep
//
//  Created by nixzhu on 15/8/6.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

class ChatBaseCell: UICollectionViewCell {

    lazy var nameLabel: UILabel = {
        let label = UILabel(frame: CGRectZero)
        label.font = UIFont.systemFontOfSize(10)
        label.textColor = UIColor.yepGrayColor()
        label.numberOfLines = 1
        self.contentView.addSubview(label)
        return label
    }()

    lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()

        imageView.frame = CGRect(x: 15, y: 0, width: 40, height: 40)

        imageView.contentMode = .ScaleAspectFit

        let tapAvatar = UITapGestureRecognizer(target: self, action: #selector(ChatBaseCell.tapAvatar(_:)))
        imageView.userInteractionEnabled = true
        imageView.addGestureRecognizer(tapAvatar)

        return imageView
    }()
    
    var user: User?
    var tapAvatarAction: ((user: User) -> Void)?
    
    var deleteMessageAction: (() -> Void)?
    var reportMessageAction: (() -> Void)?

    deinit {
        NSNotificationCenter.defaultCenter()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(avatarImageView)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatBaseCell.menuWillShow(_:)), name: UIMenuControllerWillShowMenuNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatBaseCell.menuWillHide(_:)), name: UIMenuControllerWillHideMenuNotification, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var prepareForMenuAction: ((otherGesturesEnabled: Bool) -> Void)?

    @objc func menuWillShow(notification: NSNotification) {
        prepareForMenuAction?(otherGesturesEnabled: false)
    }

    @objc func menuWillHide(notification: NSNotification) {
        prepareForMenuAction?(otherGesturesEnabled: true)
    }

    var inGroup = false

    @objc private func tapAvatar(sender: UITapGestureRecognizer) {
        println("tapAvatar")

        if let user = user {
            tapAvatarAction?(user: user)
        }
    }

    func deleteMessage(object: UIMenuController?) {
        deleteMessageAction?()
    }

    func reportMessage(object: UIMenuController?) {
        reportMessageAction?()
    }
}

extension ChatBaseCell: UIGestureRecognizerDelegate {

    // 让触发 Menu 和 Tap Media 能同时工作，不然 Tap 会让 Menu 不能弹出

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        return true
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        // iOS 9 在长按链接时不弹出 menu

        if let longPressGestureRecognizer = otherGestureRecognizer as? UILongPressGestureRecognizer {
            if longPressGestureRecognizer.minimumPressDuration == 0.75 {
                return true
            }
        }

        return false
    }
}

