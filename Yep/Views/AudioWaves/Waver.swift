//
//  Waver.swift
//  Yep
//
//  Created by kevinzhow on 15/4/1.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class Waver: UIView {
    
    fileprivate var displayLink: CADisplayLink?
    
    fileprivate let numberOfWaves: Int = 5
    
    fileprivate let waveColor = UIColor.yepTintColor()
    
    fileprivate var phase: CGFloat = 0
    
    fileprivate var presented = false
    
    var level: CGFloat = 0 {
        didSet {
            self.phase += self.phaseShift // Move the wave
            self.amplitude = fmax( level, self.idleAmplitude)
            
            self.appendValue(pow(CGFloat(level), 3))
            
            self.updateMeters()
        }
    }
    
    fileprivate let mainWaveWidth: CGFloat = 2.0
    
    fileprivate let decorativeWavesWidth: CGFloat = 1.0
    
    fileprivate let idleAmplitude: CGFloat = 0.01
    
    fileprivate let frequency: CGFloat = 1.2
    
    internal fileprivate(set) var amplitude: CGFloat = 1.0
    
    var density: CGFloat = 1.0
    
    var phaseShift: CGFloat = -0.25
    
    internal fileprivate(set) var waves: [CAShapeLayer] = []
    
    //
    
    fileprivate var waveHeight: CGFloat!
    fileprivate var waveWidth: CGFloat!
    fileprivate var waveMid: CGFloat!
    fileprivate var maxAmplitude: CGFloat!
    
    // Sample Data
    
    fileprivate var waveSampleCount = 0
    
    fileprivate var waveSamples = [CGFloat]()
    
    fileprivate var waveTotalCount: CGFloat!
    
    fileprivate var waveSquareWidth: CGFloat = 2.0
    
    fileprivate var waveGap: CGFloat = 1.0
    
    fileprivate var maxSquareWaveLength = 256
    
    fileprivate let fps = 6
    
    //

    var waverCallback: ((_ waver: Waver) -> ())? {
        didSet {
            displayLink?.invalidate()
            displayLink = CADisplayLink(target: self, selector: #selector(Waver.callbackWaver))
            displayLink?.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
            
            (0..<self.numberOfWaves).forEach { i in
                let waveline = CAShapeLayer()
                waveline.lineCap       = kCALineCapButt
                waveline.lineJoin      = kCALineJoinRound
                waveline.strokeColor   = UIColor.clear.cgColor
                waveline.fillColor     = UIColor.clear.cgColor
                waveline.lineWidth = (i==0 ? self.mainWaveWidth : self.decorativeWavesWidth)

                let floatI = CGFloat(i)
                let progressIndex = floatI/CGFloat(self.numberOfWaves)
                let progress = 1.0 - progressIndex
                let multiplier = min(1.0, (progress/3.0*2.0) + (1.0/3.0))
                
                waveline.strokeColor   = waveColor.withAlphaComponent(( i == 0 ? 1.0 : 1.0*multiplier*0.4)).cgColor
                
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
    
    fileprivate func appendValue(_ newValue: CGFloat) {

        waveSampleCount += 1

        if waveSampleCount % fps == 0 {
            waveSamples.append(newValue)
        }
    }
    
    fileprivate func setup() {
        
        self.waveHeight = self.bounds.height * 0.9
        self.waveWidth = self.bounds.width
        self.waveMid = self.waveWidth/2.0
        self.maxAmplitude = self.waveHeight - 4.0
        
    }
    
    @objc fileprivate func callbackWaver() {
        if presented {
            waverCallback?(self)
        }
    }
    
    fileprivate func updateMeters() {

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
                    wavelinePath.move(to: CGPoint(x: x, y: y))
                }
                else {
                    wavelinePath.addLine(to: CGPoint(x: x, y: y))
                }

                x += self.density
            }
            
            let waveline = self.waves[i]
            waveline.path = wavelinePath.cgPath
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

