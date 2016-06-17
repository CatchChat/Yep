//
//  PhotoTransitionAnimator.swift
//  Yep
//
//  Created by NIX on 16/6/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class PhotoTransitionAnimator: NSObject {

    var startingView: UIView?
    var endingView: UIView?

    var startingViewForAnimation: UIView?
    var endingViewForAnimation: UIView?

    var isDismissing: Bool = false

    var animationDurationWithZooming: NSTimeInterval = 0.5
    var animationDurationWithoutZooming: NSTimeInterval = 0.3

    var animationDurationFadeRatio: CGFloat = 4
    var animationDurationEndingViewFadeInRatio: CGFloat = 0.1
    var animationDurationStartingViewFadeOutRatio: CGFloat = 0.05

    var zoomingAnimationSpringDamping: CGFloat = 0.9
}

extension PhotoTransitionAnimator: UIViewControllerAnimatedTransitioning {

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {

        return animationDurationWithoutZooming
    }

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {

        setupTransitionContainerHierarchyWithTransitionContext(transitionContext)
    }

    private func setupTransitionContainerHierarchyWithTransitionContext(transitionContext: UIViewControllerContextTransitioning) {

        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)!
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!

        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!

        toView.frame = transitionContext.finalFrameForViewController(toViewController)

        let containerView = transitionContext.containerView()!

        if !toView.isDescendantOfView(containerView) {
            containerView.addSubview(toView)
        }

        if isDismissing {
            containerView.bringSubviewToFront(fromView)
        }
    }
}

