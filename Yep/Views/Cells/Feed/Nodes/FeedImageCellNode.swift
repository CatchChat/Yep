//
//  FeedImageCellNode.swift
//  Yep
//
//  Created by NIX on 16/8/18.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import YepKit
import YepPreview
import AsyncDisplayKit

class FeedImageCellNode: ASCellNode {

    lazy var imageNode: ASImageNode = {
        let node = ASImageNode()
        node.contentMode = .scaleAspectFill
        node.backgroundColor = YepConfig.FeedMedia.backgroundColor
        node.borderWidth = 1
        node.borderColor = UIColor.yepBorderColor().cgColor
        return node
    }()

    override init() {
        super.init()

        addSubnode(imageNode)
    }

    func configureWithAttachment(_ attachment: DiscoveredAttachment, imageSize: CGSize) {

        imageNode.frame = CGRect(origin: CGPoint.zero, size: imageSize)

        if attachment.isTemporary {
            imageNode.image = attachment.image

        } else {
            imageNode.yep_showActivityIndicatorWhenLoading = true
            imageNode.yep_setImageOfAttachment(attachment, withSize: imageSize)
        }
    }
}

extension FeedImageCellNode: Previewable {

    var transitionReference: Reference {
        return Reference(view: imageNode.view, image: imageNode.image)
    }
}

