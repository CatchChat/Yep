//
//  ShowStepGeniusViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/20.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ShowStepGeniusViewController: UIViewController {

    @IBOutlet weak var dot1: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        animateView(dot1, alongWithPath: UIBezierPath(ovalInRect: dot1.frame), duration: 4)
    }

    func animateView(view: UIView, alongWithPath path: UIBezierPath, duration: CFTimeInterval) {

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

