//
//  RecordButton.swift
//  Yep
//
//  Created by nixzhu on 15/12/8.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class RecordButton: UIButton {

    lazy var outerPath: UIBezierPath = {
        return UIBezierPath(ovalInRect: CGRectInset(self.bounds, 5, 5))
    }()

    enum Appearance {
        case Default
        case Recording

        var outerLineWidth: CGFloat {
            switch self {
            case .Default:
                return 5
            case .Recording:
                return 2
            }
        }
    }

    var appearance: Appearance = .Default

    lazy var outerShapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.path = self.outerPath.CGPath
        layer.lineWidth = self.appearance.outerLineWidth
        layer.strokeColor = UIColor.yepTintColor().CGColor
        return layer
    }()

    lazy var innerShapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        return layer
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        layer.addSublayer(outerShapeLayer)
        layer.addSublayer(innerShapeLayer)
    }
}

