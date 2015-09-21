//
//  BorderButton.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

@IBDesignable
class BorderButton: UIButton {

    @IBInspectable var cornerRadius: CGFloat = 6
    @IBInspectable var borderColor: UIColor = UIColor.yepTintColor()
    @IBInspectable var borderWidth: CGFloat = 1

    var needShowAccessory: Bool = false {
        willSet {
            if newValue != needShowAccessory {
                if newValue {
                    showAccessory()
                } else {
                    accessoryImageView.removeFromSuperview()
                }
            }
        }
    }

    lazy var accessoryImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "icon_accessory_mini"))
        return imageView
        }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        layer.cornerRadius = cornerRadius
        layer.borderColor = borderColor.CGColor
        layer.borderWidth = borderWidth
    }

    func showAccessory() {

        accessoryImageView.tintColor = borderColor

        addSubview(accessoryImageView)
        accessoryImageView.translatesAutoresizingMaskIntoConstraints = false

        let accessoryImageViewTrailing = NSLayoutConstraint(item: accessoryImageView, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: -10)
        let accessoryImageViewCenterY = NSLayoutConstraint(item: accessoryImageView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0)

        NSLayoutConstraint.activateConstraints([accessoryImageViewTrailing, accessoryImageViewCenterY])
    }

}
