//
//  MessageLoadingProgressView.swift
//  Yep
//
//  Created by NIX on 15/6/29.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class MessageLoadingProgressView: UIView {

    var progress: Double = 0.7

    override func drawRect(rect: CGRect) {

        let center = CGPoint(x: CGRectGetMidX(rect), y: CGRectGetMidY(rect))
        let lineWidth: CGFloat = 6
        let radius = min(rect.width, rect.height) * 0.5 - lineWidth * 0.5
        
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: CGFloat(-M_PI_2), endAngle: CGFloat(M_PI * 2 * progress - M_PI_2), clockwise: true)
        path.lineWidth = lineWidth
        path.lineCapStyle = kCGLineCapRound

        UIColor.redColor().setStroke()

        path.stroke()
    }
}
