//
//  EdgeBorderButton.swift
//  Yep
//
//  Created by nixzhu on 15/9/23.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class EdgeBorderButton: UIButton {

    let lineColor: UIColor = UIColor.yepBorderColor()
    let lineWidth: CGFloat = 1

    lazy var topLineLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = self.lineWidth
        layer.strokeColor = self.lineColor.CGColor
        return layer
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        backgroundColor = UIColor.whiteColor()

        layer.addSublayer(topLineLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let topPath = UIBezierPath()
        topPath.moveToPoint(CGPoint(x: 0, y: 0.5))
        topPath.addLineToPoint(CGPoint(x: CGRectGetWidth(bounds), y: 0.5))

        topLineLayer.path = topPath.CGPath
    }
}

