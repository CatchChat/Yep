//
//  ProfileFeedsCell.swift
//  Yep
//
//  Created by nixzhu on 15/11/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ProfileFeedsCell: UICollectionViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var iconImageViewLeadingConstraint: NSLayoutConstraint!

    @IBOutlet weak var nameLabel: UILabel!

    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var imageView4: UIImageView!

    @IBOutlet weak var accessoryImageView: UIImageView!
    @IBOutlet weak var accessoryImageViewTrailingConstraint: NSLayoutConstraint!

    var feedAttachments: [DiscoveredAttachment]? {
        willSet {
            guard let attachments = newValue else {
                return
            }

            if let attachment = attachments[safe: 0] {
                imageView1.image = attachment.thumbnailImage
            } else {
                imageView1.image = nil
            }

            if let attachment = attachments[safe: 1] {
                imageView2.image = attachment.thumbnailImage
            } else {
                imageView2.image = nil
            }

            if let attachment = attachments[safe: 2] {
                imageView3.image = attachment.thumbnailImage
            } else {
                imageView3.image = nil
            }

            if let attachment = attachments[safe: 3] {
                imageView4.image = attachment.thumbnailImage
            } else {
                imageView4.image = nil
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        nameLabel.text = NSLocalizedString("Feeds", comment: "")
        nameLabel.textColor = UIColor.yepTintColor()

        accessoryImageView.tintColor = UIColor.yepCellAccessoryImageViewTintColor()
        iconImageViewLeadingConstraint.constant = YepConfig.Profile.leftEdgeInset
        accessoryImageViewTrailingConstraint.constant = YepConfig.Profile.rightEdgeInset

        imageView1.contentMode = .ScaleAspectFill
        imageView2.contentMode = .ScaleAspectFill
        imageView3.contentMode = .ScaleAspectFill
        imageView4.contentMode = .ScaleAspectFill

        let cornerRadius: CGFloat = 2
        imageView1.layer.cornerRadius = cornerRadius
        imageView2.layer.cornerRadius = cornerRadius
        imageView3.layer.cornerRadius = cornerRadius
        imageView4.layer.cornerRadius = cornerRadius

        imageView1.clipsToBounds = true
        imageView2.clipsToBounds = true
        imageView3.clipsToBounds = true
        imageView4.clipsToBounds = true
    }

    func configureWithProfileUser(profileUser: ProfileUser?, feedAttachments: [DiscoveredAttachment]?, completion: ((feeds: [DiscoveredFeed], feedAttachments: [DiscoveredAttachment]) -> Void)?) {

        if let feedAttachments = feedAttachments {
            self.feedAttachments = feedAttachments

        } else {
            guard let profileUser = profileUser else {
                return
            }

            feedsOfUser(profileUser.userID, pageIndex: 1, perPage: 10, failureHandler: nil, completion: { feeds in
                println("user's feeds: \(feeds.count)")

                let feedAttachments = feeds.map({ $0.attachments.first }).flatMap({ $0 })

                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    self?.feedAttachments = feedAttachments

                    completion?(feeds: feeds, feedAttachments: feedAttachments)
                }
            })
        }
    }
}

