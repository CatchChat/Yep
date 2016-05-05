//
//  ShowStepGeniusViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/20.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class ShowStepGeniusViewController: ShowStepViewController {

    @IBOutlet private weak var rightPurpleDot: UIImageView!
    @IBOutlet private weak var leftGreenDot: UIImageView!
    @IBOutlet private weak var leftBlueDot: UIImageView!
    @IBOutlet private weak var leftRedDot: UIImageView!
    @IBOutlet private weak var leftPurpleDot: UIImageView!
    @IBOutlet private weak var topRedDot: UIImageView!
    @IBOutlet private weak var rightBlueDot: UIImageView!
    @IBOutlet private weak var centerBlueDot: UIImageView!
    @IBOutlet private weak var centerOrangeDot: UIImageView!
    @IBOutlet private weak var rightYellowDot: UIImageView!
    @IBOutlet private weak var rightGreenDot: UIImageView!

    @IBOutlet private weak var dotsLink: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = NSLocalizedString("Genius", comment: "")
        subTitleLabel.text = NSLocalizedString("Discover them around you", comment: "")
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

        let dotsLinkPath = UIBezierPath(arcCenter: dotsLink.center, radius: 5, startAngle: 0, endAngle: 2, clockwise: false)
        repeatAnimate(dotsLink, alongWithPath: dotsLinkPath, duration: 7, autoreverses: true)
    }
}

