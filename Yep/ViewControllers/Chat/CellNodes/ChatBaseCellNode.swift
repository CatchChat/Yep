//
//  ChatBaseCellNode.swift
//  Yep
//
//  Created by NIX on 16/7/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift
import AsyncDisplayKit

class ChatBaseCellNode: ASCellNode {

    var user: User? {
        didSet {
            if let user = user {
                let userAvatar = UserAvatar(userID: user.userID, avatarURLString: user.avatarURLString, avatarStyle: nanoAvatarStyle)
                //avatarImageNode.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
            }
        }
    }
    var tapAvatarAction: ((user: User) -> Void)?

    lazy var nameNode = ASTextNode()
    lazy var avatarImageNode = ASImageNode()

    override init() {
        super.init()

        //addSubnode(nameNode)
        addSubnode(avatarImageNode)
        avatarImageNode.backgroundColor = UIColor.redColor()

        let tapAvatar = UITapGestureRecognizer(target: self, action: #selector(ChatBaseCellNode.tapAvatar(_:)))
        avatarImageNode.userInteractionEnabled = true
        avatarImageNode.view.addGestureRecognizer(tapAvatar)
    }

    @objc private func tapAvatar(sender: UITapGestureRecognizer) {
        println("tapAvatar")

        if let user = user {
            tapAvatarAction?(user: user)
        }
    }

    override func calculateSizeThatFits(constrainedSize: CGSize) -> CGSize {

        return CGSize(width: constrainedSize.width, height: 50)
    }

    override func layout() {
        super.layout()

        avatarImageNode.frame = CGRect(x: 15, y: 0, width: 40, height: 40)
    }
}
