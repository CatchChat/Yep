//
//  ChatLeftImageCellNode.swift
//  Yep
//
//  Created by NIX on 16/7/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import AsyncDisplayKit

class ChatLeftImageCellNode: ChatLeftBaseCellNode {

    var tapImageAction: ((imageNode: ChatLeftImageCellNode) -> Void)?

    let imagePreferredWidth = YepConfig.ChatCell.mediaPreferredWidth
    let imagePreferredHeight = YepConfig.ChatCell.mediaPreferredHeight
    let imagePreferredAspectRatio: CGFloat = 4.0 / 3.0

    lazy var imageNode: ASImageNode = {
        let node = ASImageNode()
        node.contentMode = .ScaleAspectFill

        let tapAvatar = UITapGestureRecognizer(target: self, action: #selector(ChatLeftImageCellNode.tapImage(_:)))
        node.userInteractionEnabled = true
        node.view.addGestureRecognizer(tapAvatar)
        
        return node
    }()

    @objc private func tapImage(sender: UITapGestureRecognizer) {
        tapImageAction?(imageNode: self)
    }

    override init() {
        super.init()

        addSubnode(imageNode)
        imageNode.backgroundColor = UIColor.cyanColor()
    }

    var imageSize: CGSize?

    func configure(withMessage message: Message) {

        self.user = message.fromFriend

        do {
            let imageSize = message.fixedImageSize

            self.imageSize = imageSize

            imageNode.yep_setImageOfMessage(message, withSize: imageSize, tailDirection: .Left, completion: { [weak self] loadingProgress, image in
                self?.imageNode.image = image
            })
        }
    }

    override func calculateSizeThatFits(constrainedSize: CGSize) -> CGSize {

        let height = max(imageSize?.height ?? 0, ChatBaseCellNode.avatarSize.height)

        return CGSize(width: constrainedSize.width, height: height)
    }

    override func layout() {
        super.layout()

        let x = 15 + ChatBaseCellNode.avatarSize.width + 5
        let y: CGFloat = 0
        let origin = CGPoint(x: x, y: y)
        let size = self.imageSize ?? CGSize(width: 40, height: 40)
        imageNode.frame = CGRect(origin: origin, size: size)
    }
}

