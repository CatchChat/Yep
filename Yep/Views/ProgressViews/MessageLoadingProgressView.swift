//
//  MessageLoadingProgressView.swift
//  Yep
//
//  Created by NIX on 15/6/29.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class MessageLoadingProgressView: UIView {

    var progress: Double = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    override func drawRect(rect: CGRect) {

        if progress <= 0 || progress == 1.0 {
            return
        }

        let center = CGPoint(x: CGRectGetMidX(rect), y: CGRectGetMidY(rect))
        let lineWidth: CGFloat = 4
        let radius = min(rect.width, rect.height) * 0.5 - lineWidth * 0.5

        let context = UIGraphicsGetCurrentContext()

        // base circle

        CGContextSaveGState(context)

        CGContextBeginPath(context)

        CGContextSetStrokeColorWithColor(context, UIColor.lightGrayColor().colorWithAlphaComponent(0.3).CGColor)
        CGContextSetLineWidth(context, lineWidth)

        CGContextAddArc(context, center.x, center.y, radius, 0, CGFloat(M_PI * 2), 0)

        CGContextDrawPath(context, CGPathDrawingMode.Stroke)

        CGContextRestoreGState(context)

        // progress arc

        CGContextSaveGState(context)

        CGContextBeginPath(context)

        CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().CGColor)
        CGContextSetLineWidth(context, lineWidth)
        CGContextSetLineCap(context, CGLineCap.Round)

        CGContextAddArc(context, center.x, center.y, radius, CGFloat(-M_PI_2), CGFloat(M_PI * 2 * progress - M_PI_2), 0)

        CGContextDrawPath(context, CGPathDrawingMode.Stroke)

        CGContextRestoreGState(context)

        /*
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
        */
    }
}
