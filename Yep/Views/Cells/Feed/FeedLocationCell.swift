//
//  FeedLocationCell.swift
//  Yep
//
//  Created by nixzhu on 15/12/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import MapKit

private let screenWidth: CGFloat = UIScreen.mainScreen().bounds.width

class FeedLocationCell: FeedBasicCell {

    var tapLocationAction: ((locationName: String, locationCoordinate: CLLocationCoordinate2D) -> Void)?
    
    lazy var locationContainerView: FeedLocationContainerView = {
        let view = FeedLocationContainerView()
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        return view
    }()

    lazy var socialWorkBorderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "social_work_border")
        return imageView
    }()

    lazy var halfMaskImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "social_media_image_mask"))
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

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + (110 + 15)

        return ceil(height)
    }

    override func configureWithFeed(feed: DiscoveredFeed, layoutCache: FeedCellLayout.Cache, needShowSkill: Bool) {

        var _newLayout: FeedCellLayout?
        super.configureWithFeed(feed, layoutCache: (layout: layoutCache.layout, update: { newLayout in
            _newLayout = newLayout
        }), needShowSkill: needShowSkill)


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

        if let locationLayout = layoutCache.layout?.locationLayout {
            locationContainerView.frame = locationLayout.locationContainerViewFrame
            socialWorkBorderImageView.frame = locationContainerView.frame

        } else {
            let y = messageTextView.frame.origin.y + messageTextView.frame.height + 15
            let height: CGFloat = leftBottomLabel.frame.origin.y - y - 15
            locationContainerView.frame = CGRect(x: 65, y: y, width: screenWidth - 65 - 60, height: height)
            socialWorkBorderImageView.frame = locationContainerView.frame
        }
        locationContainerView.layoutIfNeeded()

        halfMaskImageView.frame = locationContainerView.mapImageView.bounds
        locationContainerView.mapImageView.maskView = halfMaskImageView

        if layoutCache.layout == nil {

            let locationLayout = FeedCellLayout.LocationLayout(locationContainerViewFrame: locationContainerView.frame)
            _newLayout?.locationLayout = locationLayout

            if let newLayout = _newLayout {
                layoutCache.update(layout: newLayout)
            }
        }
    }
}
