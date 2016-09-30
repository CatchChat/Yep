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

    @IBOutlet fileprivate weak var scrollView: UIScrollView!

    @IBOutlet fileprivate weak var pageControl: UIPageControl!

    @IBOutlet fileprivate weak var registerButton: UIButton!
    @IBOutlet fileprivate weak var loginButton: EdgeBorderButton!

    fileprivate var steps = [UIViewController]()

    override func viewDidLoad() {
        super.viewDidLoad()

        makeUI()
    }

    fileprivate var isFirstAppear = true

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)

        if isFirstAppear {
            scrollView.alpha = 0
            pageControl.alpha = 0
            registerButton.alpha = 0
            loginButton.alpha = 0
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if isFirstAppear {
            UIView.animate(withDuration: 1, delay: 0.5, options: .curveEaseInOut, animations: { [weak self] in
                self?.scrollView.alpha = 1
                self?.pageControl.alpha = 1
                self?.registerButton.alpha = 1
                self?.loginButton.alpha = 1
            }, completion: nil)
        }

        isFirstAppear = false
    }

    fileprivate func makeUI() {

        steps = makeSteps()

        pageControl.numberOfPages = steps.count
        pageControl.pageIndicatorTintColor = UIColor.yepBorderColor()
        pageControl.currentPageIndicatorTintColor = UIColor.yepTintColor()

        registerButton.setTitle(NSLocalizedString("Sign Up", comment: ""), for: .normal)
        loginButton.setTitle(String.trans_titleLogin, for: .normal)

        registerButton.backgroundColor = UIColor.yepTintColor()
        loginButton.setTitleColor(UIColor.yepInputTextColor(), for: .normal)

        let views: [String: Any] = [
            "view": view,
            "stepA": steps[0].view,
            "stepB": steps[1].view,
            "stepC": steps[2].view,
        ]

        let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[stepA(==view)]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activate(vConstraints)

        let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[stepA(==view)][stepB(==view)][stepC(==view)]|", options: [.alignAllBottom, .alignAllTop], metrics: nil, views: views)

        NSLayoutConstraint.activate(hConstraints)
    }

    fileprivate func makeSteps() -> [UIViewController] {

        let steps: [UIViewController] = [
            UIStoryboard.Scene.showStepGenius,
            UIStoryboard.Scene.showStepMatch,
            UIStoryboard.Scene.showStepMeet,
        ]

        steps.forEach({ step in
            step.view.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(step.view)

            addChildViewController(step)
            step.didMove(toParentViewController: self)
        })

        return steps
    }
}

// MARK: - UIScrollViewDelegate

extension ShowViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        let pageWidth = scrollView.bounds.width
        let pageFraction = scrollView.contentOffset.x / pageWidth

        let page = Int(round(pageFraction))

        pageControl.currentPage = page
    }
}

