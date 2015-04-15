//
//  YepRefreshView.swift
//  YepPullRefresh
//
//  Created by kevinzhow on 15/4/14.
//  Copyright (c) 2015年 kevinzhow. All rights reserved.
//

import UIKit

import QuartzCore

class YepShape: CAShapeLayer {
    
    func setupWithWidth(width:CGFloat, height:CGFloat) {
        var rectanglePath = UIBezierPath()
        
        let bottomGap = height/CGFloat(tan(M_PI/3))
        let bottomWidth = width - 2*bottomGap
        let gapSideLenth = bottomGap*2
        
        rectanglePath.moveToPoint(CGPointMake(0, 0))
        rectanglePath.addLineToPoint(CGPointMake(width, 0))
        rectanglePath.addLineToPoint(CGPointMake(width - bottomGap, height))
        rectanglePath.addLineToPoint(CGPointMake(width - bottomWidth - bottomGap, height))
        rectanglePath.closePath()
        
        // Create initial shape of the view
        self.path = rectanglePath.CGPath
        self.fillColor = UIColor(red:0.33, green:0.71, blue:0.98, alpha:1).CGColor
    }
    
    func setupFlipWithWidth(width:CGFloat, height:CGFloat) {
        var rectanglePath = UIBezierPath()
        
        let bottomGap = height/CGFloat(tan(M_PI/3))
        let bottomWidth = width - 2*bottomGap
        let gapSideLenth = bottomGap*2
        
        rectanglePath.moveToPoint(CGPointMake(bottomGap, 0))
        rectanglePath.addLineToPoint(CGPointMake(bottomGap+bottomWidth, 0))
        rectanglePath.addLineToPoint(CGPointMake(bottomGap+bottomWidth+bottomGap, height))
        rectanglePath.addLineToPoint(CGPointMake(0, height))
        rectanglePath.closePath()
        
        // Create initial shape of the view
        self.path = rectanglePath.CGPath
        self.fillColor = UIColor(red:0.33, green:0.71, blue:0.98, alpha:1).CGColor
    }
}


class YepRefreshView: UIView {
    
    var shapes = [YepShape]()
    
    var originShapesPosition = [CGPoint]()
    
    var ramdonShapesPosition = [CGPoint]()
    
    var refreshing = false
    
    static let shapeWidth:CGFloat = 15
    
    static let shapeHeight:CGFloat = 4.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        var x = YepRefreshView.shapeHeight/CGFloat(tan(M_PI/3))
        var bottomWidth = YepRefreshView.shapeWidth - 2*x
        var shape = YepShape()
        var shape2 = YepShape()
        var shape3 = YepShape()
        var shape5 = YepShape()
        var shape4 = YepShape()
        var shape6 = YepShape()
        
        shapes = [shape,shape2,shape3,shape4,shape5,shape6]
        
        shape.setupWithWidth(YepRefreshView.shapeWidth, height: YepRefreshView.shapeHeight)
        shape.position = CGPointMake(shape.position.x, shape.position.y+YepRefreshView.shapeHeight)
        
        shape2.setupFlipWithWidth(YepRefreshView.shapeWidth, height: YepRefreshView.shapeHeight)
        
        shape3.setupWithWidth(YepRefreshView.shapeWidth, height: YepRefreshView.shapeHeight)
        shape3.position = CGPointMake(shape3.position.x, shape3.position.y+YepRefreshView.shapeHeight)
        
        shape4.setupFlipWithWidth(YepRefreshView.shapeWidth, height: YepRefreshView.shapeHeight)
        
        shape5.setupWithWidth(YepRefreshView.shapeWidth, height: YepRefreshView.shapeHeight)
        shape5.position = CGPointMake(shape5.position.x, shape5.position.y+YepRefreshView.shapeHeight)
        
        shape6.setupFlipWithWidth(YepRefreshView.shapeWidth, height: YepRefreshView.shapeHeight)
        
        originShapesPosition = [shape.position, shape2.position, shape3.position, shape4.position, shape5.position, shape6.position]
        
        ramdonShapesPosition = [CGPointMake(-110, -230.0), CGPointMake(-70, -110.0), CGPointMake(180, -30.0), CGPointMake(140, -220.0), CGPointMake(-140, 230.0), CGPointMake(-220, 40.0)]
        
        for (index, shape) in enumerate(shapes) {
            shape.opacity = 0.0
            shape.position = ramdonShapesPosition[index]
        }
        
        var leafShape1 = CAShapeLayer()
        leafShape1.frame = CGRectMake(-YepRefreshView.shapeWidth/2.0 + frame.width/2.0, -YepRefreshView.shapeHeight + frame.height/2.0, YepRefreshView.shapeWidth, YepRefreshView.shapeHeight*2)
        leafShape1.addSublayer(shape)
        leafShape1.addSublayer(shape2)
        self.layer.addSublayer(leafShape1)
        
        var leafShape2 = CAShapeLayer()
        leafShape2.frame = CGRectMake(-YepRefreshView.shapeWidth/2.0 + frame.width/2.0, -YepRefreshView.shapeHeight + frame.height/2.0, YepRefreshView.shapeWidth, YepRefreshView.shapeHeight*2)
        leafShape2.addSublayer(shape3)
        leafShape2.addSublayer(shape4)
        self.layer.addSublayer(leafShape2)
        
        var leafShape3 = CAShapeLayer()
        leafShape3.frame = CGRectMake(-YepRefreshView.shapeWidth/2.0 + frame.width/2.0, -YepRefreshView.shapeHeight + frame.height/2.0, YepRefreshView.shapeWidth, YepRefreshView.shapeHeight*2)
        leafShape3.addSublayer(shape5)
        leafShape3.addSublayer(shape6)
        self.layer.addSublayer(leafShape3)
        
        leafShape1.anchorPoint = CGPoint(x: 0, y: 0.5)
        leafShape2.anchorPoint = CGPoint(x: 0, y: 0.5)
        leafShape3.anchorPoint = CGPoint(x: 0, y: 0.5)
        leafShape1.transform = CATransform3DMakeRotation(CGFloat(-M_PI/6), 0.0, 0.0, 1.0)
        leafShape2.transform = CATransform3DMakeRotation(CGFloat(M_PI/2), 0.0, 0.0, 1.0)
        leafShape3.transform = CATransform3DMakeRotation(CGFloat(-(M_PI)+M_PI/6), 0.0, 0.0, 1.0)
        
    }
    
    func beginFlik() {
        
        if !refreshing {
            refreshing = true
            
            for (index, shape) in enumerate(shapes) {
                shape.opacity = 1.0
                let animation = CABasicAnimation(keyPath: "opacity")
                animation.fromValue = 1.0
                animation.toValue = 0.5
                animation.repeatCount = 1000
                animation.autoreverses = true
                animation.fillMode = kCAFillModeBoth
                animation.timingFunction = CAMediaTimingFunction(name: "linear")
                
                var delay:Double = 0
                var timeScale:Double = 3
                
                if index == 0 || index == 5 {
                    
                    delay = 0.1*timeScale
                }
            
                if index == 1 || index == 2 {
                    //2
                    delay = 0.05*timeScale
                }
                
                
                animation.duration = 0.09*timeScale
                animation.beginTime = CACurrentMediaTime() + delay

                shape.addAnimation(animation, forKey: "flip")
            }

        }
    }
    
    func updatePullRefreshWithProgress(progress: CGFloat) {
        println("\(progress)")
        
        if (!refreshing) {
            
            if progress == 0.0 {
                beginFlik()
            }
            
            for (index, shape) in enumerate(shapes) {
                
                shape.opacity = 1 - Float(progress)
                shape.position = CGPointMake(originShapesPosition[index].x+ramdonShapesPosition[index].x*progress, ramdonShapesPosition[index].y*progress+originShapesPosition[index].y)
                
            }
        }
        
    }
    
    func stopFlik() {
        refreshing = false
        for (index, shape) in enumerate(shapes) {
            shape.removeAnimationForKey("flip")
        }
        updatePullRefreshWithProgress(1.0)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
