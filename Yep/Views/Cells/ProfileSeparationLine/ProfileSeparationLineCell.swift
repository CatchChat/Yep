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
    var lineWidth: CGFloat = 1.0 / UIScreen.main.scale

    // MARK: Draw

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        lineColor.setStroke()

        let context = UIGraphicsGetCurrentContext()

        context!.setLineWidth(lineWidth)

        let y = ceil(rect.height * 0.5)

        context!.move(to: CGPoint(x: leftEdgeInset, y: y))
        context!.addLine(to: CGPoint(x: rect.width - rightEdgeInset, y: y))

        context!.strokePath()
    }
}
