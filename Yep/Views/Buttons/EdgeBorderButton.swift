//
//  EdgeBorderButton.swift
//  Yep
//
//  Created by nixzhu on 15/9/23.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class EdgeBorderButton: UIButton {

    let lineColor: UIColor = UIColor.yepBorderColor()
    let lineWidth: CGFloat = 1

    lazy var topLineLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = self.lineWidth
        layer.strokeColor = self.lineColor.cgColor
        return layer
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        backgroundColor = UIColor.white

        layer.addSublayer(topLineLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let topPath = UIBezierPath()
        topPath.move(to: CGPoint(x: 0, y: 0.5))
        topPath.addLine(to: CGPoint(x: bounds.width, y: 0.5))

        topLineLayer.path = topPath.cgPath
    }
}

