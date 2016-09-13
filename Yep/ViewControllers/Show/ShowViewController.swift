//
//  ShowViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler

final class ShowViewController: UIViewController {

    @IBOutlet private weak var scrollView: UIScrollView!

    @IBOutlet private weak var pageControl: UIPageControl!

    @IBOutlet private weak var registerButton: UIButton!
    @IBOutlet private weak var loginButton: EdgeBorderButton!

    private var steps = [UIViewController]()

    override func viewDidLoad() {
        super.viewDidLoad()

        makeUI()
    }

    private var isFirstAppear = true

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
            }, completion: nil)
        }

        isFirstAppear = false
    }

    private func makeUI() {

        steps = makeSteps()

        pageControl.numberOfPages = steps.count
        pageControl.pageIndicatorTintColor = UIColor.yepBorderColor()
        pageControl.currentPageIndicatorTintColor = UIColor.yepTintColor()

        registerButton.setTitle(NSLocalizedString("Sign Up", comment: ""), forState: .Normal)
        loginButton.setTitle(String.trans_titleLogin, forState: .Normal)

        registerButton.backgroundColor = UIColor.yepTintColor()
        loginButton.setTitleColor(UIColor.yepInputTextColor(), forState: .Normal)

        let views: [String: AnyObject] = [
            "view": view,
            "stepA": steps[0].view,
            "stepB": steps[1].view,
            "stepC": steps[2].view,
        ]

        let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[stepA(==view)]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activateConstraints(vConstraints)

        let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[stepA(==view)][stepB(==view)][stepC(==view)]|", options: [.AlignAllBottom, .AlignAllTop], metrics: nil, views: views)

        NSLayoutConstraint.activateConstraints(hConstraints)
    }

    private func makeSteps() -> [UIViewController] {

        let steps: [UIViewController] = [
            UIStoryboard.Scene.showStepGenius,
            UIStoryboard.Scene.showStepMatch,
            UIStoryboard.Scene.showStepMeet,
        ]

        steps.forEach({ step in
            step.view.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(step.view)

            addChildViewController(step)
            step.didMoveToParentViewController(self)
        })

        return steps
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

