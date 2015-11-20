//
//  FeedSocialWorkCell.swift
//  Yep
//
//  Created by nixzhu on 15/11/19.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedSocialWorkCell: FeedBasicCell {

    @IBOutlet weak var socialWorkContainerView: UIView!
    @IBOutlet weak var socialWorkImageView: UIImageView!
    @IBOutlet weak var githubRepoContainerView: UIView!
    @IBOutlet weak var githubRepoImageView: UIImageView!
    @IBOutlet weak var githubRepoNameLabel: UILabel!
    @IBOutlet weak var githubRepoDescriptionLabel: UILabel!

    static let messageTextViewMaxWidth: CGFloat = {
        let maxWidth = UIScreen.mainScreen().bounds.width - (15 + 40 + 10 + 60)
        return maxWidth
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let rect = feed.body.boundingRectWithSize(CGSize(width: FeedSocialWorkCell.messageTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedCell.textAttributes, context: nil)

        var height: CGFloat = ceil(rect.height) + 10 + 40 + 4 + 15 + 17 + 15
        switch feed.kind {
        case .GithubRepo:
            height += (80 + 15)
        case .DribbbleShot:
            height += (80 + 15)
        default:
            break
        }

        return ceil(height)
    }
}

