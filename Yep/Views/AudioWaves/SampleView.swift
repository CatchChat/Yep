//
//  SampleView.swift
//  Yep
//
//  Created by NIX on 15/4/3.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

@IBDesignable
final class SampleView: UIView {

    var samples: [CGFloat]?

    var progress: CGFloat = 0 {
        didSet {
            updateWave()
        }
    }

    @IBInspectable var sampleColor: UIColor = UIColor.yepTintColor() {
        willSet {
            playedWaveLayer.strokeColor = newValue.withAlphaComponent(0.5).cgColor
            unplayedWaveLayer.strokeColor = newValue.cgColor
        }
    }

    let sampleWidth: CGFloat = YepConfig.audioSampleWidth()
    let sampleGap = YepConfig.audioSampleGap()

    lazy var playedWaveLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = self.sampleWidth
        layer.strokeColor = self.sampleColor.withAlphaComponent(0.5).cgColor
        return layer
    }()

    lazy var unplayedWaveLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = self.sampleWidth
        layer.strokeColor = self.sampleColor.cgColor
        return layer
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        backgroundColor = UIColor.clear

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

                for (index, percent) in samples.enumerated() {

                    let x = CGFloat(index) * sampleWidth + sampleGap * CGFloat(index)
                    let sampleHeightMax = viewHeight * 0.7
                    var realSampleHeight = percent * viewHeight

                    realSampleHeight = realSampleHeight < 1 ? 1 : realSampleHeight

                    let sampleHeight = realSampleHeight < sampleHeightMax ? realSampleHeight: sampleHeightMax

                    if CGFloat(index) / CGFloat(samples.count) < progress {
                        playedWavePath.move(to: CGPoint(x: x, y: viewHeight / 2.0 - sampleHeight / 2.0))
                        playedWavePath.addLine(to: CGPoint(x: x, y: sampleHeight / 2.0 + viewHeight / 2.0))

                    } else {
                        unplayedWavePath.move(to: CGPoint(x: x, y: viewHeight / 2.0 - sampleHeight / 2.0))
                        unplayedWavePath.addLine(to: CGPoint(x: x, y: sampleHeight / 2.0 + viewHeight / 2.0))
                    }
                }

                playedWaveLayer.path = playedWavePath.cgPath
                unplayedWaveLayer.path = unplayedWavePath.cgPath
            }

        } else {
            samples = [0.05, 0.05, 0.1, 0.2, 0.3, 0.6, 0.2, 0.7, 0.9, 0.7, 0.6, 0.3, 0.1, 0.1, 0.05] // count = 15
            progress = 0
        }
    }
}

