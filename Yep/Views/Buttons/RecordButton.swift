//
//  RecordButton.swift
//  Yep
//
//  Created by nixzhu on 15/12/8.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class RecordButton: UIButton {

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
        return UIBezierPath(roundedRect: CGRectInset(self.bounds, 35, 35), cornerRadius: 5)
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

        var outerFillColor: UIColor {
            switch self {
            case .Default:
                return UIColor.whiteColor()
            case .Recording:
                return UIColor(red: 237/255.0, green: 247/255.0, blue: 1, alpha: 1)
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
                let animation = CABasicAnimation(keyPath: "fillColor")
                animation.toValue = appearance.outerFillColor.CGColor
                animation.duration = 0.25
                animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
                animation.fillMode = kCAFillModeBoth
                animation.removedOnCompletion = false

                outerShapeLayer.addAnimation(animation, forKey: "fillColor")
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
        layer.fillColor = self.appearance.outerFillColor.CGColor
        layer.fillRule = kCAFillRuleEvenOdd
        layer.contentsScale = UIScreen.mainScreen().scale
        return layer
    }()

    lazy var innerShapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.path = self.innerPath.CGPath
        layer.fillColor = UIColor.yepTintColor().CGColor
        layer.fillRule = kCAFillRuleEvenOdd
        layer.contentsScale = UIScreen.mainScreen().scale
        return layer
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        layer.addSublayer(outerShapeLayer)
        layer.addSublayer(innerShapeLayer)
    }
}

