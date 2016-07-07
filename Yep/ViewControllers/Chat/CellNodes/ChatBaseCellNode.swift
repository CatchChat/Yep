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

    static let avatarSize = CGSize(width: 40, height: 40)
    static let topPadding: CGFloat = 5
    static let bottomPadding: CGFloat = 10

    var user: User? {
        didSet {
            if let user = user {
                let userAvatar = UserAvatar(userID: user.userID, avatarURLString: user.avatarURLString, avatarStyle: nanoAvatarStyle)
                avatarImageNode.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
            }
        }
    }
    var tapAvatarAction: ((user: User) -> Void)?

    lazy var nameNode = ASTextNode()
    lazy var avatarImageNode: ASImageNode = {
        let node = ASImageNode()
        let tapAvatar = UITapGestureRecognizer(target: self, action: #selector(ChatBaseCellNode.tapAvatar(_:)))
        node.userInteractionEnabled = true
        node.view.addGestureRecognizer(tapAvatar)
        return node
    }()

    override init() {
        super.init()

        //addSubnode(nameNode)
        addSubnode(avatarImageNode)
        avatarImageNode.backgroundColor = UIColor.redColor()
    }

    @objc private func tapAvatar(sender: UITapGestureRecognizer) {
        println("tapAvatar")

        if let user = user {
            tapAvatarAction?(user: user)
        }
    }
}

