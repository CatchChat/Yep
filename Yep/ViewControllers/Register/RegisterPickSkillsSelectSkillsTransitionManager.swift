//
//  RegisterPickSkillsSelectSkillsTransitionManager.swift
//  Yep
//
//  Created by NIX on 15/4/20.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class RegisterPickSkillsSelectSkillsTransitionManager: NSObject, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {

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
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {

        return 0.6
    }

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {

        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)

        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)

        let containerView = transitionContext.containerView()

        if isPresentation {
            if let view = toView {
                containerView?.addSubview(view)
            }
        }

        let animatingVC = isPresentation ? toVC! : fromVC!
        let animatingView = isPresentation ? toView! : fromView!

        let onScreenFrame = transitionContext.finalFrameForViewController(animatingVC)
        let offScreenFrame = CGRectOffset(onScreenFrame, 0, CGRectGetHeight(onScreenFrame))

        let (initialFrame, finalFrame) = isPresentation ? (offScreenFrame, onScreenFrame) : (onScreenFrame, offScreenFrame)

        animatingView.frame = initialFrame

        if self.isPresentation {
            animatingView.alpha = 0
        } else {
            animatingView.alpha = 1
        }

        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, options: [.AllowUserInteraction, .BeginFromCurrentState], animations: { [unowned self] in
            animatingView.frame = finalFrame

            if self.isPresentation {
                animatingView.alpha = 1
            } else {
                animatingView.alpha = 0
            }

        }, completion: { [unowned self] _ in

            if !self.isPresentation {
                fromView?.removeFromSuperview()
            }

            transitionContext.completeTransition(true)
        })
    }
}

