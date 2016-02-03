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

        struct Color {
            static let red = UIColor(red: 1, green: 56/255.0, blue: 36/255.0, alpha: 1)
            static let green = UIColor(red:0.1, green:0.74, blue:0.61, alpha:1)
            static let blue = UIColor(red: 56/255.0, green: 166/255.0, blue: 249/255.0, alpha: 1)
            static let yellow = UIColor(red: 245/255.0, green: 166/255.0, blue: 35/255.0, alpha: 1)
            static let dark = UIColor(red: 52/255.0, green: 73/255.0, blue: 94/255.0, alpha: 1)
        }

        var color: UIColor {
            switch self {
            case .Palette:
                return Color.red
            case .Plane:
                return Color.blue
            case .Heart:
                return Color.red
            case .Star:
                return Color.yellow
            case .Bubble:
                return Color.dark

            case .Android:
                return Color.green
            case .Apple:
                return Color.dark
            case .Pet:
                return Color.yellow
            case .Wine:
                return Color.red
            case .Music:
                return Color.green

            case .Steve:
                return Color.blue
            case .Camera:
                return Color.green
            case .Game:
                return Color.dark
            case .Ball:
                return Color.blue
            case .Tech:
                return Color.blue
            }
        }

        var image: UIImage? {
            return UIImage(named: "badge_" + self.rawValue)
        }
    }

    //@IBInspectable
    var badge: Badge = .Heart {
        willSet {
            badgeImageView.image = newValue.image
            badgeImageView.tintColor = newValue.color
        }
    }

    var enabled: Bool = false {
        willSet {
            UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
                self.badgeImageView.tintColor = newValue ? UIColor.whiteColor() : self.badge.color
            }, completion: { finished in
            })
        }
    }

    var tapAction: ((BadgeView) -> Void)?

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

        addSubview(badgeImageView)

        badgeImageView.translatesAutoresizingMaskIntoConstraints = false

        let iconConstraintCenterX = NSLayoutConstraint(item: badgeImageView, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0)
        let iconConstraintCenterY = NSLayoutConstraint(item: badgeImageView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0)

        NSLayoutConstraint.activateConstraints([iconConstraintCenterX, iconConstraintCenterY])
    }

    func tap() {
        tapAction?(self)
    }
}
