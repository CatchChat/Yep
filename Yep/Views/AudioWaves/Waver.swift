//
//  Waver.swift
//  Yep
//
//  Created by kevinzhow on 15/4/1.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class Waver: UIView {
    
    private var displayLink: CADisplayLink?
    
    private let numberOfWaves: Int = 5
    
    private let waveColor = UIColor.yepTintColor()
    
    private var phase: CGFloat = 0
    
    private var presented = false
    
    var level: CGFloat = 0 {
        didSet {
            self.phase += self.phaseShift // Move the wave
            self.amplitude = fmax( level, self.idleAmplitude)
            
            self.appendValue(pow(CGFloat(level), 3))
            
            self.updateMeters()
        }
    }
    
    private let mainWaveWidth: CGFloat = 2.0
    
    private let decorativeWavesWidth: CGFloat = 1.0
    
    private let idleAmplitude: CGFloat = 0.01
    
    private let frequency: CGFloat = 1.2
    
    internal private(set) var amplitude: CGFloat = 1.0
    
    var density: CGFloat = 1.0
    
    var phaseShift: CGFloat = -0.25
    
    internal private(set) var waves: [CAShapeLayer] = []
    
    //
    
    private var waveHeight: CGFloat!
    private var waveWidth: CGFloat!
    private var waveMid: CGFloat!
    private var maxAmplitude: CGFloat!
    
    // Sample Data
    
    private var waveSampleCount = 0
    
    private var waveSamples = [CGFloat]()
    
    private var waveTotalCount: CGFloat!
    
    private var waveSquareWidth: CGFloat = 2.0
    
    private var waveGap: CGFloat = 1.0
    
    private var maxSquareWaveLength = 256
    
    private let fps = 6
    
    //

    var waverCallback: ((waver: Waver) -> ())? {
        didSet {
            displayLink?.invalidate()
            displayLink = CADisplayLink(target: self, selector: #selector(Waver.callbackWaver))
            displayLink?.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
            
            (0..<self.numberOfWaves).forEach { i in
                let waveline = CAShapeLayer()
                waveline.lineCap       = kCALineCapButt
                waveline.lineJoin      = kCALineJoinRound
                waveline.strokeColor   = UIColor.clearColor().CGColor
                waveline.fillColor     = UIColor.clearColor().CGColor
                waveline.lineWidth = (i==0 ? self.mainWaveWidth : self.decorativeWavesWidth)

                let floatI = CGFloat(i)
                let progressIndex = floatI/CGFloat(self.numberOfWaves)
                let progress = 1.0 - progressIndex
                let multiplier = min(1.0, (progress/3.0*2.0) + (1.0/3.0))
                
                waveline.strokeColor   = waveColor.colorWithAlphaComponent(( i == 0 ? 1.0 : 1.0*multiplier*0.4)).CGColor
                
                self.layer.addSublayer(waveline)
                self.waves.append(waveline)
            }
        }
    }

    deinit {
        displayLink?.invalidate()
        println("deinit Waver")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func appendValue(newValue: CGFloat) {

        waveSampleCount += 1

        if waveSampleCount % fps == 0 {
            waveSamples.append(newValue)
        }
    }
    
    private func setup() {
        
        self.waveHeight = CGRectGetHeight(self.bounds) * 0.9
        self.waveWidth = CGRectGetWidth(self.bounds)
        self.waveMid = self.waveWidth/2.0
        self.maxAmplitude = self.waveHeight - 4.0
        
    }
    
    @objc private func callbackWaver() {
        if presented {
            waverCallback?(waver: self)
        }
    }
    
    private func updateMeters() {

        (0..<self.numberOfWaves).forEach { i in
            
            let wavelinePath = UIBezierPath()
            
            // Progress is a value between 1.0 and -0.5, determined by the current wave idx, which is used to alter the wave's amplitude.
            let progress = 1.0 - CGFloat(i)/CGFloat(self.numberOfWaves)
            let normedAmplitude = (1.5*progress-0.5)*self.amplitude

            var x: CGFloat = 0
            while x < self.waveWidth + self.density {

                //Thanks to https://github.com/stefanceriu/SCSiriWaveformView
                // We use a parable to scale the sinus wave, that has its peak in the middle of the view.
                let scaling = -pow(x/self.waveMid-1, 2) + 1 // make center bigger
                
                var y = scaling*self.maxAmplitude*normedAmplitude
                let temp = 2.0*CGFloat(M_PI)*(x/self.waveWidth)*self.frequency
                let temp2 = temp+self.phase
                y = CGFloat(y)*CGFloat(sinf(Float(temp2))) + self.waveHeight
                
                if (x==0) {
                    wavelinePath.moveToPoint(CGPointMake(x, y))
                }
                else {
                    wavelinePath.addLineToPoint(CGPointMake(x, y))
                }

                x += self.density
            }
            
            let waveline = self.waves[safe: i]
            waveline?.path = wavelinePath.CGPath
        }
    }

    func resetWaveSamples() {
        waveSamples = []
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.presented = true
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        self.presented = false
    }
}

