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
    @IBOutlet weak var pageControlBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var finishButton: BorderButton!
    @IBOutlet weak var finishButtonBottomConstraint: NSLayoutConstraint!

    var steps = [UIViewController]()

    override func viewDidLoad() {
        super.viewDidLoad()

        finishButton.tintColor = UIColor.yepTintColor()
        finishButton.needShowAccessory = true
        
        pageControlBottomConstraint.constant = Ruler.iPhoneVertical(0, 10, 20, 30).value
        finishButtonBottomConstraint.constant = Ruler.iPhoneVertical(20, 30, 40, 50).value

        makeUI()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        scrollView.alpha = 0
        pageControl.alpha = 0
        finishButton.alpha = 0
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animateWithDuration(2, delay: 0.5, options: .CurveEaseInOut, animations: { [weak self] in
            self?.scrollView.alpha = 1
            self?.pageControl.alpha = 1
            self?.finishButton.alpha = 1
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

        //finishButton.alpha = 0
        finishButton.setTitle(NSLocalizedString("Get Started", comment: ""), forState: .Normal)

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

//        let isLastStep = (page == (steps.count - 1))
//
//        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
//            self.finishButton.alpha = isLastStep ? 1 : 0
//            //self.pageControl.alpha = isLastStep ? 0 : 1
//
//        }, completion: { _ in
//        })

        pageControl.currentPage = page
    }
}


