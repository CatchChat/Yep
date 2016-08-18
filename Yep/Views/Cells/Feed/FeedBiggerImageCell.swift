//
//  FeedBiggerImageCell.swift
//  Yep
//
//  Created by nixzhu on 15/12/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import AsyncDisplayKit

final class FeedBiggerImageCell: FeedBasicCell {

    override class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + YepConfig.FeedBiggerImageCell.imageSize.height + 15

        return ceil(height)
    }

    var tapImagesAction: FeedTapImagesAction?

    private func createImageNode() -> ASImageNode {

        let node = ASImageNode()
        node.frame = CGRect(origin: CGPointZero, size: YepConfig.FeedBiggerImageCell.imageSize)
        node.contentMode = .ScaleAspectFill
        node.backgroundColor = YepConfig.FeedMedia.backgroundColor
        node.borderWidth = 1
        node.borderColor = UIColor.yepBorderColor().CGColor

        node.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(FeedBiggerImageCell.tap(_:)))
        node.view.addGestureRecognizer(tap)

        return node
    }

    private lazy var imageNode: ASImageNode = {
        return self.createImageNode()
    }()

    /*
    lazy var biggerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
        imageView.frame = CGRect(origin: CGPoint(x: 65, y: 0), size: YepConfig.FeedBiggerImageCell.imageSize)
        imageView.layer.borderColor = UIColor.yepBorderColor().CGColor
        imageView.layer.borderWidth = 1.0 / UIScreen.mainScreen().scale

        imageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(FeedBiggerImageCell.tap(_:)))
        imageView.addGestureRecognizer(tap)

        return imageView
    }()
     */

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        //contentView.addSubview(biggerImageView)
        contentView.addSubview(imageNode.view)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        //biggerImageView.image = nil
        imageNode.image = nil
    }

    override func configureWithFeed(feed: DiscoveredFeed, layout: FeedCellLayout, needShowSkill: Bool) {

        super.configureWithFeed(feed, layout: layout, needShowSkill: needShowSkill)

        if let onlyAttachment = feed.imageAttachments?.first {

            if onlyAttachment.isTemporary {
                imageNode.image = onlyAttachment.image

            } else {
                imageNode.yep_showActivityIndicatorWhenLoading = true
                imageNode.yep_setImageOfAttachment(onlyAttachment, withSize: YepConfig.FeedBiggerImageCell.imageSize)
            }
        }

        let biggerImageLayout = layout.biggerImageLayout!
        imageNode.frame = biggerImageLayout.biggerImageViewFrame
    }

    @objc private func tap(sender: UITapGestureRecognizer) {

        guard let firstAttachment = feed?.imageAttachments?.first where !firstAttachment.isTemporary else {
            return
        }

        if let attachments = feed?.imageAttachments {
            tapImagesAction?(transitionViews: [imageNode.view], attachments: attachments, image: imageNode.image, index: 0)
        }
    }

    /*
    override func configureWithFeed(feed: DiscoveredFeed, layout: FeedCellLayout, needShowSkill: Bool) {

        super.configureWithFeed(feed, layout: layout, needShowSkill: needShowSkill)

        if let onlyAttachment = feed.imageAttachments?.first {

            if onlyAttachment.isTemporary {
                biggerImageView.image = onlyAttachment.image

            } else {
                biggerImageView.yep_showActivityIndicatorWhenLoading = true
                biggerImageView.yep_setImageOfAttachment(onlyAttachment, withSize: YepConfig.FeedBiggerImageCell.imageSize)
            }
        }

        let biggerImageLayout = layout.biggerImageLayout!
        biggerImageView.frame = biggerImageLayout.biggerImageViewFrame
    }

    @objc private func tap(sender: UITapGestureRecognizer) {

        guard let firstAttachment = feed?.imageAttachments?.first where !firstAttachment.isTemporary else {
            return
        }

        if let attachments = feed?.imageAttachments {
            tapImagesAction?(transitionViews: [biggerImageView], attachments: attachments, image: biggerImageView.image, index: 0)
        }
    }
     */
}

