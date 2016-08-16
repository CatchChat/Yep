//
//  FeedLocationCell.swift
//  Yep
//
//  Created by nixzhu on 15/12/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import MapKit
import YepKit

final class FeedLocationCell: FeedBasicCell {

    override class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + (110 + 15)

        return ceil(height)
    }

    var tapLocationAction: ((locationName: String, locationCoordinate: CLLocationCoordinate2D) -> Void)?
    
    lazy var locationContainerView: FeedLocationContainerView = {
        let view = FeedLocationContainerView()
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        return view
    }()

    lazy var socialWorkBorderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.yep_socialWorkBorder
        return imageView
    }()

    lazy var halfMaskImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.yep_socialMediaImageMask)
        return imageView
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()

        locationContainerView.mapImageView.image = nil
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(locationContainerView)
        contentView.addSubview(socialWorkBorderImageView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureWithFeed(feed: DiscoveredFeed, layout: FeedCellLayout, needShowSkill: Bool) {

        super.configureWithFeed(feed, layout: layout, needShowSkill: needShowSkill)

        if let attachment = feed.attachment {
            if case let .Location(locationInfo) = attachment {

                let location = CLLocation(latitude: locationInfo.latitude, longitude: locationInfo.longitude)
                let size = CGSize(width: UIScreen.mainScreen().bounds.width - 65 - 60, height: 110 - locationContainerView.nameLabel.bounds.height)
                locationContainerView.mapImageView.yep_showActivityIndicatorWhenLoading = true
                locationContainerView.mapImageView.yep_setImageOfLocation(location, withSize: size)

                if locationInfo.name.isEmpty {
                    locationContainerView.nameLabel.text = NSLocalizedString("Unknown location", comment: "")

                } else {
                    locationContainerView.nameLabel.text = locationInfo.name
                }
            }
        }

        locationContainerView.mapImageView.maskView = halfMaskImageView

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
        socialWorkBorderImageView.frame = locationContainerView.frame

        locationContainerView.layoutIfNeeded()

        halfMaskImageView.frame = locationContainerView.mapImageView.bounds
        locationContainerView.mapImageView.maskView = halfMaskImageView
    }
}

