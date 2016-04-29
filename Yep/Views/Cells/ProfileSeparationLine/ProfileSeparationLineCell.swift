//
//  ProfileSeparationLineCell.swift
//  Yep
//
//  Created by NIX on 15/5/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class ProfileSeparationLineCell: UICollectionViewCell {

    var leftEdgeInset: CGFloat = YepConfig.Profile.leftEdgeInset
    var rightEdgeInset: CGFloat = YepConfig.Profile.rightEdgeInset
    var lineColor: UIColor = UIColor.yepBorderColor()
    var lineWidth: CGFloat = 1.0 / UIScreen.mainScreen().scale

    // MARK: Draw

    override func drawRect(rect: CGRect) {
        super.drawRect(rect)

        lineColor.setStroke()

        let context = UIGraphicsGetCurrentContext()

        CGContextSetLineWidth(context, lineWidth)

        let y = ceil(CGRectGetHeight(rect) * 0.5)

        CGContextMoveToPoint(context, leftEdgeInset, y)
        CGContextAddLineToPoint(context, CGRectGetWidth(rect) - rightEdgeInset, y)

        CGContextStrokePath(context)
    }
}
