//
//  ProfileSeparationLineCell.swift
//  Yep
//
//  Created by NIX on 15/5/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ProfileSeparationLineCell: UICollectionViewCell {

    var leftEdgeInset: CGFloat = YepConfig.Profile.leftEdgeInset
    var rightEdgeInset: CGFloat = YepConfig.Profile.rightEdgeInset
    var lineColor: UIColor = UIColor.lightGrayColor()

    lazy var separationLineLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = 1.0 / UIScreen.mainScreen().scale
        layer.strokeColor = self.lineColor.CGColor
        return layer
        }()


    override func awakeFromNib() {
        super.awakeFromNib()

        layer.addSublayer(separationLineLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let path = UIBezierPath()
        let y = ceil(CGRectGetHeight(bounds) * 0.5)
        path.moveToPoint(CGPoint(x: leftEdgeInset, y: y))
        path.addLineToPoint(CGPoint(x: CGRectGetWidth(bounds) - rightEdgeInset, y: y))

        separationLineLayer.path = path.CGPath
    }

}
