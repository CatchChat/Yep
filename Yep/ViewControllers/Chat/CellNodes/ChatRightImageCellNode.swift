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

    private lazy var imageMaskView: UIView = {
        let imageView = UIImageView()
        imageView.image = UIImage.yep_rightTailImageBubble
        return imageView
    }()

    lazy var imageNode: ASImageNode = {
        let node = ASImageNode()
        node.contentMode = .ScaleAspectFill

        node.view.maskView = self.imageMaskView

        let tapAvatar = UITapGestureRecognizer(target: self, action: #selector(ChatRightImageCellNode.tapImage(_:)))
        node.userInteractionEnabled = true
        node.view.addGestureRecognizer(tapAvatar)

        return node
    }()

    private lazy var borderNode: ASImageNode = {
        let node = ASImageNode()
        node.contentMode = .ScaleAspectFill
        let image = UIImage(named: "right_tail_image_bubble_border")?.resizableImageWithCapInsets(UIEdgeInsets(top: 24, left: 20, bottom: 20, right: 27), resizingMode: .Stretch)
        node.image = image
        return node
    }()

    override init() {
        super.init()

        addSubnode(imageNode)
        addSubnode(borderNode)
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

        var size = self.imageSize ?? CGSize(width: 40, height: 40)
        size.width = min(size.width, YepConfig.ChatCell.imageMaxWidth)
        let x = calculatedSize.width - (size.width + 5 + ChatBaseCellNode.avatarSize.width + 15)
        let y = ChatBaseCellNode.topPadding
        let origin = CGPoint(x: x, y: y)
        imageNode.frame = CGRect(origin: origin, size: size)

        imageMaskView.frame = imageNode.bounds

        borderNode.frame = imageNode.frame
    }

    // MARK: Selctors

    @objc private func tapImage(sender: UITapGestureRecognizer) {

        tapImageAction?(node: self)
    }
}

