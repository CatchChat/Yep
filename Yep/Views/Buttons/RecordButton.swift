//
//  RecordButton.swift
//  Yep
//
//  Created by nixzhu on 15/12/8.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class RecordButton: UIButton {

    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: 100, height: 100)
    }

    lazy var outerPath: UIBezierPath = {
        return UIBezierPath(ovalInRect: CGRectInset(self.bounds, 8, 8))
    }()

    lazy var innerDefaultPath: UIBezierPath = {
        return UIBezierPath(roundedRect: CGRectInset(self.bounds, 14, 14), cornerRadius: 43)
    }()

    lazy var innerRecordingPath: UIBezierPath = {
        return UIBezierPath(roundedRect: CGRectInset(self.bounds, 30, 30), cornerRadius: 5)
    }()

    var innerPath: UIBezierPath {
        switch appearance {
        case .Default:
            return innerDefaultPath
        case .Recording:
            return innerRecordingPath
        }
    }

    enum Appearance {
        case Default
        case Recording

        var outerLineWidth: CGFloat {
            switch self {
            case .Default:
                return 8
            case .Recording:
                return 3
            }
        }
    }

    var appearance: Appearance = .Default {
        didSet {

            do {
                let animation = CABasicAnimation(keyPath: "lineWidth")
                animation.toValue = appearance.outerLineWidth
                animation.duration = 0.25
                animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
                animation.fillMode = kCAFillModeBoth
                animation.removedOnCompletion = false

                outerShapeLayer.addAnimation(animation, forKey: "lineWidth")
            }

            do {
                let animation = CABasicAnimation(keyPath: "path")

                animation.toValue = innerPath.CGPath
                animation.duration = 0.25
                animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
                animation.fillMode = kCAFillModeBoth
                animation.removedOnCompletion = false

                innerShapeLayer.addAnimation(animation, forKey: "path")
            }
        }
    }

    lazy var outerShapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.path = self.outerPath.CGPath
        layer.lineWidth = self.appearance.outerLineWidth
        layer.strokeColor = UIColor.yepTintColor().CGColor
        layer.fillColor = UIColor.whiteColor().CGColor
        return layer
    }()

    lazy var innerShapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.path = self.innerPath.CGPath
        layer.fillColor = UIColor.redColor().CGColor
        layer.fillRule = kCAFillRuleEvenOdd
        return layer
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        backgroundColor = UIColor.clearColor()

        layer.addSublayer(outerShapeLayer)
        layer.addSublayer(innerShapeLayer)
    }
}

