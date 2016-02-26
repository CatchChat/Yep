//
//  FeedLocationContainerView.swift
//  Yep
//
//  Created by nixzhu on 15/12/16.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedLocationContainerView: UIView {

    var tapAction: (() -> Void)?

    lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "feed_container_background")
        return imageView
    }()

    lazy var mapImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        return imageView
    }()

    lazy var pinImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "icon_pin_shadow")
        return imageView
    }()

    lazy var horizontalLineView: HorizontalLineView = {
        let view = HorizontalLineView()
        view.atBottom = false
        view.backgroundColor = UIColor.whiteColor()
        return view
    }()

    var needCompressNameLabel: Bool = false
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.lightGrayColor()
        label.font = UIFont.systemFontOfSize(12)
        return label
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        let tap = UITapGestureRecognizer(target: self, action: "tap:")
        addGestureRecognizer(tap)
    }

    private func makeUI() {

        addSubview(backgroundImageView)
        addSubview(mapImageView)
        addSubview(pinImageView)
        addSubview(horizontalLineView)
        addSubview(nameLabel)

        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        mapImageView.translatesAutoresizingMaskIntoConstraints = false
        pinImageView.translatesAutoresizingMaskIntoConstraints = false
        horizontalLineView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "backgroundImageView": backgroundImageView,
            "mapImageView": mapImageView,
            "horizontalLineView": horizontalLineView,
            "nameLabel": nameLabel,
        ]

        let backgroundH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[backgroundImageView]|", options: [], metrics: nil, views: views)
        let backgroundV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[backgroundImageView]|", options: [], metrics: nil, views: views)
        NSLayoutConstraint.activateConstraints(backgroundH)
        NSLayoutConstraint.activateConstraints(backgroundV)

        let constraintsH1 = NSLayoutConstraint.constraintsWithVisualFormat("H:|[mapImageView]|", options: [], metrics: nil, views: views)
        let constraintsH2 = NSLayoutConstraint.constraintsWithVisualFormat("H:|[horizontalLineView]|", options: [], metrics: nil, views: views)
        let constraintsH3 = NSLayoutConstraint.constraintsWithVisualFormat("H:|-10-[nameLabel]-10-|", options: [], metrics: nil, views: views)

        let constraintsV: [NSLayoutConstraint]
        if needCompressNameLabel {
            constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[mapImageView][nameLabel(20)]|", options: [], metrics: nil, views: views)
        } else {
            constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[mapImageView][nameLabel(30)]|", options: [], metrics: nil, views: views)
        }

        let horizontalLineViewH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[horizontalLineView]|", options: [], metrics: nil, views: views)
        let horizontalLineViewV = NSLayoutConstraint.constraintsWithVisualFormat("V:[horizontalLineView(1)]", options: [], metrics: nil, views: views)
        let horizontalLineViewTop = NSLayoutConstraint(item: horizontalLineView, attribute: .Top, relatedBy: .Equal, toItem: nameLabel, attribute: .Top, multiplier: 1.0, constant: 0)

        let pinImageViewCenterX = NSLayoutConstraint(item: pinImageView, attribute: .CenterX, relatedBy: .Equal, toItem: mapImageView, attribute: .CenterX, multiplier: 1.0, constant: 0)
        let pinImageViewCenterY = NSLayoutConstraint(item: pinImageView, attribute: .CenterY, relatedBy: .Equal, toItem: mapImageView, attribute: .CenterY, multiplier: 1.0, constant: 0)

        NSLayoutConstraint.activateConstraints(constraintsH1)
        NSLayoutConstraint.activateConstraints(constraintsH2)
        NSLayoutConstraint.activateConstraints(constraintsH3)
        NSLayoutConstraint.activateConstraints(constraintsV)

        NSLayoutConstraint.activateConstraints(horizontalLineViewH)
        NSLayoutConstraint.activateConstraints(horizontalLineViewV)
        NSLayoutConstraint.activateConstraints([horizontalLineViewTop])

        NSLayoutConstraint.activateConstraints([pinImageViewCenterX, pinImageViewCenterY])
    }

    @objc private func tap(sender: UITapGestureRecognizer) {
        tapAction?()
    }
}

