//
//  BadgeView.swift
//  Yep
//
//  Created by NIX on 15/7/2.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

//@IBDesignable
final class BadgeView: UIView {

    enum Badge: String {
        case palette = "palette"
        case plane = "plane"
        case heart = "heart"
        case star = "star"
        case bubble = "bubble"

        case android = "android"
        case apple = "apple"
        case pet = "pet"
        case wine = "wine"
        case music = "music"

        case steve = "steve"
        case camera = "camera"
        case game = "game"
        case ball = "ball"
        case tech = "tech"

        struct Color {
            static let red = UIColor(red: 1, green: 56/255.0, blue: 36/255.0, alpha: 1)
            static let green = UIColor(red:0.1, green:0.74, blue:0.61, alpha:1)
            static let blue = UIColor(red: 56/255.0, green: 166/255.0, blue: 249/255.0, alpha: 1)
            static let yellow = UIColor(red: 245/255.0, green: 166/255.0, blue: 35/255.0, alpha: 1)
            static let dark = UIColor(red: 52/255.0, green: 73/255.0, blue: 94/255.0, alpha: 1)
        }

        var color: UIColor {
            switch self {
            case .palette:
                return Color.red
            case .plane:
                return Color.blue
            case .heart:
                return Color.red
            case .star:
                return Color.yellow
            case .bubble:
                return Color.dark

            case .android:
                return Color.green
            case .apple:
                return Color.dark
            case .pet:
                return Color.yellow
            case .wine:
                return Color.red
            case .music:
                return Color.green

            case .steve:
                return Color.blue
            case .camera:
                return Color.green
            case .game:
                return Color.dark
            case .ball:
                return Color.blue
            case .tech:
                return Color.blue
            }
        }

        var image: UIImage? {
            return UIImage.yep_badgeWithName(self.rawValue)
        }
    }

    //@IBInspectable
    var badge: Badge = .heart {
        willSet {
            badgeImageView.image = newValue.image
            badgeImageView.tintColor = newValue.color
        }
    }

    var enabled: Bool = false {
        willSet {
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.badgeImageView.tintColor = newValue ? UIColor.white : strongSelf.badge.color
            }, completion: nil)
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

        let tap = UITapGestureRecognizer(target: self, action: #selector(BadgeView.tap))
        addGestureRecognizer(tap)
    }

    func makeUI() {

        addSubview(badgeImageView)

        badgeImageView.translatesAutoresizingMaskIntoConstraints = false

        let iconConstraintCenterX = NSLayoutConstraint(item: badgeImageView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        let iconConstraintCenterY = NSLayoutConstraint(item: badgeImageView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)

        NSLayoutConstraint.activate([iconConstraintCenterX, iconConstraintCenterY])
    }

    func tap() {
        tapAction?(self)
    }
}
