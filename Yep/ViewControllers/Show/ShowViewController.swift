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

    @IBOutlet weak var pageControl: UIPageControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        makeUI()
    }

    func makeUI() {

        let stepA = step("Yep Intro")
        let stepB = step("Yep Intro")
        let stepC = step("Yep Intro", finishAction: {
            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                if let _ = YepUserDefaults.v1AccessToken.value {
                    appDelegate.startMainStory()
                } else {
                    appDelegate.startIntroStory()
                }
            }
        })

        let steps = [stepA, stepB, stepC]

        pageControl.numberOfPages = steps.count
        pageControl.pageIndicatorTintColor = UIColor.lightGrayColor()
        pageControl.currentPageIndicatorTintColor = UIColor.yepTintColor()

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

    private func step(name: String, finishAction: ShowStepViewController.FinishAction? = nil) -> ShowStepViewController {

        let step = storyboard!.instantiateViewControllerWithIdentifier("ShowStepViewController") as! ShowStepViewController

        step.showName = name
        step.finishAction = finishAction

        step.view.setTranslatesAutoresizingMaskIntoConstraints(false)
        scrollView.addSubview(step.view)

        addChildViewController(step)
        step.didMoveToParentViewController(self)

        return step
    }
}

// MARK: - UIScrollViewDelegate

extension ShowViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(scrollView: UIScrollView) {

        let pageWidth = CGRectGetWidth(scrollView.bounds)
        let pageFraction = scrollView.contentOffset.x / pageWidth

        pageControl.currentPage = Int(round(pageFraction))
    }
}


