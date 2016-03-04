//
//  FeedNormalImagesCell.swift
//  Yep
//
//  Created by nixzhu on 15/12/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedNormalImagesCell: FeedBasicCell {

    var tapMediaAction: FeedTapMediaAction?

    private func createImageViewWithFrame(frame: CGRect) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
        imageView.frame = CGRect(origin: CGPoint(x: feedTextFixedSpace, y: 0), size: YepConfig.FeedNormalImagesCell.imageSize)
        imageView.frame = frame
        imageView.layer.borderColor = UIColor.yepBorderColor().CGColor
        imageView.layer.borderWidth = 1.0 / UIScreen.mainScreen().scale

        imageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tap:")
        imageView.addGestureRecognizer(tap)

        return imageView
    }

    lazy var imageView1: UIImageView = {
        let x = feedTextFixedSpace
        let frame = CGRect(origin: CGPoint(x: x, y: 0), size: YepConfig.FeedNormalImagesCell.imageSize)
        let imageView = self.createImageViewWithFrame(frame)

        return imageView
    }()

    lazy var imageView2: UIImageView = {
        let x = feedTextFixedSpace + (YepConfig.FeedNormalImagesCell.imageSize.width + 5)
        let frame = CGRect(origin: CGPoint(x: x, y: 0), size: YepConfig.FeedNormalImagesCell.imageSize)
        let imageView = self.createImageViewWithFrame(frame)

        return imageView
    }()

    lazy var imageView3: UIImageView = {
        let x = feedTextFixedSpace + (YepConfig.FeedNormalImagesCell.imageSize.width + 5) * 2
        let frame = CGRect(origin: CGPoint(x: x, y: 0), size: YepConfig.FeedNormalImagesCell.imageSize)
        let imageView = self.createImageViewWithFrame(frame)

        return imageView
    }()

    override class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + YepConfig.FeedNormalImagesCell.imageSize.height + 15

        return ceil(height)
    }
    
    var imageViews: [UIImageView] = []

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(imageView1)
        contentView.addSubview(imageView2)
        contentView.addSubview(imageView3)

        imageViews = [imageView1, imageView2, imageView3]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageView1.image = nil
        imageView2.image = nil
        imageView3.image = nil
    }

    override func configureWithFeed(feed: DiscoveredFeed, layoutCache: FeedCellLayout.Cache, needShowSkill: Bool) {

        var _newLayout: FeedCellLayout?
        super.configureWithFeed(feed, layoutCache: (layout: layoutCache.layout, update: { newLayout in
            _newLayout = newLayout
        }), needShowSkill: needShowSkill)

        if let normalImagesLayout = layoutCache.layout?.normalImagesLayout {
            imageView1.frame = normalImagesLayout.imageView1Frame
            imageView2.frame = normalImagesLayout.imageView2Frame
            imageView3.frame = normalImagesLayout.imageView3Frame

        } else {
            imageViews.forEach({
                $0.frame.origin.y = messageTextView.frame.origin.y + messageTextView.frame.height + 15
            })
        }

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

        if layoutCache.layout == nil {

            let normalImagesLayout = FeedCellLayout.NormalImagesLayout(imageView1Frame: imageView1.frame, imageView2Frame: imageView2.frame, imageView3Frame: imageView3.frame)
            _newLayout?.normalImagesLayout = normalImagesLayout

            if let newLayout = _newLayout {
                layoutCache.update(layout: newLayout)
            }
        }
    }

    @objc private func tap(sender: UITapGestureRecognizer) {

        guard let firstAttachment = feed?.imageAttachments?.first where !firstAttachment.isTemporary else {
            return
        }
        
        if let imageView = sender.view as? UIImageView, index = imageViews.indexOf(imageView) {

            if let attachments = feed?.imageAttachments {
                tapMediaAction?(transitionView: imageView, image: imageView.image, attachments: attachments, index: index)
            }
        }
    }
}

