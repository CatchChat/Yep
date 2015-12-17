//
//  FeedBiggerImageCell.swift
//  Yep
//
//  Created by nixzhu on 15/12/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedBiggerImageCell: FeedBasicCell {

    var tapMediaAction: ((transitionView: UIView, image: UIImage?, attachments: [DiscoveredAttachment], index: Int) -> Void)?

    lazy var biggerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
        imageView.frame = CGRect(origin: CGPoint(x: 65, y: 0), size: YepConfig.FeedBiggerImageCell.imageSize)
        imageView.layer.borderColor = UIColor.yepBorderColor().CGColor
        imageView.layer.borderWidth = 1
        return imageView
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(biggerImageView)

        biggerImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tap:")
        biggerImageView.addGestureRecognizer(tap)
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

    override func configureWithFeed(feed: DiscoveredFeed, needShowSkill: Bool) {
        super.configureWithFeed(feed, needShowSkill: needShowSkill)

        if let onlyAttachment = feed.imageAttachments?.first {
            biggerImageView.yep_showActivityIndicatorWhenLoading = true
            biggerImageView.yep_setImageOfAttachment(onlyAttachment, withSize: YepConfig.FeedBiggerImageCell.imageSize)

            biggerImageView.frame.origin.y = messageTextView.frame.origin.y + messageTextView.frame.height + 15
        }
    }

    @objc private func tap(sender: UITapGestureRecognizer) {

        if let attachments = feed?.imageAttachments {
            tapMediaAction?(transitionView: biggerImageView, image: biggerImageView.image, attachments: attachments, index: 0)
        }
    }
}

