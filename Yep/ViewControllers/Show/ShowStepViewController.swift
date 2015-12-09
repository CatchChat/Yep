//
//  ShowStepViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler

class ShowStepViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet private weak var titleLabelBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet private weak var subTitleLabelBottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.textColor = UIColor.yepTintColor()

        titleLabelBottomConstraint.constant = Ruler.iPhoneVertical(20, 30, 30, 30).value
        subTitleLabelBottomConstraint.constant = Ruler.iPhoneVertical(120, 140, 160, 180).value
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        view.alpha = 0
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animateWithDuration(0.5, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
            self?.view.alpha = 1
        }, completion: { _ in })
    }

    func repeatAnimate(view: UIView, alongWithPath path: UIBezierPath, duration: CFTimeInterval, autoreverses: Bool = false) {

        let animation = CAKeyframeAnimation(keyPath: "position")

        animation.calculationMode = kCAAnimationPaced
        animation.fillMode = kCAFillModeForwards
        animation.duration = duration
        animation.repeatCount = Float.infinity
        animation.autoreverses = autoreverses

        if autoreverses {
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)

        } else {
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        }

        animation.path = path.CGPath

        view.layer.addAnimation(animation, forKey: "Animation")
    }

    func animate(view: UIView, offset: UInt32, duration: CFTimeInterval) {

        let path = UIBezierPath()

        func flip() -> CGFloat {
            return arc4random() % 2 == 0 ? -1 : 1
        }

        let beginPoint = CGPoint(x: view.center.x + CGFloat(arc4random() % offset) * flip(), y: view.center.y + CGFloat(arc4random() % offset) * 0.5 * flip())
        let endPoint = CGPoint(x: view.center.x + CGFloat(arc4random() % offset) * flip(), y: view.center.y + CGFloat(arc4random() % offset) * 0.5 * flip())
        path.moveToPoint(beginPoint)
        path.addLineToPoint(endPoint)

        repeatAnimate(view, alongWithPath: path, duration: duration, autoreverses: true)

        repeatRotate(view, fromValue: -0.1, toValue: 0.1, duration: duration)
    }

    private func repeatRotate(view: UIView, fromValue: AnyObject, toValue: AnyObject, duration: CFTimeInterval) {

        let rotate = CABasicAnimation(keyPath: "transform.rotation.z")

        rotate.fromValue = fromValue
        rotate.toValue = toValue
        rotate.duration = duration
        rotate.repeatCount = Float.infinity
        rotate.autoreverses = true
        rotate.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)

        view.layer.allowsEdgeAntialiasing = true

        view.layer.addAnimation(rotate, forKey: "Rotate")
    }
}

