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

    private var enabled: Bool = false {
        willSet {
            if newValue {
                iconImageView.tintColor = UIColor.yepTintColor()
                nameLabel.textColor = UIColor.yepTintColor()
                accessoryImageView.hidden = false
                accessoryImageView.tintColor = UIColor.yepCellAccessoryImageViewTintColor()
            } else {
                iconImageView.tintColor = SocialAccount.disabledColor
                nameLabel.textColor = SocialAccount.disabledColor
                accessoryImageView.hidden = true
            }
        }
    }

    var feedAttachments: [DiscoveredAttachment?]? {
        willSet {
            guard let _attachments = newValue else {
                return
            }

            enabled = !_attachments.isEmpty

            // 对于从左到右排列，且左边的最新，要处理数量不足的情况

            var attachments = _attachments

            let imageViews = [
                imageView4,
                imageView3,
                imageView2,
                imageView1,
            ]

            let shortagesCount = max(imageViews.count - attachments.count, 0)

            // 不足补空
            if shortagesCount > 0 {
                let shortages = Array<DiscoveredAttachment?>(count: shortagesCount, repeatedValue: nil)
                attachments.insertContentsOf(shortages, at: 0)
            }

            for i in 0..<imageViews.count {
                if i < shortagesCount {
                    imageViews[i].image = nil
                } else {
                    if let thumbnailImage = attachments[i]?.thumbnailImage {
                        imageViews[i].image = thumbnailImage
                    } else {
                        imageViews[i].image = UIImage(named: "icon_feed_text")
                    }
                }
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        enabled = false

        nameLabel.text = NSLocalizedString("Feeds", comment: "")

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

    func configureWithProfileUser(profileUser: ProfileUser?, feedAttachments: [DiscoveredAttachment?]?, completion: ((feeds: [DiscoveredFeed], feedAttachments: [DiscoveredAttachment?]) -> Void)?) {

        if let feedAttachments = feedAttachments {
            self.feedAttachments = feedAttachments

        } else {
            guard let profileUser = profileUser else {
                return
            }

            feedsOfUser(profileUser.userID, pageIndex: 1, perPage: 20, failureHandler: nil, completion: { feeds in
                println("user's feeds: \(feeds.count)")

                let feedAttachments = feeds.map({ feed -> DiscoveredAttachment? in
                    if let attachment = feed.attachment {
                        if case let .Images(attachments) = attachment {
                            return attachments.first
                        }
                    }

                    return nil
                })

                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    self?.feedAttachments = feedAttachments

                    completion?(feeds: feeds, feedAttachments: feedAttachments)
                }
            })
        }
    }
}

