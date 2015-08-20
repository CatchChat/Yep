//
//  ShowStepViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ShowStepViewController: UIViewController {

    func repeatAnimate(view: UIView, alongWithPath path: UIBezierPath, duration: CFTimeInterval, autoreverses: Bool = false) {

        let animation = CAKeyframeAnimation(keyPath: "position")

        animation.calculationMode = kCAAnimationPaced
        animation.fillMode = kCAFillModeForwards
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.repeatCount = Float.infinity
        animation.autoreverses = autoreverses

        animation.path = path.CGPath

        view.layer.addAnimation(animation, forKey: "Animation")
    }
}
