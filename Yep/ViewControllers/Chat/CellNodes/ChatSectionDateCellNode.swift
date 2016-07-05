//
//  ChatSectionDateCellNode.swift
//  Yep
//
//  Created by NIX on 16/7/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift
import AsyncDisplayKit

class ChatSectionDateCellNode: ASCellNode {

    lazy var textNode: ASTextNode = {
        let node = ASTextNode()
        node.contentMode = .Center
        return node
    }()


    override init() {
        super.init()

        addSubnode(textNode)
    }

    override func calculateSizeThatFits(constrainedSize: CGSize) -> CGSize {

        return CGSize(width: constrainedSize.width, height: 20)
    }

    override func layout() {
        super.layout()

        textNode.frame = bounds.insetBy(dx: 15, dy: 0)
    }
}

