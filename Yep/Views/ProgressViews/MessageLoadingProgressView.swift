//
//  MessageLoadingProgressView.swift
//  Yep
//
//  Created by NIX on 15/6/29.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class MessageLoadingProgressView: UIView {

    var progress: Double = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    override func drawRect(rect: CGRect) {

        let center = CGPoint(x: CGRectGetMidX(rect), y: CGRectGetMidY(rect))
        let lineWidth: CGFloat = 4
        let radius = min(rect.width, rect.height) * 0.5 - lineWidth * 0.5

        // base circle

        let baseCircle = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat(M_PI * 2), clockwise: true)
        baseCircle.lineWidth = lineWidth
        baseCircle.lineCapStyle = kCGLineCapRound

        UIColor.lightGrayColor().setStroke()

        baseCircle.stroke()

        // progress arc

        let progressArc = UIBezierPath(arcCenter: center, radius: radius, startAngle: CGFloat(-M_PI_2), endAngle: CGFloat(M_PI * 2 * progress - M_PI_2), clockwise: true)

        progressArc.lineWidth = lineWidth
        progressArc.lineCapStyle = kCGLineCapRound

        UIColor.whiteColor().setStroke()

        progressArc.stroke()
    }
}
