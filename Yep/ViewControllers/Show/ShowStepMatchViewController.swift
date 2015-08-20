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

        animate(camera, offset: 10, duration: 4)
        animate(pen, offset: 5, duration: 5)
        animate(book, offset: 10, duration: 3)
        animate(controller, offset: 15, duration: 2)
        animate(keyboard, offset: 20, duration: 4)
    }

    private func animate(view: UIView, offset: UInt32, duration: CFTimeInterval) {

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

        view.layer.addAnimation(rotate, forKey: "Rotate")
    }
}

