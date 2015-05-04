//
//  Waver.swift
//  Waver-Swift
//
//  Created by kevinzhow on 15/4/1.
//  Copyright (c) 2015年 kevinzhow. All rights reserved.
//

import UIKit

class Waver: UIView {
    
    var displayLink: CADisplayLink!
    
    var numberOfWaves: Int = 5
    
    var waveColor: UIColor = UIColor(red: 50/255.0, green: 167/255.0, blue: 255/255.0, alpha: 1.0)
    
    private var phase: CGFloat = 0
    
    var presented = false
    
    var level: CGFloat! {
        didSet {
            self.phase+=self.phaseShift; // Move the wave
            self.amplitude = fmax( level, self.idleAmplitude)
            
            self.appendValue(pow(CGFloat(level),3))
            
            self.updateMeters()
        }
    }
    
    var mainWaveWidth: CGFloat = 2.0
    
    var decorativeWavesWidth: CGFloat = 1.0
    
    var idleAmplitude: CGFloat = 0.01
    
    var frequency: CGFloat = 1.2
    
    internal private(set) var amplitude: CGFloat = 1.0
    
    var density: CGFloat = 1.0
    
    var phaseShift: CGFloat = -0.25
    
    internal private(set) var waves: NSMutableArray = []
    
    //
    
    var waveHeight: CGFloat!
    var waveWidth: CGFloat!
    var waveMid: CGFloat!
    var maxAmplitude: CGFloat!
    
    // Sample Data
    
    var waveSampleCount = 0
    
    var waveSamples = [CGFloat]()
    
    var waveTotalCount: CGFloat!
    
    var waveSquareWidth: CGFloat = 2.0
    
    var waveGap: CGFloat = 1.0
    
    var maxSquareWaveLength = 256
    
    var maxTime = 60
    
    var fps = 6
    
    //

    var waverCallback: ((waver: Waver) -> ())? {
        didSet {
            displayLink = CADisplayLink(target: self, selector: Selector("callbackWaver"))
            displayLink.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
            
            for var i = 0; i < self.numberOfWaves; ++i {
                var waveline = CAShapeLayer()
                waveline.lineCap       = kCALineCapButt
                waveline.lineJoin      = kCALineJoinRound
                waveline.strokeColor   = UIColor.clearColor().CGColor
                waveline.fillColor     = UIColor.clearColor().CGColor
                waveline.lineWidth = (i==0 ? self.mainWaveWidth : self.decorativeWavesWidth)

                var floatI = CGFloat(i)
                var progressIndex = floatI/CGFloat(self.numberOfWaves)
                var progress = 1.0 - progressIndex
                var multiplier = min(1.0, (progress/3.0*2.0) + (1.0/3.0))
                
                waveline.strokeColor   = waveColor.colorWithAlphaComponent(( i == 0 ? 1.0 : 1.0*multiplier*0.4)).CGColor
                
                self.layer.addSublayer(waveline)
                self.waves.addObject(waveline)
            }
            
        }
    }

    deinit {
        displayLink.invalidate()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    func appendValue(newValue: CGFloat) {
        
        if ++waveSampleCount % fps == 0{
            
            waveSamples.append(newValue*5)
            
            updateMeters()
        }
    }
    
    private func setup() {
        
        self.waveHeight = CGRectGetHeight(self.bounds) * 0.9
        self.waveWidth = CGRectGetWidth(self.bounds)
        self.waveMid = self.waveWidth/2.0
        self.maxAmplitude = self.waveHeight - 4.0
        
    }
    
    func callbackWaver() {
        if presented {
            waverCallback!(waver: self)
        }
    }
    
    private func updateMeters() {
        UIGraphicsBeginImageContext(self.frame.size)
        
        for var i=0; i < self.numberOfWaves; ++i {
            
            
            var wavelinePath = UIBezierPath()
            
            // Progress is a value between 1.0 and -0.5, determined by the current wave idx, which is used to alter the wave's amplitude.
            var progress = 1.0 - CGFloat(i)/CGFloat(self.numberOfWaves)
            var normedAmplitude = (1.5*progress-0.5)*self.amplitude
            
            
            for var x = 0 as CGFloat; x<self.waveWidth + self.density; x += self.density {
                
                //Thanks to https://github.com/stefanceriu/SCSiriWaveformView
                // We use a parable to scale the sinus wave, that has its peak in the middle of the view.
                var scaling = -pow(x/self.waveMid-1, 2) + 1 // make center bigger
                
                var y = scaling*self.maxAmplitude*normedAmplitude
                var temp = 2.0*CGFloat(M_PI)*(x/self.waveWidth)*self.frequency
                var temp2 = temp+self.phase
                y = CGFloat(y)*CGFloat(sinf(Float(temp2))) + self.waveHeight
                
                if (x==0) {
                    wavelinePath.moveToPoint(CGPointMake(x, y))
                }
                else {
                    wavelinePath.addLineToPoint(CGPointMake(x, y))
                }
            }
            
            var waveline = self.waves.objectAtIndex(i) as! CAShapeLayer
            waveline.path = wavelinePath.CGPath
            
        }
        
        UIGraphicsEndImageContext()
    }
    
    func compressSamples() -> [Float]? {
        
        println("Begin compress")
        
        var finalSamples = [Float]()
        
        var samplesCount = waveSamples.count //获取总的 Sample 数量
        
        println("Samples before compress \(waveSamples)")
        
        var totalTime:CGFloat = CGFloat(waveSamples.count/(60/fps)) // 计算音频的时长
        
        var bubbleWidth = -0.05*(totalTime*totalTime) + 6.0*totalTime + 50.0 //计算这个时长下的Bubble宽度，Bubble 的宽度和时间的关系函数是一个一元二次函数
        
        var effectiveSample = bubbleWidth/(waveSquareWidth+waveGap) < 1 ? 1 : bubbleWidth/(waveSquareWidth+waveGap) //计算这个长度里实际可以放多少个sample
        
        effectiveSample = max(20, effectiveSample)
        
        var sampleGap = Int(CGFloat(samplesCount)/effectiveSample) //计算按照实际可放的sample数量，原sample需要每几个合并一次
        
        var timePerSample = totalTime/(CGFloat(samplesCount)/effectiveSample) //计算合并后每个 sample 需要经过多少时间播放
        
        println("samplesCount \(samplesCount) totalTime \(totalTime) bubbleWidth \(bubbleWidth) effectiveSample \(effectiveSample) sampleGap \(sampleGap) timePerSample \(timePerSample)")
        
        //
        
        var sampleCount = 1
        
        var lastSample: CGFloat = 0
        
        for sample in waveSamples {
            
            lastSample = max(sample, lastSample)
            
            if sampleCount >= sampleGap {
                sampleCount = 1
                finalSamples.append(Float(lastSample))
                lastSample = 0
            }else {
                sampleCount += 1
            }
            
        }
        
        println("Final Sample is \(finalSamples)")
        
        return finalSamples
    }

    func resetWaveSamples() {
        waveSamples = [CGFloat]()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.presented = true
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        self.presented = false
    }
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
