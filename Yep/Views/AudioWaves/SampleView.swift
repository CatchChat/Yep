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

    var samples: [CGFloat]?

    var progress: CGFloat = 0 {
        didSet {
            updateWave()
        }
    }

    @IBInspectable var sampleColor: UIColor = UIColor.yepTintColor() {
        willSet {
            playedWaveLayer.strokeColor = newValue.colorWithAlphaComponent(0.5).CGColor
            unplayedWaveLayer.strokeColor = newValue.CGColor
        }
    }

    let sampleWidth: CGFloat = YepConfig.audioSampleWidth()
    let sampleGap = YepConfig.audioSampleGap()

    lazy var playedWaveLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = self.sampleWidth
        layer.strokeColor = self.sampleColor.colorWithAlphaComponent(0.5).CGColor
        return layer
    }()

    lazy var unplayedWaveLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = self.sampleWidth
        layer.strokeColor = self.sampleColor.CGColor
        return layer
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        backgroundColor = UIColor.clearColor()

        layer.addSublayer(unplayedWaveLayer)
        layer.addSublayer(playedWaveLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateWave()
    }

    func updateWave() {

        let playedWavePath = UIBezierPath()
        let unplayedWavePath = UIBezierPath()

        if let samples = samples {

            if samples.count > 0 {

                let viewHeight = self.bounds.height

                for (index, percent) in samples.enumerate() {

                    let x = CGFloat(index) * sampleWidth + sampleGap * CGFloat(index)
                    let sampleHeightMax = viewHeight * 0.7
                    var realSampleHeight = percent * viewHeight

                    realSampleHeight = realSampleHeight < 1 ? 1 : realSampleHeight

                    let sampleHeight = realSampleHeight < sampleHeightMax ? realSampleHeight: sampleHeightMax

                    if CGFloat(index) / CGFloat(samples.count) < progress {
                        playedWavePath.moveToPoint(CGPointMake(x, viewHeight / 2.0 - sampleHeight / 2.0))
                        playedWavePath.addLineToPoint(CGPointMake(x, sampleHeight / 2.0 + viewHeight / 2.0))

                    } else {
                        unplayedWavePath.moveToPoint(CGPointMake(x, viewHeight / 2.0 - sampleHeight / 2.0))
                        unplayedWavePath.addLineToPoint(CGPointMake(x, sampleHeight / 2.0 + viewHeight / 2.0))
                    }
                }

                playedWaveLayer.path = playedWavePath.CGPath
                unplayedWaveLayer.path = unplayedWavePath.CGPath
            }

        } else {
            samples = [0.05, 0.05, 0.1, 0.2, 0.3, 0.6, 0.2, 0.7, 0.9, 0.7, 0.6, 0.3, 0.1, 0.1, 0.05] // count = 15
            progress = 0
        }
    }
}

