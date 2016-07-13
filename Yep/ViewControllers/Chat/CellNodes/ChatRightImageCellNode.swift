//
//  ChatRightImageCellNode.swift
//  Yep
//
//  Created by NIX on 16/7/6.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import AsyncDisplayKit

class ChatRightImageCellNode: ChatRightBaseCellNode {

    var tapImageAction: ((node: Previewable) -> Void)?

    private let imagePreferredWidth = YepConfig.ChatCell.mediaPreferredWidth
    private let imagePreferredHeight = YepConfig.ChatCell.mediaPreferredHeight
    private let imagePreferredAspectRatio: CGFloat = 4.0 / 3.0

    lazy var imageNode: ASImageNode = {
        let node = ASImageNode()
        node.contentMode = .ScaleAspectFill

        let tapAvatar = UITapGestureRecognizer(target: self, action: #selector(ChatRightImageCellNode.tapImage(_:)))
        node.userInteractionEnabled = true
        node.view.addGestureRecognizer(tapAvatar)

        return node
    }()

    override init() {
        super.init()

        addSubnode(imageNode)
    }

    private var imageSize: CGSize?

    func configure(withMessage message: Message) {

        self.user = message.fromFriend

        do {
            let imageSize = message.fixedImageSize

            self.imageSize = imageSize

            imageNode.yep_setImageOfMessage(message, withSize: imageSize, tailDirection: .Right, completion: { [weak self] loadingProgress, image in
                self?.imageNode.image = image
            })
        }
    }

    override func calculateSizeThatFits(constrainedSize: CGSize) -> CGSize {

        let height = max(imageSize?.height ?? 0, ChatBaseCellNode.avatarSize.height)

        return CGSize(width: constrainedSize.width, height: height + ChatBaseCellNode.topPadding + ChatBaseCellNode.bottomPadding)
    }

    override func layout() {
        super.layout()

        let size = self.imageSize ?? CGSize(width: 40, height: 40)
        let x = calculatedSize.width - (size.width + 5 + ChatBaseCellNode.avatarSize.width + 15)
        let y = ChatBaseCellNode.topPadding
        let origin = CGPoint(x: x, y: y)
        imageNode.frame = CGRect(origin: origin, size: size)
    }

    // MARK: Selctors

    @objc private func tapImage(sender: UITapGestureRecognizer) {

        tapImageAction?(node: self)
    }
}

