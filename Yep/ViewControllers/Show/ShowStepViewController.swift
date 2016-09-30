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
    @IBOutlet fileprivate weak var titleLabelBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet fileprivate weak var subTitleLabelBottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.textColor = UIColor.yepTintColor()

        titleLabelBottomConstraint.constant = Ruler.iPhoneVertical(20, 30, 30, 30).value
        subTitleLabelBottomConstraint.constant = Ruler.iPhoneVertical(120, 140, 160, 180).value
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        view.alpha = 0
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
            self?.view.alpha = 1
        }, completion: { _ in })
    }

    func repeatAnimate(_ view: UIView, alongWithPath path: UIBezierPath, duration: CFTimeInterval, autoreverses: Bool = false) {

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

        animation.path = path.cgPath

        view.layer.add(animation, forKey: "Animation")
    }

    func animate(_ view: UIView, offset: UInt32, duration: CFTimeInterval) {

        let path = UIBezierPath()

        func flip() -> CGFloat {
            return arc4random() % 2 == 0 ? -1 : 1
        }

        let beginPoint = CGPoint(x: view.center.x + CGFloat(arc4random() % offset) * flip(), y: view.center.y + CGFloat(arc4random() % offset) * 0.5 * flip())
        let endPoint = CGPoint(x: view.center.x + CGFloat(arc4random() % offset) * flip(), y: view.center.y + CGFloat(arc4random() % offset) * 0.5 * flip())
        path.move(to: beginPoint)
        path.addLine(to: endPoint)

        repeatAnimate(view, alongWithPath: path, duration: duration, autoreverses: true)

        repeatRotate(view, fromValue: -0.1, toValue: 0.1, duration: duration)
    }

    fileprivate func repeatRotate(_ view: UIView, fromValue: Any, toValue: Any, duration: CFTimeInterval) {

        let rotate = CABasicAnimation(keyPath: "transform.rotation.z")

        rotate.fromValue = fromValue
        rotate.toValue = toValue
        rotate.duration = duration
        rotate.repeatCount = Float.infinity
        rotate.autoreverses = true
        rotate.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)

        view.layer.allowsEdgeAntialiasing = true

        view.layer.add(rotate, forKey: "Rotate")
    }
}

