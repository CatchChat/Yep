//
//  ShowViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ShowViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!


    override func viewDidLoad() {
        super.viewDidLoad()

        makeUI()
    }

    func makeUI() {

        let stepA = step("Yep Intro")
        let stepB = step("Yep Intro")
        let stepC = step("Yep Intro")

        stepA.view.backgroundColor = UIColor.redColor()
        stepB.view.backgroundColor = UIColor.blueColor()
        stepC.view.backgroundColor = UIColor.greenColor()

        let steps = [stepA, stepB, stepC]

        let viewsDictionary = [
            "view": view,
            "stepA": stepA.view,
            "stepB": stepB.view,
            "stepC": stepC.view,
        ]

        let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[stepA(==view)]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        view.addConstraints(vConstraints)

        let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[stepA(==view)][stepB(==view)][stepC(==view)]|", options: .AlignAllBottom | .AlignAllTop, metrics: nil, views: viewsDictionary)

        view.addConstraints(hConstraints)
    }

    private func step(name: String) -> ShowStepViewController {

        let step = storyboard!.instantiateViewControllerWithIdentifier("ShowStepViewController") as! ShowStepViewController

        step.showName = name

        step.view.setTranslatesAutoresizingMaskIntoConstraints(false)
        scrollView.addSubview(step.view)

        addChildViewController(step)
        step.didMoveToParentViewController(self)

        return step
    }
}
