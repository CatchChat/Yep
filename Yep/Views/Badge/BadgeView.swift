//
//  BadgeView.swift
//  Yep
//
//  Created by NIX on 15/7/2.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

//@IBDesignable
class BadgeView: UIView {

    //@IBInspectable
    var badgeName: String = "tech" {
        willSet {
            if let badgeImage = UIImage(named: "icon_skill_" + newValue) {
                badge.image = badgeImage
            }
        }
    }

    lazy var backgroundView: UIView = {
        let view = UIView()
        return view
        }()

    lazy var badge: UIImageView = {
        let imageView = UIImageView()
        return imageView
        }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    func makeUI() {

        addSubview(backgroundView)
        addSubview(badge)

        backgroundView.setTranslatesAutoresizingMaskIntoConstraints(false)
        badge.setTranslatesAutoresizingMaskIntoConstraints(false)

        let viewsDictionary = [
            "backgroundView": backgroundView,
            "badge": badge,
        ]

        let backgroundViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[backgroundView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)
        let backgroundViewConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[backgroundView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(backgroundViewConstraintsH)
        NSLayoutConstraint.activateConstraints(backgroundViewConstraintsV)

        let iconConstraintCenterX = NSLayoutConstraint(item: badge, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0)
        let iconConstraintCenterY = NSLayoutConstraint(item: badge, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0)

        NSLayoutConstraint.activateConstraints([iconConstraintCenterX, iconConstraintCenterY])
    }
}
