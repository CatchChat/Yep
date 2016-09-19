//
//  BorderButton.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

@IBDesignable
final class BorderButton: UIButton {

    @IBInspectable var cornerRadius: CGFloat = 6
    @IBInspectable var borderColor: UIColor = UIColor.yepTintColor()
    @IBInspectable var borderWidth: CGFloat = 1

    override var isEnabled: Bool {
        willSet {
            let newBorderColor = newValue ? borderColor : UIColor(white: 0.8, alpha: 1.0)
            layer.borderColor = newBorderColor.cgColor
        }
    }

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
        let image = UIImage.yep_iconAccessoryMini
        let imageView = UIImageView(image: image)
        return imageView
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        layer.cornerRadius = cornerRadius
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    func showAccessory() {

        accessoryImageView.tintColor = borderColor

        addSubview(accessoryImageView)
        accessoryImageView.translatesAutoresizingMaskIntoConstraints = false

        let accessoryImageViewTrailing = NSLayoutConstraint(item: accessoryImageView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -10)
        let accessoryImageViewCenterY = NSLayoutConstraint(item: accessoryImageView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)

        NSLayoutConstraint.activate([accessoryImageViewTrailing, accessoryImageViewCenterY])
    }
}

