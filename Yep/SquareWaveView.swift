//
//  SquareWaveView.swift
//  Waver-Swift
//
//  Created by kevinzhow on 15/4/1.
//  Copyright (c) 2015年 kevinzhow. All rights reserved.
//

import UIKit

class SquareWaveView: UIView {

    var maxHeight: CGFloat = 1.0
    
    var waves = [CGFloat]()
    
    var wave = CAShapeLayer()
    
    var waveWidth: CGFloat = 4.0
    
    var waveGap: CGFloat = 1.0
    
    var waveTotalCount: CGFloat!
    
    var waveSampleCount = 0
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    func setup() {
       
        wave.lineCap       = kCALineCapButt
        wave.lineJoin      = kCALineJoinRound
        wave.fillColor     = UIColor.clearColor().CGColor
        wave.lineWidth     = waveWidth
        wave.strokeColor   = UIColor.grayColor().CGColor
        self.layer.addSublayer(wave)
        
        waveTotalCount = self.bounds.width/(waveWidth+waveGap)
        
    }
    
    private func updateMeters() {
        UIGraphicsBeginImageContext(self.frame.size)
        
        var wavesPath = UIBezierPath()
        
        for (index, wave) in enumerate(waves) {
            
            var x = CGFloat(index) * waveWidth + waveGap * CGFloat(index)
            
            wavesPath.moveToPoint(CGPointMake(x, self.bounds.height/2.0 - wave/2.0))
            wavesPath.addLineToPoint(CGPointMake(x, wave/2.0 + self.bounds.height/2.0))
            
        }
        
        wave.path = wavesPath.CGPath
        
        UIGraphicsEndImageContext()
    }
    
    func appendValue(newValue: CGFloat) {

        if ++waveSampleCount % 6 == 0{
            
            waves.append(newValue*self.bounds.height)
            
            if waves.count > Int(waveTotalCount) {
                waves.removeAtIndex(0)
            }
            
            updateMeters()
        }

    }

}
