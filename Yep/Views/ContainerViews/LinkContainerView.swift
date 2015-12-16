//
//  LinkContainerView.swift
//  Yep
//
//  Created by nixzhu on 15/12/16.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class LinkContainerView: UIView {

    var tapAction: (() -> Void)?

    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "icon_link")
        imageView.tintColor = UIColor.yepIconImageViewTintColor()
        return imageView
    }()

    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.darkGrayColor()
        label.font = UIFont.systemFontOfSize(12)
        return label
    }()

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

        addSubview(iconImageView)
        addSubview(textLabel)
        addSubview(accessoryImageView)

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        accessoryImageView.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "iconImageView": iconImageView,
            "textLabel": textLabel,
            "accessoryImageView": accessoryImageView,
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-10-[iconImageView]-10-[textLabel]-5-[accessoryImageView]-10-|", options: [.AlignAllCenterY], metrics: nil, views: views)

        iconImageView.setContentHuggingPriority(UILayoutPriorityDefaultHigh, forAxis: .Horizontal)
        accessoryImageView.setContentHuggingPriority(UILayoutPriorityDefaultHigh, forAxis: .Horizontal)

        let iconImageViewCenterY = NSLayoutConstraint(item: iconImageView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints([iconImageViewCenterY])
    }

    @objc private func tap(sender: UITapGestureRecognizer) {
        tapAction?()
    }
}

