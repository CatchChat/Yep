//
//  ChatLeftLocationCellNode.swift
//  Yep
//
//  Created by NIX on 16/7/13.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import AsyncDisplayKit

class ChatLeftLocationCellNode: ChatLeftBaseCellNode {

    static let mapSize = CGSize(width: 192, height: 108)

    var tapMapAction: (() -> Void)?

    lazy var imageNode: ASImageNode = {
        let node = ASImageNode()
        node.contentMode = .ScaleAspectFill

        let tap = UITapGestureRecognizer(target: self, action: #selector(ChatLeftLocationCellNode.tapMap(_:)))
        node.userInteractionEnabled = true
        node.view.addGestureRecognizer(tap)

        return node
    }()

    @objc private func tapMap(sender: UITapGestureRecognizer) {

        tapMapAction?()
    }

    override init() {
        super.init()

        addSubnode(imageNode)
    }

    func configure(withMessage message: Message) {

        self.user = message.fromFriend

        do {
            let locationName = message.textContent

            ImageCache.sharedInstance.mapImageOfMessage(message, withSize: ChatLeftLocationCellNode.mapSize, tailDirection: .Left, bottomShadowEnabled: !locationName.isEmpty) { [weak self] mapImage in
                print("mapImage.resizingMode: \(mapImage.resizingMode.rawValue)")
                print("mapImage.capInsets: \(mapImage.capInsets)")
                self?.imageNode.image = mapImage
            }
        }
    }

    override func calculateSizeThatFits(constrainedSize: CGSize) -> CGSize {

        return CGSize(width: constrainedSize.width, height: ChatLeftLocationCellNode.mapSize.height + ChatBaseCellNode.verticalPadding)
    }

    override func layout() {
        super.layout()

        let x = 15 + ChatBaseCellNode.avatarSize.width + 5
        let y = ChatBaseCellNode.topPadding
        let origin = CGPoint(x: x, y: y)
        imageNode.frame = CGRect(origin: origin, size: ChatLeftLocationCellNode.mapSize)
    }
}

