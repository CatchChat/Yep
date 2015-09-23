//
//  ShowViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler

class ShowViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var pageControl: UIPageControl!

    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!

    var steps = [UIViewController]()

    override func viewDidLoad() {
        super.viewDidLoad()

        makeUI()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        scrollView.alpha = 0
        pageControl.alpha = 0
        registerButton.alpha = 0
        loginButton.alpha = 0
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animateWithDuration(2, delay: 0.5, options: .CurveEaseInOut, animations: { [weak self] in
            self?.scrollView.alpha = 1
            self?.pageControl.alpha = 1
            self?.registerButton.alpha = 1
            self?.loginButton.alpha = 1
        }, completion: { _ in })
    }

    func makeUI() {

        let stepA = stepGenius()
        let stepB = stepMatch()
        let stepC = stepMeet()

        steps = [stepA, stepB, stepC]

        pageControl.numberOfPages = steps.count
        pageControl.pageIndicatorTintColor = UIColor.lightGrayColor()
        pageControl.currentPageIndicatorTintColor = UIColor.yepTintColor()

        registerButton.setTitle(NSLocalizedString("Sign Up", comment: ""), forState: .Normal)
        loginButton.setTitle(NSLocalizedString("Login", comment: ""), forState: .Normal)

        let viewsDictionary = [
            "view": view,
            "stepA": stepA.view,
            "stepB": stepB.view,
            "stepC": stepC.view,
        ]

        let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[stepA(==view)]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(vConstraints)

        let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[stepA(==view)][stepB(==view)][stepC(==view)]|", options: [.AlignAllBottom, .AlignAllTop], metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(hConstraints)
    }

    private func stepGenius() -> ShowStepGeniusViewController {
        let step = storyboard!.instantiateViewControllerWithIdentifier("ShowStepGeniusViewController") as! ShowStepGeniusViewController

        step.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(step.view)

        addChildViewController(step)
        step.didMoveToParentViewController(self)

        return step
    }

    private func stepMatch() -> ShowStepMatchViewController {
        let step = storyboard!.instantiateViewControllerWithIdentifier("ShowStepMatchViewController") as! ShowStepMatchViewController

        step.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(step.view)

        addChildViewController(step)
        step.didMoveToParentViewController(self)

        return step
    }

    private func stepMeet() -> ShowStepMeetViewController {
        let step = storyboard!.instantiateViewControllerWithIdentifier("ShowStepMeetViewController") as! ShowStepMeetViewController

        step.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(step.view)

        addChildViewController(step)
        step.didMoveToParentViewController(self)

        return step
    }

    // MARK: Actions

    @IBAction func finish(sender: UIButton) {

        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            if YepUserDefaults.isLogined {
                appDelegate.startMainStory()
            } else {
                appDelegate.startIntroStory()
            }
        }
    }
    
}

// MARK: - UIScrollViewDelegate

extension ShowViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(scrollView: UIScrollView) {

        let pageWidth = CGRectGetWidth(scrollView.bounds)
        let pageFraction = scrollView.contentOffset.x / pageWidth

        let page = Int(round(pageFraction))

        pageControl.currentPage = page
    }
}


