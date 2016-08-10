//
//  SearchedFeedLocationCell.swift
//  Yep
//
//  Created by NIX on 16/4/19.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import MapKit
import YepKit

final class SearchedFeedLocationCell: SearchedFeedBasicCell {

    override class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + (10 + 20)

        return ceil(height)
    }

    var tapLocationAction: ((locationName: String, locationCoordinate: CLLocationCoordinate2D) -> Void)?

    lazy var locationContainerView: IconTitleContainerView = {
        let view = IconTitleContainerView()
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        return view
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(locationContainerView)

        locationContainerView.iconImageView.image = UIImage.yep_iconLocation
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureWithFeed(feed: DiscoveredFeed, layout: SearchedFeedCellLayout, keyword: String?) {

        super.configureWithFeed(feed, layout: layout, keyword: keyword)

        if let attachment = feed.attachment {
            if case let .Location(locationInfo) = attachment {

                if locationInfo.name.isEmpty {
                    locationContainerView.titleLabel.text = NSLocalizedString("Unknown location", comment: "")

                } else {
                    locationContainerView.titleLabel.text = locationInfo.name
                }
            }
        }

        locationContainerView.tapAction = { [weak self] in
            guard let attachment = feed.attachment else {
                return
            }

            if case .Location = feed.kind {
                if case let .Location(locationInfo) = attachment {
                    self?.tapLocationAction?(locationName: locationInfo.name, locationCoordinate: locationInfo.coordinate)
                }
            }
        }

        let locationLayout = layout.locationLayout!
        locationContainerView.frame = locationLayout.locationContainerViewFrame
    }
}

