//
//  FeedURLCell.swift
//  Yep
//
//  Created by nixzhu on 16/1/14.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class FeedURLCell: FeedBasicCell {

    override class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + (100 + 15)

        return ceil(height)
    }

    var tapURLInfoAction: ((URL: NSURL) -> Void)?

    lazy var feedURLContainerView: FeedURLContainerView = {
        let view = FeedURLContainerView(frame: CGRect(x: 0, y: 0, width: 200, height: 150))
        view.compressionMode = false
        return view
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(feedURLContainerView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureWithFeed(feed: DiscoveredFeed, layout: FeedCellLayout, needShowSkill: Bool) {

        super.configureWithFeed(feed, layout: layout, needShowSkill: needShowSkill)

        if let attachment = feed.attachment {
            if case let .URL(openGraphInfo) = attachment {

                feedURLContainerView.configureWithOpenGraphInfoType(openGraphInfo)

                feedURLContainerView.tapAction = { [weak self] in
                    self?.tapURLInfoAction?(URL: openGraphInfo.URL)
                }
            }
        }

        let _URLLayout = layout._URLLayout!
        feedURLContainerView.frame = _URLLayout.URLContainerViewFrame
    }
}

