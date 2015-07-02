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

    enum Badge: String {
        case Palette = "palette"
        case Plane = "plane"
        case Heart = "heart"
        case Star = "star"
        case Bubble = "bubble"

        case Android = "android"
        case Apple = "apple"
        case Pet = "pet"
        case Wine = "wine"
        case Music = "music"

        case Steve = "steve"
        case Camera = "camera"
        case Game = "game"
        case Ball = "ball"
        case Tech = "tech"
    }

    //@IBInspectable
    var badge: Badge = .Heart {
        willSet {
            if let badgeImage = UIImage(named: "badge_" + newValue.rawValue) {
                badgeImageView.image = badgeImage
            }
        }
    }

    var enabled: Bool = false {
        willSet {
            //backgroundView.backgroundColor = newValue ? UIColor.yepTintColor() : UIColor.clearColor()

            UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
                self.badgeImageView.tintColor = newValue ? UIColor.whiteColor() : UIColor.yepTintColor()
            }, completion: { finished in
            })
        }
    }

    var tapAction: ((BadgeView) -> Void)?

//    lazy var backgroundView: UIView = {
//        let view = UIView()
//        return view
//        }()

    lazy var badgeImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
        }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        let tap = UITapGestureRecognizer(target: self, action: "tap")
        addGestureRecognizer(tap)
    }

    func makeUI() {

        //addSubview(backgroundView)
        addSubview(badgeImageView)

        //backgroundView.setTranslatesAutoresizingMaskIntoConstraints(false)
        badgeImageView.setTranslatesAutoresizingMaskIntoConstraints(false)

//        let viewsDictionary = [
//            "backgroundView": backgroundView,
//            "badgeImageView": badgeImageView,
//        ]
//
//        let backgroundViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[backgroundView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)
//        let backgroundViewConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[backgroundView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)
//
//        NSLayoutConstraint.activateConstraints(backgroundViewConstraintsH)
//        NSLayoutConstraint.activateConstraints(backgroundViewConstraintsV)

        let iconConstraintCenterX = NSLayoutConstraint(item: badgeImageView, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0)
        let iconConstraintCenterY = NSLayoutConstraint(item: badgeImageView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0)

        NSLayoutConstraint.activateConstraints([iconConstraintCenterX, iconConstraintCenterY])
    }

    func tap() {
        tapAction?(self)
    }
}
