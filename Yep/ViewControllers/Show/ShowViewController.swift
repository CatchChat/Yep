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

    @IBOutlet private weak var scrollView: UIScrollView!

    @IBOutlet private weak var pageControl: UIPageControl!

    @IBOutlet private weak var registerButton: UIButton!
    @IBOutlet private weak var loginButton: EdgeBorderButton!

    private var isFirstAppear = true

    private var steps = [UIViewController]()

    override func viewDidLoad() {
        super.viewDidLoad()

        makeUI()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)

        if isFirstAppear {
            scrollView.alpha = 0
            pageControl.alpha = 0
            registerButton.alpha = 0
            loginButton.alpha = 0
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if isFirstAppear {
            UIView.animateWithDuration(1, delay: 0.5, options: .CurveEaseInOut, animations: { [weak self] in
                self?.scrollView.alpha = 1
                self?.pageControl.alpha = 1
                self?.registerButton.alpha = 1
                self?.loginButton.alpha = 1
            }, completion: { _ in })
        }

        isFirstAppear = false
    }

    private func makeUI() {

        let stepA = stepGenius()
        let stepB = stepMatch()
        let stepC = stepMeet()

        steps = [stepA, stepB, stepC]

        pageControl.numberOfPages = steps.count
        pageControl.pageIndicatorTintColor = UIColor.yepBorderColor()
        pageControl.currentPageIndicatorTintColor = UIColor.yepTintColor()

        registerButton.setTitle(NSLocalizedString("Sign Up", comment: ""), forState: .Normal)
        loginButton.setTitle(NSLocalizedString("Login", comment: ""), forState: .Normal)

        registerButton.backgroundColor = UIColor.yepTintColor()
        loginButton.setTitleColor(UIColor.yepInputTextColor(), forState: .Normal)

        let viewsDictionary = [
            "view": view,
            "stepA": stepA.view,
            "stepB": stepB.view,
            "stepC": stepC.view,
        ]

        let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[stepA(==view)]|", options: [], metrics: nil, views: viewsDictionary)

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
    
    @IBAction private func register(sender: UIButton) {
        let storyboard = UIStoryboard(name: "Intro", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("RegisterPickNameViewController") as! RegisterPickNameViewController

        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction private func login(sender: UIButton) {
        let storyboard = UIStoryboard(name: "Intro", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("LoginByMobileViewController") as! LoginByMobileViewController

        navigationController?.pushViewController(vc, animated: true)
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

