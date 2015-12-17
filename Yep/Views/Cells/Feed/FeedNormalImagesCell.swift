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
        imageView.frame = CGRect(origin: CGPoint(x: 65, y: 0), size: YepConfig.FeedNormalImagesCell.imageSize)
        imageView.frame = frame
        imageView.layer.borderColor = UIColor.yepBorderColor().CGColor
        imageView.layer.borderWidth = 1

        imageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tap:")
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
        let frame = CGRect(origin: CGPoint(x: 65, y: 0), size: YepConfig.FeedNormalImagesCell.imageSize)
        let imageView = self.createImageViewWithFrame(frame)

        return imageView
    }()

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

    override func configureWithFeed(feed: DiscoveredFeed, needShowSkill: Bool) {
        super.configureWithFeed(feed, needShowSkill: needShowSkill)

        if let attachments = feed.imageAttachments {

            for i in 0..<imageViews.count {

                if let attachment = attachments[safe: i] {
                    imageViews[i].yep_showActivityIndicatorWhenLoading = true
                    imageViews[i].yep_setImageOfAttachment(attachment, withSize: YepConfig.FeedNormalImagesCell.imageSize)

                    imageViews[i].frame.origin.y = messageTextView.frame.origin.y + messageTextView.frame.height + 15

                    imageViews[i].hidden = false

                } else {
                    imageViews[i].hidden = true
                }
            }
        }
    }

    @objc private func tap(sender: UITapGestureRecognizer) {

        if let imageView = sender.view as? UIImageView, index = imageViews.indexOf(imageView) {

            if let attachments = feed?.imageAttachments {
                tapMediaAction?(transitionView: imageView, image: imageView.image, attachments: attachments, index: index)
            }
        }
    }
}

