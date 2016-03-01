//
//  FeedBiggerImageCell.swift
//  Yep
//
//  Created by nixzhu on 15/12/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedBiggerImageCell: FeedBasicCell {

    var tapMediaAction: FeedTapMediaAction?

    lazy var biggerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
        imageView.frame = CGRect(origin: CGPoint(x: 65, y: 0), size: YepConfig.FeedBiggerImageCell.imageSize)
        imageView.layer.borderColor = UIColor.yepBorderColor().CGColor
        imageView.layer.borderWidth = 1.0 / UIScreen.mainScreen().scale

        imageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tap:")
        imageView.addGestureRecognizer(tap)

        return imageView
    }()

    override class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + YepConfig.FeedBiggerImageCell.imageSize.height + 15

        return ceil(height)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(biggerImageView)
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

        biggerImageView.image = nil
    }

    override func configureWithFeed(feed: DiscoveredFeed, layoutCache: FeedCellLayout.Cache, needShowSkill: Bool) {

        var _newLayout: FeedCellLayout?
        super.configureWithFeed(feed, layoutCache: (layout: layoutCache.layout, update: { newLayout in
            _newLayout = newLayout
        }), needShowSkill: needShowSkill)

        if let biggerImageLayout = layoutCache.layout?.biggerImageLayout {
            biggerImageView.frame = biggerImageLayout.biggerImageViewFrame

        } else {
            biggerImageView.frame.origin.y = messageTextView.frame.origin.y + messageTextView.frame.height + 15
        }

        if let onlyAttachment = feed.imageAttachments?.first {

            if onlyAttachment.isTemporary {
                biggerImageView.image = onlyAttachment.image

            } else {
                biggerImageView.yep_showActivityIndicatorWhenLoading = true
                biggerImageView.yep_setImageOfAttachment(onlyAttachment, withSize: YepConfig.FeedBiggerImageCell.imageSize)
            }
        }

        if layoutCache.layout == nil {

            let biggerImageLayout = FeedCellLayout.BiggerImageLayout(biggerImageViewFrame: biggerImageView.frame)
            _newLayout?.biggerImageLayout = biggerImageLayout

            if let newLayout = _newLayout {
                layoutCache.update(layout: newLayout)
            }
        }
    }

    @objc private func tap(sender: UITapGestureRecognizer) {

        guard let firstAttachment = feed?.imageAttachments?.first where !firstAttachment.isTemporary else {
            return
        }

        if let attachments = feed?.imageAttachments {
            tapMediaAction?(transitionView: biggerImageView, image: biggerImageView.image, attachments: attachments, index: 0)
        }
    }
}

