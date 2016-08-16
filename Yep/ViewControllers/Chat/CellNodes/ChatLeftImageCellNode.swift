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

    var tapImageAction: ((node: Previewable) -> Void)?

    private let imagePreferredWidth = YepConfig.ChatCell.mediaPreferredWidth
    private let imagePreferredHeight = YepConfig.ChatCell.mediaPreferredHeight
    private let imagePreferredAspectRatio: CGFloat = 4.0 / 3.0

    private lazy var imageMaskView: UIView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "left_tail_image_bubble")
        return imageView
    }()

    lazy var imageNode: ASImageNode = {
        let node = ASImageNode()
        node.contentMode = .ScaleAspectFill

        node.view.maskView = self.imageMaskView

        let tapAvatar = UITapGestureRecognizer(target: self, action: #selector(ChatLeftImageCellNode.tapImage(_:)))
        node.userInteractionEnabled = true
        node.view.addGestureRecognizer(tapAvatar)
        
        return node
    }()

    private lazy var borderNode: ASImageNode = {
        let node = ASImageNode()
        node.contentMode = .ScaleAspectFill
        let image = UIImage(named: "left_tail_image_bubble_border")?.resizableImageWithCapInsets(UIEdgeInsets(top: 25, left: 27, bottom: 20, right: 20), resizingMode: .Stretch)
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

            imageNode.yep_setImageOfMessage(message, withSize: imageSize, tailDirection: .Left, completion: { [weak self] loadingProgress, image in
                self?.imageNode.image = image
            })
        }
    }

    override func calculateSizeThatFits(constrainedSize: CGSize) -> CGSize {

        let height = max(imageSize?.height ?? 0, ChatBaseCellNode.avatarSize.height)

        return CGSize(width: constrainedSize.width, height: height + ChatBaseCellNode.verticalPadding)
    }

    override func layout() {
        super.layout()

        let x = 15 + ChatBaseCellNode.avatarSize.width + 5
        let y = ChatBaseCellNode.topPadding
        let origin = CGPoint(x: x, y: y)
        var size = self.imageSize ?? CGSize(width: 40, height: 40)
        size.width = min(size.width, YepConfig.ChatCell.imageMaxWidth)
        imageNode.frame = CGRect(origin: origin, size: size)

        imageMaskView.frame = imageNode.bounds

        borderNode.frame = imageNode.frame
    }

    // MARK: Selectors

    @objc private func tapImage(sender: UITapGestureRecognizer) {

        tapImageAction?(node: self)
    }
}

