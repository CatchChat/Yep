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

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        isPresentation = true

        return self
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        isPresentation = false

        return self
    }

    // MARK: UIViewControllerAnimatedTransitioning
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {

        return 0.6
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)
        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)

        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)

        let containerView = transitionContext.containerView

        if isPresentation {
            if let view = toView {
                containerView.addSubview(view)
            }
        }

        let animatingVC = isPresentation ? toVC! : fromVC!
        let animatingView = isPresentation ? toView! : fromView!

        let onScreenFrame = transitionContext.finalFrame(for: animatingVC)
        let offScreenFrame = onScreenFrame.offsetBy(dx: 0, dy: onScreenFrame.height)

        let (initialFrame, finalFrame) = isPresentation ? (offScreenFrame, onScreenFrame) : (onScreenFrame, offScreenFrame)

        animatingView.frame = initialFrame

        if self.isPresentation {
            animatingView.alpha = 0
        } else {
            animatingView.alpha = 1
        }

        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: { [unowned self] in
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

