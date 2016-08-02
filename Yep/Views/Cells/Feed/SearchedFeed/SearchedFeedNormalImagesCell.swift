//
//  SearchedFeedNormalImagesCell.swift
//  Yep
//
//  Created by NIX on 16/4/19.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class SearchedFeedNormalImagesCell: SearchedFeedBasicCell {

    override class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + (10 + YepConfig.SearchedFeedNormalImagesCell.imageSize.height)

        return ceil(height)
    }

    var tapImagesAction: FeedTapImagesAction?

    private func createImageViewWithFrame(frame: CGRect) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
        imageView.frame = CGRect(origin: CGPoint(x: 65, y: 0), size: YepConfig.FeedNormalImagesCell.imageSize)
        imageView.frame = frame
        imageView.layer.borderColor = UIColor.yepBorderColor().CGColor
        imageView.layer.borderWidth = 1.0 / UIScreen.mainScreen().scale

        imageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(SearchedFeedNormalImagesCell.tap(_:)))
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

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(imageView1)
        contentView.addSubview(imageView2)
        contentView.addSubview(imageView3)
        contentView.addSubview(imageView4)

        imageViews = [imageView1, imageView2, imageView3, imageView4]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageView1.image = nil
        imageView2.image = nil
        imageView3.image = nil
        imageView4.image = nil
    }

    override func configureWithFeed(feed: DiscoveredFeed, layout: SearchedFeedCellLayout, keyword: String?) {

        super.configureWithFeed(feed, layout: layout, keyword: keyword)

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

    // MARK: Actions

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
}

