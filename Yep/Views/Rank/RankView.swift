//
//  RankView.swift
//  Yep
//
//  Created by NIX on 15/3/18.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

@IBDesignable
class RankView: UIView {

    @IBInspectable var barNumber: Int = 4
    @IBInspectable var barColor: UIColor = UIColor.yepTintColor()
    @IBInspectable var barBackgroundColor: UIColor = UIColor(white: 0.0, alpha: 0.15)
    @IBInspectable var rank: Int = 2
    @IBInspectable var gap: CGFloat = 1

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        backgroundColor = UIColor.clearColor()
    }

    override func drawRect(rect: CGRect) {
        let barWidth = (rect.width - gap * (CGFloat(barNumber) - 1)) / CGFloat(barNumber)
        let barStepHeight = rect.height / CGFloat(barNumber)

        for i in 0..<barNumber {
            let bar = UIBezierPath()
            let barIndex = CGFloat(i)
            let x = barWidth * 0.5 + barWidth * barIndex + gap * barIndex
            bar.moveToPoint(CGPoint(x: x, y: rect.height))
            bar.addLineToPoint(CGPoint(x: x, y: barStepHeight * (CGFloat(barNumber) - (barIndex + 1))))
            bar.lineWidth = barWidth
            if i < rank {
                barColor.setStroke()
            } else {
                barBackgroundColor.setStroke()
            }
            bar.stroke()
        }
    }
}

