//
//  SampleView.swift
//  Yep
//
//  Created by NIX on 15/4/3.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

@IBDesignable
class SampleView: UIView {

    var samples: [CGFloat]? {
        didSet {
            setNeedsLayout()
        }
    }

    @IBInspectable var sampleColor: UIColor = UIColor.yepTintColor() {
        willSet {
            waveLayer.strokeColor = newValue.CGColor
        }
    }

    let sampleWidth: CGFloat = YepConfig.audioSampleWidth()
    let sampleGap = YepConfig.audioSampleGap()

    lazy var waveLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = self.sampleWidth
        layer.strokeColor = self.sampleColor.CGColor
        return layer
        }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        backgroundColor = UIColor.clearColor()

        layer.addSublayer(waveLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let wavePath = UIBezierPath()

        if let samples = samples {

            if samples.count > 0 {

                let viewHeight = self.bounds.height

                for (index, percent) in enumerate(samples) {

                    let x = CGFloat(index) * sampleWidth + sampleGap * CGFloat(index)
                    let sampleHeightMax = viewHeight * 0.8
                    let realSampleHeight = percent * viewHeight
                    

                    let sampleHeight = realSampleHeight < sampleHeightMax ? realSampleHeight: sampleHeightMax

                    wavePath.moveToPoint(CGPointMake(x, viewHeight / 2.0 - sampleHeight / 2.0))
                    wavePath.addLineToPoint(CGPointMake(x, sampleHeight / 2.0 + viewHeight / 2.0))
                }
                
                waveLayer.path = wavePath.CGPath
            }

        } else {
            samples = [0.05, 0.05, 0.1, 0.2, 0.3, 0.6, 0.2, 0.7, 0.9, 0.7, 0.6, 0.3, 0.1, 0.1, 0.05] // count = 15 
        }
    }

}
