//
//  YepRefreshView.swift
//  YepPullRefresh
//
//  Created by kevinzhow on 15/4/14.
//  Copyright (c) 2015年 kevinzhow. All rights reserved.
//

import UIKit

import QuartzCore

final class YepShape: CAShapeLayer {

    let shapeColor = UIColor(red:0.33, green:0.71, blue:0.98, alpha:1)

    func setupPathWithWidth(width: CGFloat, height: CGFloat) {
        let rectanglePath = UIBezierPath()
        
        let bottomGap = height / CGFloat(tan(M_PI / 3))
        let bottomWidth = width - bottomGap * 2
        //let gapSideLenth = bottomGap * 2
        
        rectanglePath.moveToPoint(CGPointMake(0, 0))
        rectanglePath.addLineToPoint(CGPointMake(width, 0))
        rectanglePath.addLineToPoint(CGPointMake(width - bottomGap, height))
        rectanglePath.addLineToPoint(CGPointMake(width - bottomWidth - bottomGap, height))
        rectanglePath.closePath()

        self.path = rectanglePath.CGPath
        self.fillColor = shapeColor.CGColor
    }
    
    func setupFlipPathWithWidth(width: CGFloat, height: CGFloat) {
        let rectanglePath = UIBezierPath()
        
        let bottomGap = height / CGFloat(tan(M_PI / 3))
        let bottomWidth = width - bottomGap * 2
        //let gapSideLenth = bottomGap * 2
        
        rectanglePath.moveToPoint(CGPointMake(bottomGap, 0))
        rectanglePath.addLineToPoint(CGPointMake(bottomGap + bottomWidth, 0))
        rectanglePath.addLineToPoint(CGPointMake(bottomGap + bottomWidth + bottomGap, height))
        rectanglePath.addLineToPoint(CGPointMake(0, height))
        rectanglePath.closePath()

        self.path = rectanglePath.CGPath
        self.fillColor = shapeColor.CGColor
    }
}


final class YepRefreshView: UIView {
    
    var shapes = [YepShape]()
    
    var originShapePositions = [CGPoint]()
    var ramdonShapePositions = [CGPoint]()
    
    var isFlashing = false
    
    let shapeWidth: CGFloat = 15
    let shapeHeight: CGFloat = 4.0
    
    override init(frame: CGRect) {

        super.init(frame: frame)

        //let x = shapeHeight / CGFloat(tan(M_PI / 3))

        //var bottomWidth = shapeWidth - x * 2

        let shape1 = YepShape()
        let shape2 = YepShape()
        let shape3 = YepShape()
        let shape5 = YepShape()
        let shape4 = YepShape()
        let shape6 = YepShape()
        
        shape1.setupPathWithWidth(shapeWidth, height: shapeHeight)
        shape1.position = CGPoint(
            x: shape1.position.x,
            y: shape1.position.y + shapeHeight
        )
        
        shape2.setupFlipPathWithWidth(shapeWidth, height: shapeHeight)
        
        shape3.setupPathWithWidth(shapeWidth, height: shapeHeight)
        shape3.position = CGPoint(
            x: shape3.position.x,
            y: shape3.position.y + shapeHeight
        )
        
        shape4.setupFlipPathWithWidth(shapeWidth, height: shapeHeight)
        
        shape5.setupPathWithWidth(shapeWidth, height: shapeHeight)
        shape5.position = CGPoint(
            x: shape5.position.x,
            y: shape5.position.y + shapeHeight)
        
        shape6.setupFlipPathWithWidth(shapeWidth, height: shapeHeight)

        shapes = [shape1, shape2, shape3, shape4, shape5, shape6]

        originShapePositions = shapes.map { $0.position }

        ramdonShapePositions = generateRamdonShapePositionsWithCount(originShapePositions.count)

        for (index, shape) in shapes.enumerate() {
            shape.opacity = 0.0
            shape.position = ramdonShapePositions[index]
        }
        
        let leafShape1 = CAShapeLayer()
        leafShape1.frame = CGRect(
            x: -shapeWidth / 2 + frame.width / 2,
            y: -shapeHeight + frame.height / 2,
            width: shapeWidth,
            height: shapeHeight * 2
        )
        leafShape1.addSublayer(shape1)
        leafShape1.addSublayer(shape2)
        self.layer.addSublayer(leafShape1)
        
        let leafShape2 = CAShapeLayer()
        leafShape2.frame = CGRect(
            x: -shapeWidth / 2 + frame.width / 2,
            y: -shapeHeight + frame.height / 2,
            width: shapeWidth,
            height: shapeHeight * 2
        )
        leafShape2.addSublayer(shape3)
        leafShape2.addSublayer(shape4)
        self.layer.addSublayer(leafShape2)
        
        let leafShape3 = CAShapeLayer()
        leafShape3.frame = CGRect(
            x: -shapeWidth / 2 + frame.width / 2,
            y: -shapeHeight + frame.height / 2,
            width: shapeWidth,
            height: shapeHeight * 2
        )
        leafShape3.addSublayer(shape5)
        leafShape3.addSublayer(shape6)
        self.layer.addSublayer(leafShape3)
        
        leafShape1.anchorPoint = CGPoint(x: 0, y: 0.5)
        leafShape2.anchorPoint = CGPoint(x: 0, y: 0.5)
        leafShape3.anchorPoint = CGPoint(x: 0, y: 0.5)

        leafShape1.transform = CATransform3DMakeRotation(CGFloat(-M_PI / 6), 0.0, 0.0, 1.0)
        leafShape2.transform = CATransform3DMakeRotation(CGFloat(M_PI / 2), 0.0, 0.0, 1.0)
        leafShape3.transform = CATransform3DMakeRotation(CGFloat(-M_PI + M_PI / 6), 0.0, 0.0, 1.0)
        
    }

    func generateRamdonShapePositionsWithCount(count: Int) -> [CGPoint] {
        func randomInRange(range: Range<Int>) -> CGFloat {
            var offset = 0

            if range.startIndex < 0 {
                offset = abs(range.startIndex)
            }

            let mini = UInt32(range.startIndex + offset)
            let maxi = UInt32(range.endIndex   + offset)

            return CGFloat(Int(mini + arc4random_uniform(maxi - mini)) - offset)
        }

        var positions = [CGPoint]()

        for _ in 0..<count {
            positions.append(CGPoint(x: randomInRange(-200...200), y: randomInRange(-200...200)))
        }

        return positions
    }

    func updateRamdonShapePositions() {
        ramdonShapePositions = generateRamdonShapePositionsWithCount(ramdonShapePositions.count)
    }

    func updateShapePositionWithProgressPercentage(progressPercentage: CGFloat) {

        if progressPercentage >= 1.0 {
            if !isFlashing {
                beginFlashing()
            }

        } else {
            if isFlashing {
                stopFlashing()
            }
        }

        for (index, shape) in shapes.enumerate() {

            shape.opacity = Float(progressPercentage)

            let x1 = ramdonShapePositions[index].x
            let y1 = ramdonShapePositions[index].y

            let x0 = originShapePositions[index].x
            let y0 = originShapePositions[index].y

            shape.position = CGPoint(
                x: x1 + (x0 - x1) * progressPercentage,
                y: y1 + (y0 - y1) * progressPercentage
            )
        }
    }
    
    func beginFlashing() {

        isFlashing = true

        for (index, shape) in shapes.enumerate() {
            shape.opacity = 1.0

            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 1.0
            animation.toValue = 0.5
            animation.repeatCount = 1000
            animation.autoreverses = true
            animation.fillMode = kCAFillModeBoth
            animation.timingFunction = CAMediaTimingFunction(name: "linear")

            var delay: Double = 0
            let timeScale: Double = 3

            switch index {
            case 0, 5:
                delay = 0.1 * timeScale

            case 1, 2:
                delay = 0.05 * timeScale

            default:
                break
            }

            animation.duration = 0.09 * timeScale
            animation.beginTime = CACurrentMediaTime() + delay

            shape.addAnimation(animation, forKey: "flip")
        }
    }

    func stopFlashing() {

        isFlashing = false

        for shape in shapes {
            shape.removeAnimationForKey("flip")
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
