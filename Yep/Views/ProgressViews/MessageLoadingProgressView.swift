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

    override func draw(_ rect: CGRect) {

        if progress <= 0 || progress == 1.0 {
            return
        }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let lineWidth: CGFloat = 4
        let radius = min(rect.width, rect.height) * 0.5 - lineWidth * 0.5

        /*
        let context = UIGraphicsGetCurrentContext()

        // base circle

        context!.saveGState()

        context!.beginPath()

        context!.setStrokeColor(UIColor.lightGray.withAlphaComponent(0.3).cgColor)
        context!.setLineWidth(lineWidth)

        CGContextAddArc(context!, center.x, center.y, radius, 0, CGFloat(M_PI * 2), 0)

        context!.drawPath(using: CGPathDrawingMode.stroke)

        context!.restoreGState()

        // progress arc

        context!.saveGState()

        context!.beginPath()

        context!.setStrokeColor(UIColor.white.cgColor)
        context!.setLineWidth(lineWidth)
        context!.setLineCap(CGLineCap.round)

        CGContextAddArc(context!, center.x, center.y, radius, CGFloat(-M_PI_2), CGFloat(M_PI * 2 * progress - M_PI_2), 0)

        context!.drawPath(using: CGPathDrawingMode.stroke)

        context!.restoreGState()
         */

        // base circle

        let baseCircle = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat(M_PI * 2), clockwise: true)
        baseCircle.lineWidth = lineWidth
        baseCircle.lineCapStyle = .round

        UIColor.lightGray.setStroke()

        baseCircle.stroke()

        // progress arc

        let progressArc = UIBezierPath(arcCenter: center, radius: radius, startAngle: CGFloat(-M_PI_2), endAngle: CGFloat(M_PI * 2 * progress - M_PI_2), clockwise: true)

        progressArc.lineWidth = lineWidth
        progressArc.lineCapStyle = .round

        UIColor.white.setStroke()

        progressArc.stroke()
    }
}

