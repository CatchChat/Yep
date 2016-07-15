//
//  ChatRightLocationCellNode.swift
//  Yep
//
//  Created by NIX on 16/7/13.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import AsyncDisplayKit

class ChatRightLocationCellNode: ChatRightBaseCellNode {

    private static let mapSize = CGSize(width: 192, height: 108)

    private static let nameAttributes = [
        NSForegroundColorAttributeName: UIColor.whiteColor(),
        NSFontAttributeName: UIFont.systemFontOfSize(12),
    ]

    var tapMapAction: ((message: Message) -> Void)?

    private lazy var imageNode: ASImageNode = {
        let node = ASImageNode()
        node.contentMode = .ScaleAspectFill

        let tap = UITapGestureRecognizer(target: self, action: #selector(ChatRightLocationCellNode.tapMap(_:)))
        node.userInteractionEnabled = true
        node.view.addGestureRecognizer(tap)

        return node
    }()

    private lazy var locationNameNode: ASTextNode = {
        let node = ASTextNode()
        node.layerBacked = true
        node.maximumNumberOfLines = 1
        return node
    }()

    private lazy var borderNode: ASImageNode = {
        let node = ASImageNode()
        node.contentMode = .ScaleAspectFill
        let image = UIImage(named: "right_tail_image_bubble_border")?.resizableImageWithCapInsets(UIEdgeInsets(top: 24, left: 20, bottom: 20, right: 27), resizingMode: .Stretch)
        node.image = image
        return node
    }()

    private var message: Message?

    override init() {
        super.init()

        addSubnode(imageNode)
        addSubnode(locationNameNode)
        addSubnode(borderNode)
    }

    func configure(withMessage message: Message) {

        self.user = message.fromFriend

        self.message = message

        do {
            let locationName = message.textContent

            locationNameNode.attributedText = NSAttributedString(string: locationName, attributes: ChatRightLocationCellNode.nameAttributes)

            ImageCache.sharedInstance.mapImageOfMessage(message, withSize: ChatRightLocationCellNode.mapSize, tailDirection: .Right, bottomShadowEnabled: !locationName.isEmpty) { [weak self] mapImage in
                self?.imageNode.image = mapImage
            }
        }
    }

    override func calculateSizeThatFits(constrainedSize: CGSize) -> CGSize {

        let nameMaxWidth = ChatRightLocationCellNode.mapSize.width - (10 + 10)
        locationNameNode.measure(CGSize(width: nameMaxWidth, height: CGFloat.max))

        return CGSize(width: constrainedSize.width, height: ChatRightLocationCellNode.mapSize.height + ChatBaseCellNode.verticalPadding)
    }

    override func layout() {
        super.layout()

        let size = ChatRightLocationCellNode.mapSize
        let x = calculatedSize.width - (size.width + 5 + ChatBaseCellNode.avatarSize.width + 15)
        let y = ChatBaseCellNode.topPadding
        let origin = CGPoint(x: x, y: y)
        imageNode.frame = CGRect(origin: origin, size: size)

        borderNode.frame = imageNode.frame

        do {
            let offsetX = (ChatRightLocationCellNode.mapSize.width - locationNameNode.calculatedSize.width) / 2
            let y = ChatBaseCellNode.topPadding + ChatRightLocationCellNode.mapSize.height - 20
            let offsetY = (20 - locationNameNode.calculatedSize.height) / 2
            let origin = CGPoint(x: x + offsetX, y: y + offsetY)
            locationNameNode.frame = CGRect(origin: origin, size: locationNameNode.calculatedSize)
        }
    }

    // MARK: Selectors

    @objc private func tapMap(sender: UITapGestureRecognizer) {

        if let message = message {
            tapMapAction?(message: message)
        }
    }
}

