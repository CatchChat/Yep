//
//  FeedNormalImagesCell.swift
//  Yep
//
//  Created by nixzhu on 15/12/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import AsyncDisplayKit

final class FeedNormalImagesCell: FeedBasicCell {

    override class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + YepConfig.FeedNormalImagesCell.imageSize.height + 15

        return ceil(height)
    }

    var tapImagesAction: FeedTapImagesAction?

    private func createImageNode() -> ASImageNode {
        let node = ASImageNode()
        node.contentMode = .ScaleAspectFill
        node.backgroundColor = YepConfig.FeedMedia.backgroundColor
        node.borderWidth = 1
        node.borderColor = UIColor.yepBorderColor().CGColor
        return node
    }

    lazy var imageNode1: ASImageNode = {
        return self.createImageNode()
    }()

    lazy var imageNode2: ASImageNode = {
        return self.createImageNode()
    }()

    lazy var imageNode3: ASImageNode = {
        return self.createImageNode()
    }()

    lazy var imageNode4: ASImageNode = {
        return self.createImageNode()
    }()

    var imageNodes: [ASImageNode] = []

    /*
    private func createImageViewWithFrame(frame: CGRect) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
        imageView.frame = frame
        imageView.layer.borderColor = UIColor.yepBorderColor().CGColor
        imageView.layer.borderWidth = 1.0 / UIScreen.mainScreen().scale

        imageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(FeedNormalImagesCell.tap(_:)))
        imageView.addGestureRecognizer(tap)

        return imageView
    }

    lazy var imageView1: UIImageView = {
        let x = 65
        let frame = CGRect(origin: CGPoint(x: x, y: 0), size: YepConfig.FeedNormalImagesCell.imageSize)
        let imageView = self.createImageViewWithFrame(frame)

        return imageView
    }()

    lazy var imageView2: UIImageView = {
        let x = 65 + (YepConfig.FeedNormalImagesCell.imageSize.width + 5)
        let frame = CGRect(origin: CGPoint(x: x, y: 0), size: YepConfig.FeedNormalImagesCell.imageSize)
        let imageView = self.createImageViewWithFrame(frame)

        return imageView
    }()

    lazy var imageView3: UIImageView = {
        let x = 65 + (YepConfig.FeedNormalImagesCell.imageSize.width + 5) * 2
        let frame = CGRect(origin: CGPoint(x: x, y: 0), size: YepConfig.FeedNormalImagesCell.imageSize)
        let imageView = self.createImageViewWithFrame(frame)

        return imageView
    }()

    lazy var imageView4: UIImageView = {
        let x = 65 + (YepConfig.FeedNormalImagesCell.imageSize.width + 5) * 3
        let frame = CGRect(origin: CGPoint(x: x, y: 0), size: YepConfig.FeedNormalImagesCell.imageSize)
        let imageView = self.createImageViewWithFrame(frame)

        return imageView
    }()

    var imageViews: [UIImageView] = []
     */

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        /*
        contentView.addSubview(imageView1)
        contentView.addSubview(imageView2)
        contentView.addSubview(imageView3)
        contentView.addSubview(imageView4)

        imageViews = [imageView1, imageView2, imageView3, imageView4]
         */

        contentView.addSubview(imageNode1.view)
        contentView.addSubview(imageNode2.view)
        contentView.addSubview(imageNode3.view)
        contentView.addSubview(imageNode4.view)

        imageNodes = [imageNode1, imageNode2, imageNode3, imageNode4]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        /*
        imageView1.image = nil
        imageView2.image = nil
        imageView3.image = nil
        imageView4.image = nil
         */

        imageNodes.forEach({ $0.image = nil })
    }

    override func configureWithFeed(feed: DiscoveredFeed, layout: FeedCellLayout, needShowSkill: Bool) {

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

                    imageNodes[i].hidden = false

                } else {
                    imageNodes[i].hidden = true
                }
            }
        }

        let normalImagesLayout = layout.normalImagesLayout!
        imageNode1.frame = normalImagesLayout.imageView1Frame
        imageNode2.frame = normalImagesLayout.imageView2Frame
        imageNode3.frame = normalImagesLayout.imageView3Frame
        imageNode4.frame = normalImagesLayout.imageView4Frame
    }

    /*
    override func configureWithFeed(feed: DiscoveredFeed, layout: FeedCellLayout, needShowSkill: Bool) {

        super.configureWithFeed(feed, layout: layout, needShowSkill: needShowSkill)

        if let attachments = feed.imageAttachments {
            for i in 0..<imageViews.count {
                if let attachment = attachments[safe: i] {
                    if attachment.isTemporary {
                        imageViews[i].image = attachment.image

                    } else {
                        imageViews[i].yep_showActivityIndicatorWhenLoading = true
                        imageViews[i].yep_setImageOfAttachment(attachment, withSize: YepConfig.FeedNormalImagesCell.imageSize)
                    }

                    imageViews[i].hidden = false

                } else {
                    imageViews[i].hidden = true
                }
            }
        }

        let normalImagesLayout = layout.normalImagesLayout!
        imageView1.frame = normalImagesLayout.imageView1Frame
        imageView2.frame = normalImagesLayout.imageView2Frame
        imageView3.frame = normalImagesLayout.imageView3Frame
        imageView4.frame = normalImagesLayout.imageView4Frame
    }

    @objc private func tap(sender: UITapGestureRecognizer) {

        guard let firstAttachment = feed?.imageAttachments?.first where !firstAttachment.isTemporary else {
            return
        }
        
        if let imageView = sender.view as? UIImageView, index = imageViews.indexOf(imageView) {

            if let attachments = feed?.imageAttachments {
                let transitionViews: [UIView?] = imageViews.map({ $0 })
                tapImagesAction?(transitionViews: transitionViews, attachments: attachments, image: imageView.image, index: index)
            }
        }
    }
     */
}

