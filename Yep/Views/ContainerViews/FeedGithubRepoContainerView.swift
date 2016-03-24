//
//  FeedGithubRepoContainerView.swift
//  Yep
//
//  Created by nixzhu on 15/12/16.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedGithubRepoContainerView: UIView {

    var tapAction: (() -> Void)?

    lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "feed_container_background")
        return imageView
    }()

    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "icon_repo")
        imageView.tintColor = UIColor.yepIconImageViewTintColor()
        return imageView
    }()

    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.blackColor()
        label.font = UIFont.systemFontOfSize(16)
        return label
    }()

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.lightGrayColor()
        label.font = UIFont.systemFontOfSize(12)
        label.numberOfLines = 2
        return label
    }()

    var needShowAccessoryImageView: Bool = true
    lazy var accessoryImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "icon_accessory_mini")
        imageView.tintColor = UIColor.yepCellAccessoryImageViewTintColor()
        return imageView
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        let tap = UITapGestureRecognizer(target: self, action: "tap:")
        addGestureRecognizer(tap)
    }

    private func makeUI() {

        backgroundColor = UIColor.whiteColor()
        tintAdjustmentMode = .Normal

        addSubview(backgroundImageView)
        addSubview(iconImageView)
        addSubview(nameLabel)
        addSubview(descriptionLabel)
        addSubview(accessoryImageView)

        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        accessoryImageView.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "backgroundImageView": backgroundImageView,
            "iconImageView": iconImageView,
            "nameLabel": nameLabel,
            "descriptionLabel": descriptionLabel,
            "accessoryImageView": accessoryImageView,
        ]

        let backgroundH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[backgroundImageView]|", options: [], metrics: nil, views: views)
        let backgroundV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[backgroundImageView]|", options: [], metrics: nil, views: views)
        NSLayoutConstraint.activateConstraints(backgroundH)
        NSLayoutConstraint.activateConstraints(backgroundV)

        let constraintsH: [NSLayoutConstraint]
        if needShowAccessoryImageView {
            constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-10-[iconImageView(16)]-10-[nameLabel]-5-[accessoryImageView(8)]-10-|", options: [], metrics: nil, views: views)
        } else {
            accessoryImageView.hidden = true
            constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-10-[iconImageView(16)]-10-[nameLabel]-10-|", options: [], metrics: nil, views: views)
        }

        iconImageView.setContentHuggingPriority(UILayoutPriorityDefaultHigh, forAxis: .Horizontal)
        accessoryImageView.setContentHuggingPriority(UILayoutPriorityDefaultHigh, forAxis: .Horizontal)

        iconImageView.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, forAxis: .Horizontal)
        accessoryImageView.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, forAxis: .Horizontal)

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:[nameLabel]-3-[descriptionLabel]", options: [.AlignAllLeading, .AlignAllTrailing], metrics: nil, views: views)

        let iconImageViewCenterY = NSLayoutConstraint(item: iconImageView, attribute: .CenterY, relatedBy: .Equal, toItem: nameLabel, attribute: .CenterY, multiplier: 1.0, constant: 0)
        let accessoryImageViewCenterY = NSLayoutConstraint(item: accessoryImageView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0)

        let helperView = UIView()
        addSubview(helperView)
        helperView.translatesAutoresizingMaskIntoConstraints = false

        let helperViewCenterY = NSLayoutConstraint(item: helperView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0)
        let helperViewTop = NSLayoutConstraint(item: helperView, attribute: .Top, relatedBy: .Equal, toItem: nameLabel, attribute: .Top, multiplier: 1.0, constant: 0)
        let helperViewBottom = NSLayoutConstraint(item: helperView, attribute: .Bottom, relatedBy: .Equal, toItem: descriptionLabel, attribute: .Bottom, multiplier: 1.0, constant: 0)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints(constraintsV)
        NSLayoutConstraint.activateConstraints([iconImageViewCenterY, accessoryImageViewCenterY])
        NSLayoutConstraint.activateConstraints([helperViewCenterY, helperViewTop, helperViewBottom])
    }

    @objc private func tap(sender: UITapGestureRecognizer) {
        tapAction?()
    }
}

