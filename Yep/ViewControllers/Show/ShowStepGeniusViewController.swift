//
//  ShowStepGeniusViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/20.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class ShowStepGeniusViewController: ShowStepViewController {

    @IBOutlet fileprivate weak var rightPurpleDot: UIImageView!
    @IBOutlet fileprivate weak var leftGreenDot: UIImageView!
    @IBOutlet fileprivate weak var leftBlueDot: UIImageView!
    @IBOutlet fileprivate weak var leftRedDot: UIImageView!
    @IBOutlet fileprivate weak var leftPurpleDot: UIImageView!
    @IBOutlet fileprivate weak var topRedDot: UIImageView!
    @IBOutlet fileprivate weak var rightBlueDot: UIImageView!
    @IBOutlet fileprivate weak var centerBlueDot: UIImageView!
    @IBOutlet fileprivate weak var centerOrangeDot: UIImageView!
    @IBOutlet fileprivate weak var rightYellowDot: UIImageView!
    @IBOutlet fileprivate weak var rightGreenDot: UIImageView!

    @IBOutlet fileprivate weak var dotsLink: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = String.trans_showGenius
        subTitleLabel.text = String.trans_showDiscoverThem
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        repeatAnimate(rightPurpleDot, alongWithPath: UIBezierPath(ovalIn: rightPurpleDot.frame.insetBy(dx: 2, dy: 2)), duration: 4)
        repeatAnimate(leftGreenDot, alongWithPath: UIBezierPath(ovalIn: leftGreenDot.frame.insetBy(dx: 5, dy: 5)), duration: 2.5)
        repeatAnimate(leftBlueDot, alongWithPath: UIBezierPath(ovalIn: leftBlueDot.frame.insetBy(dx: 3, dy: 3)), duration: 4)
        repeatAnimate(leftRedDot, alongWithPath: UIBezierPath(ovalIn: leftRedDot.frame.insetBy(dx: 3, dy: 3)), duration: 1.5)
        repeatAnimate(leftPurpleDot, alongWithPath: UIBezierPath(ovalIn: leftPurpleDot.frame.insetBy(dx: 1, dy: 1)), duration: 6)
        repeatAnimate(topRedDot, alongWithPath: UIBezierPath(ovalIn: topRedDot.frame.insetBy(dx: 1, dy: 1)), duration: 2)
        repeatAnimate(rightBlueDot, alongWithPath: UIBezierPath(ovalIn: rightBlueDot.frame.insetBy(dx: 1, dy: 1)), duration: 3)
        repeatAnimate(centerBlueDot, alongWithPath: UIBezierPath(ovalIn: centerBlueDot.frame.insetBy(dx: 1, dy: 1)), duration: 3)
        repeatAnimate(centerOrangeDot, alongWithPath: UIBezierPath(ovalIn: centerOrangeDot.frame.insetBy(dx: 1, dy: 1)), duration: 3)
        repeatAnimate(rightYellowDot, alongWithPath: UIBezierPath(ovalIn: rightYellowDot.frame.insetBy(dx: 1, dy: 1)), duration: 3)
        repeatAnimate(rightGreenDot, alongWithPath: UIBezierPath(ovalIn: rightGreenDot.frame.insetBy(dx: 1, dy: 1)), duration: 3)

        let dotsLinkPath = UIBezierPath(arcCenter: dotsLink.center, radius: 5, startAngle: 0, endAngle: 2, clockwise: false)
        repeatAnimate(dotsLink, alongWithPath: dotsLinkPath, duration: 7, autoreverses: true)
    }
}

