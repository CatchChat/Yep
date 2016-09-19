//
//  RecordButton.swift
//  Yep
//
//  Created by nixzhu on 15/12/8.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class RecordButton: UIButton {

    override var intrinsicContentSize : CGSize {
        return CGSize(width: 100, height: 100)
    }

    lazy var outerPath: UIBezierPath = {
        return UIBezierPath(ovalIn: self.bounds.insetBy(dx: 8, dy: 8))
    }()

    lazy var innerDefaultPath: UIBezierPath = {
        return UIBezierPath(roundedRect: self.bounds.insetBy(dx: 14, dy: 14), cornerRadius: 43)
    }()

    lazy var innerRecordingPath: UIBezierPath = {
        return UIBezierPath(roundedRect: self.bounds.insetBy(dx: 35, dy: 35), cornerRadius: 5)
    }()

    var innerPath: UIBezierPath {
        switch appearance {
        case .default:
            return innerDefaultPath
        case .recording:
            return innerRecordingPath
        }
    }

    enum Appearance {
        case `default`
        case recording

        var outerLineWidth: CGFloat {
            switch self {
            case .default:
                return 8
            case .recording:
                return 3
            }
        }

        var outerFillColor: UIColor {
            switch self {
            case .default:
                return UIColor.white
            case .recording:
                return UIColor(red: 237/255.0, green: 247/255.0, blue: 1, alpha: 1)
            }
        }
    }

    var appearance: Appearance = .default {
        didSet {

            do {
                let animation = CABasicAnimation(keyPath: "lineWidth")
                animation.toValue = appearance.outerLineWidth
                animation.duration = 0.25
                animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
                animation.fillMode = kCAFillModeBoth
                animation.isRemovedOnCompletion = false

                outerShapeLayer.add(animation, forKey: "lineWidth")
            }

            do {
                let animation = CABasicAnimation(keyPath: "fillColor")
                animation.toValue = appearance.outerFillColor.cgColor
                animation.duration = 0.25
                animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
                animation.fillMode = kCAFillModeBoth
                animation.isRemovedOnCompletion = false

                outerShapeLayer.add(animation, forKey: "fillColor")
            }

            do {
                let animation = CABasicAnimation(keyPath: "path")

                animation.toValue = innerPath.cgPath
                animation.duration = 0.25
                animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
                animation.fillMode = kCAFillModeBoth
                animation.isRemovedOnCompletion = false

                innerShapeLayer.add(animation, forKey: "path")
            }
        }
    }

    lazy var outerShapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.path = self.outerPath.cgPath
        layer.lineWidth = self.appearance.outerLineWidth
        layer.strokeColor = UIColor.yepTintColor().cgColor
        layer.fillColor = self.appearance.outerFillColor.cgColor
        layer.fillRule = kCAFillRuleEvenOdd
        layer.contentsScale = UIScreen.main.scale
        return layer
    }()

    lazy var innerShapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.path = self.innerPath.cgPath
        layer.fillColor = UIColor.yepTintColor().cgColor
        layer.fillRule = kCAFillRuleEvenOdd
        layer.contentsScale = UIScreen.main.scale
        return layer
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        layer.addSublayer(outerShapeLayer)
        layer.addSublayer(innerShapeLayer)
    }
}

