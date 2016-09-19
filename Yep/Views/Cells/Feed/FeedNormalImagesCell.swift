//
//  FeedNormalImagesCell.swift
//  Yep
//
//  Created by nixzhu on 15/12/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepPreview
import AsyncDisplayKit

final class FeedNormalImagesCell: FeedBasicCell {

    override class func heightOfFeed(_ feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + YepConfig.FeedNormalImagesCell.imageSize.height + 15
        return ceil(height)
    }

    var tapImagesAction: FeedTapImagesAction?

    fileprivate func createImageNode() -> ASImageNode {

        let node = ASImageNode()
        node.frame = CGRect(origin: CGPoint.zero, size: YepConfig.FeedNormalImagesCell.imageSize)
        node.contentMode = .scaleAspectFill
        node.backgroundColor = YepConfig.FeedMedia.backgroundColor
        node.borderWidth = 1
        node.borderColor = UIColor.yepBorderColor().cgColor

        node.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(FeedNormalImagesCell.tap(_:)))
        node.view.addGestureRecognizer(tap)

        return node
    }

    fileprivate lazy var imageNode1: ASImageNode = {
        return self.createImageNode()
    }()

    fileprivate lazy var imageNode2: ASImageNode = {
        return self.createImageNode()
    }()

    fileprivate lazy var imageNode3: ASImageNode = {
        return self.createImageNode()
    }()

    fileprivate lazy var imageNode4: ASImageNode = {
        return self.createImageNode()
    }()

    fileprivate var imageNodes: [ASImageNode] = []

    fileprivate let needAllImageNodes: Bool = FeedsViewController.feedNormalImagesCountThreshold == 4

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        if needAllImageNodes {
            imageNodes = [imageNode1, imageNode2, imageNode3, imageNode4]
        } else {
            imageNodes = [imageNode1, imageNode2, imageNode3]
        }

        imageNodes.forEach({
            contentView.addSubview($0.view)
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageNodes.forEach({ $0.image = nil })
    }

    override func configureWithFeed(_ feed: DiscoveredFeed, layout: FeedCellLayout, needShowSkill: Bool) {

        super.configureWithFeed(feed, layout: layout, needShowSkill: needShowSkill)

        if let attachments = feed.imageAttachments {
            for i in 0..<imageNodes.count {
                if let attachment = attachments[safe: i] {
                    if attachment.isTemporary {
                        imageNodes[i].image = attachment.image

                    } else {
                        imageNodes[i].yep_showActivityIndicatorWhenLoading = true
                        imageNodes[i].yep_setImageOfAttachment(attachment, withSize: YepConfig.FeedNormalImagesCell.imageSize)
                    }

                    imageNodes[i].isHidden = false

                } else {
                    imageNodes[i].isHidden = true
                }
            }
        }

        let normalImagesLayout = layout.normalImagesLayout!
        imageNode1.frame = normalImagesLayout.imageView1Frame
        imageNode2.frame = normalImagesLayout.imageView2Frame
        imageNode3.frame = normalImagesLayout.imageView3Frame
        if needAllImageNodes {
            imageNode4.frame = normalImagesLayout.imageView4Frame
        }
    }

    @objc fileprivate func tap(_ sender: UITapGestureRecognizer) {

        guard let attachments = feed?.imageAttachments else {
            return
        }

        guard let firstAttachment = attachments.first , !firstAttachment.isTemporary else {
            return
        }

        let views = imageNodes.map({ $0.view })
        guard let view = sender.view, let index = views.index(of: view) else {
            return
        }

        let transitionReferences: [Reference?] = imageNodes.map({
            Reference(view: $0.view, image: $0.image)
        })
        let image = imageNodes[index].image
        tapImagesAction?(transitionReferences: transitionReferences, attachments: attachments, image: image, index: index)
    }
}

