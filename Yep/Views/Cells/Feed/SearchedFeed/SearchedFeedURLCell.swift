//
//  SearchedFeedURLCell.swift
//  Yep
//
//  Created by NIX on 16/4/19.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class SearchedFeedURLCell: SearchedFeedBasicCell {

    override class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + (10 + 20)

        return ceil(height)
    }

    var tapURLInfoAction: ((URL: NSURL) -> Void)?

    lazy var feedURLContainerView: IconTitleContainerView = {
        let view = IconTitleContainerView(frame: CGRect(x: 0, y: 0, width: 200, height: 150))
        return view
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(feedURLContainerView)

        feedURLContainerView.iconImageView.image = UIImage.yep_iconLink
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureWithFeed(feed: DiscoveredFeed, layout: SearchedFeedCellLayout, keyword: String?) {

        super.configureWithFeed(feed, layout: layout, keyword: keyword)

        if let attachment = feed.attachment {
            if case let .URL(openGraphInfo) = attachment {

                feedURLContainerView.titleLabel.text = openGraphInfo.title

                feedURLContainerView.tapAction = { [weak self] in
                    self?.tapURLInfoAction?(URL: openGraphInfo.URL)
                }
            }
        }

        let _URLLayout = layout._URLLayout!
        feedURLContainerView.frame = _URLLayout.URLContainerViewFrame
    }
}

