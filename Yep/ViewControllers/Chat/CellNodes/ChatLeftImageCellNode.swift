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

    lazy var imageNode: ASImageNode = {
        let node = ASImageNode()
        node.contentMode = .ScaleAspectFill
        return node
    }()

    override init() {
        super.init()

        addSubnode(imageNode)
        imageNode.backgroundColor = UIColor.cyanColor()
    }

    var imageSize: CGSize?

    func configure(withMessage message: Message, messageImagePreferredWidth: CGFloat, messageImagePreferredHeight: CGFloat, messageImagePreferredAspectRatio: CGFloat) {

        self.user = message.fromFriend

        if let (imageWidth, imageHeight) = imageMetaOfMessage(message) {
            let aspectRatio = imageWidth / imageHeight

            let messageImagePreferredWidth = max(messageImagePreferredWidth, ceil(YepConfig.ChatCell.mediaMinHeight * aspectRatio))
            let messageImagePreferredHeight = max(messageImagePreferredHeight, ceil(YepConfig.ChatCell.mediaMinWidth / aspectRatio))

            if aspectRatio >= 1 {

                let width = min(messageImagePreferredWidth, YepConfig.ChatCell.imageMaxWidth)
                var size = CGSize(width: messageImagePreferredWidth, height: ceil(messageImagePreferredWidth / aspectRatio))
                size = size.yep_ensureMinWidthOrHeight(YepConfig.ChatCell.mediaMinHeight)

                self.imageSize = size

                imageNode.yep_setImageOfMessage(message, withSize: size, tailDirection: .Left, completion: { [weak self] loadingProgress, image in
                    self?.imageNode.image = image
//                    SafeDispatch.async { [weak self] in
//                        self?.loadingWithProgress(loadingProgress, image: image)
//                    }
                })

            } else {
                var size = CGSize(width: messageImagePreferredHeight * aspectRatio, height: messageImagePreferredHeight)
                size = size.yep_ensureMinWidthOrHeight(YepConfig.ChatCell.mediaMinHeight)

                self.imageSize = size

                imageNode.yep_setImageOfMessage(message, withSize: size, tailDirection: .Left, completion: { [weak self] loadingProgress, image in
                    self?.imageNode.image = image
//                    SafeDispatch.async { [weak self] in
//                        self?.loadingWithProgress(loadingProgress, image: image)
//                    }
                })
            }

        } else {
            let size = CGSize(width: messageImagePreferredWidth, height: ceil(messageImagePreferredWidth / messageImagePreferredAspectRatio))

            self.imageSize = size

            imageNode.yep_setImageOfMessage(message, withSize: size, tailDirection: .Left, completion: { [weak self] loadingProgress, image in
                self?.imageNode.image = image
//                    SafeDispatch.async { [weak self] in
//                        self?.loadingWithProgress(loadingProgress, image: image)
//                    }
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

