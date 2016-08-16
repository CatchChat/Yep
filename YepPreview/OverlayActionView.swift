//
//  OverlayActionView.swift
//  Yep
//
//  Created by NIX on 16/6/21.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class OverlayActionView: UIView {

    var shareAction: (() -> Void)?

    private lazy var shareButton: UIButton = {
        let button = UIButton()
        let image = UIImage(named: "icon_more_image")
        button.setImage(image, forState: .Normal)
        button.addTarget(self, action: #selector(OverlayActionView.share(_:)), forControlEvents: .TouchUpInside)
        return button
    }()

    override func drawRect(rect: CGRect) {

        let startColor: UIColor = UIColor.clearColor()
        let endColor: UIColor = UIColor.blackColor().colorWithAlphaComponent(0.2)

        let context = UIGraphicsGetCurrentContext()

        let colors = [startColor.CGColor, endColor.CGColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations: [CGFloat] = [0.0, 1.0]

        let gradient = CGGradientCreateWithColors(colorSpace, colors, colorLocations)

        let startPoint = CGPointZero
        let endPoint = CGPoint(x: 0, y: rect.height)

        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, CGGradientDrawingOptions(rawValue: 0))
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    private func makeUI() {

        addSubview(shareButton)
        shareButton.translatesAutoresizingMaskIntoConstraints = false

        do {
            let trailing = shareButton.trailingAnchor.constraintEqualToAnchor(self.trailingAnchor, constant: -30)
            let bottom = shareButton.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor, constant: -30)

            NSLayoutConstraint.activateConstraints([trailing, bottom])
        }
    }

    @objc private func share(sender: UIButton) {
        shareAction?()
    }
}

