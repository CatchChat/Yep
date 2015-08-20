//
//  ShowStepGeniusViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/20.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ShowStepGeniusViewController: UIViewController {

    @IBOutlet weak var rightPurpleDot: UIImageView!
    @IBOutlet weak var leftGreenDot: UIImageView!
    @IBOutlet weak var leftBlueDot: UIImageView!
    @IBOutlet weak var leftRedDot: UIImageView!
    @IBOutlet weak var leftPurpleDot: UIImageView!
    @IBOutlet weak var topRedDot: UIImageView!
    @IBOutlet weak var rightBlueDot: UIImageView!
    @IBOutlet weak var centerBlueDot: UIImageView!
    @IBOutlet weak var centerOrangeDot: UIImageView!
    @IBOutlet weak var rightYellowDot: UIImageView!
    @IBOutlet weak var rightGreenDot: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        repeatAnimate(rightPurpleDot, alongWithPath: UIBezierPath(ovalInRect: CGRectInset(rightPurpleDot.frame, 2, 2)), duration: 4)
        repeatAnimate(leftGreenDot, alongWithPath: UIBezierPath(ovalInRect: CGRectInset(leftGreenDot.frame, 5, 5)), duration: 2.5)
        repeatAnimate(leftBlueDot, alongWithPath: UIBezierPath(ovalInRect: CGRectInset(leftBlueDot.frame, 3, 3)), duration: 4)
        repeatAnimate(leftRedDot, alongWithPath: UIBezierPath(ovalInRect: CGRectInset(leftRedDot.frame, 3, 3)), duration: 1.5)
        repeatAnimate(leftPurpleDot, alongWithPath: UIBezierPath(ovalInRect: CGRectInset(leftPurpleDot.frame, 1, 1)), duration: 6)
        repeatAnimate(topRedDot, alongWithPath: UIBezierPath(ovalInRect: CGRectInset(topRedDot.frame, 1, 1)), duration: 2)
        repeatAnimate(rightBlueDot, alongWithPath: UIBezierPath(ovalInRect: CGRectInset(rightBlueDot.frame, 1, 1)), duration: 3)
        repeatAnimate(centerBlueDot, alongWithPath: UIBezierPath(ovalInRect: CGRectInset(centerBlueDot.frame, 1, 1)), duration: 3)
        repeatAnimate(centerOrangeDot, alongWithPath: UIBezierPath(ovalInRect: CGRectInset(centerOrangeDot.frame, 1, 1)), duration: 3)
        repeatAnimate(rightYellowDot, alongWithPath: UIBezierPath(ovalInRect: CGRectInset(rightYellowDot.frame, 1, 1)), duration: 3)
        repeatAnimate(rightGreenDot, alongWithPath: UIBezierPath(ovalInRect: CGRectInset(rightGreenDot.frame, 1, 1)), duration: 3)
    }

    func repeatAnimate(view: UIView, alongWithPath path: UIBezierPath, duration: CFTimeInterval) {

        let animation = CAKeyframeAnimation(keyPath: "position")

        animation.calculationMode = kCAAnimationPaced
        animation.fillMode = kCAFillModeForwards
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.repeatCount = Float.infinity

        animation.path = path.CGPath

        view.layer.addAnimation(animation, forKey: "Animation")
    }
}

