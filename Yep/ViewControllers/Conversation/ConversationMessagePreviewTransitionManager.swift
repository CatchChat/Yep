//
//  ConversationMessagePreviewTransitionManager.swift
//  Yep
//
//  Created by NIX on 15/5/6.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ConversationMessagePreviewTransitionManager: NSObject, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {

    var frame = CGRectZero


    var isPresentation = false

    // MARK: UIViewControllerTransitioningDelegate

    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresentation = true

        return self
    }

    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresentation = false

        return self
    }

    // MARK: UIViewControllerAnimatedTransitioning

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 2.6
    }

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {

        if isPresentation {
            presentTransition(transitionContext)
        } else {
            dismissTransition(transitionContext)
        }
    }

    func presentTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)

        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)

        let containerView = transitionContext.containerView()

        containerView.addSubview(toView!)

        let animatingVC = toVC!
        let animatingView = toView!

        let finalFrame = transitionContext.finalFrameForViewController(animatingVC)

        animatingView.frame = frame

        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, options: .AllowUserInteraction | .BeginFromCurrentState, animations: { () -> Void in
            animatingView.frame = finalFrame

        }, completion: { (finished) -> Void in
            transitionContext.completeTransition(true)
        })
    }

    func dismissTransition(transitionContext: UIViewControllerContextTransitioning) {
        //let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
        //let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)

        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)
        //let toView = transitionContext.viewForKey(UITransitionContextToViewKey)

        //let containerView = transitionContext.containerView()

        //containerView.addSubview(toView!)

        //let animatingVC = fromVC!
        let animatingView = fromView!

        //let finalFrame = transitionContext.finalFrameForViewController(animatingVC)

        //animatingView.frame = frame

        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, options: .AllowUserInteraction | .BeginFromCurrentState, animations: { () -> Void in
            animatingView.frame = self.frame

        }, completion: { (finished) -> Void in
            animatingView.removeFromSuperview()
            transitionContext.completeTransition(true)
        })
    }
    
}