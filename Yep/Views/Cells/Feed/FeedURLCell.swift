//
//  FeedURLCell.swift
//  Yep
//
//  Created by nixzhu on 16/1/14.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

private let screenWidth: CGFloat = UIScreen.mainScreen().bounds.width

class FeedURLCell: FeedBasicCell {

    lazy var feedURLContainerView: FeedURLContainerView = {
        let view = FeedURLContainerView()
        return view
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(feedURLContainerView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + (100 + 15)

        return ceil(height)
    }

    override func configureWithFeed(feed: DiscoveredFeed, layoutCache: FeedCellLayout.Cache, needShowSkill: Bool) {

        var _newLayout: FeedCellLayout?
        super.configureWithFeed(feed, layoutCache: (layout: layoutCache.layout, update: { newLayout in
            _newLayout = newLayout
        }), needShowSkill: needShowSkill)

        let y = messageTextView.frame.origin.y + messageTextView.frame.height + 15
        let height: CGFloat = leftBottomLabel.frame.origin.y - y - 15
        feedURLContainerView.frame = CGRect(x: 65, y: y, width: screenWidth - 65 - 60, height: height)
    }
}

