//
//  ShowStepMatchViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/20.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ShowStepMatchViewController: ShowStepViewController {

    @IBOutlet weak var camera: UIImageView!
    @IBOutlet weak var pen: UIImageView!
    @IBOutlet weak var book: UIImageView!
    @IBOutlet weak var controller: UIImageView!
    @IBOutlet weak var keyboard: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        animateKeyboard()
    }

    private func animateKeyboard() {

        let keyboardPath = UIBezierPath()

        let offset: UInt32 = 20
        let beginPoint = CGPoint(x: keyboard.center.x - CGFloat(arc4random() % offset), y: keyboard.center.y + CGFloat(arc4random() % offset) * 0.5 * (arc4random() % 2 == 0 ? -1 : 1))
        let endPoint = CGPoint(x: keyboard.center.x + CGFloat(arc4random() % offset), y: keyboard.center.y + CGFloat(arc4random() % offset) * 0.5 * (arc4random() % 2 == 0 ? -1 : 1))
        keyboardPath.moveToPoint(beginPoint)
        keyboardPath.addLineToPoint(endPoint)

        repeatAnimate(keyboard, alongWithPath: keyboardPath, duration: 4, autoreverses: true)

        repeatRotate(keyboard, fromValue: -0.1, toValue: 0.1, duration: 3)
   }

    private func repeatRotate(view: UIView, fromValue: AnyObject, toValue: AnyObject, duration: CFTimeInterval) {
        let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
        rotate.fromValue = fromValue
        rotate.toValue = toValue
        rotate.duration = duration
        rotate.repeatCount = Float.infinity
        rotate.autoreverses = true
        rotate.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)

        view.layer.addAnimation(rotate, forKey: "Rotate")
    }
}

