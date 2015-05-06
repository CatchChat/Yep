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

    var transitionContext: UIViewControllerContextTransitioning?

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
        return isPresentation ? 0.5 : 0.5
    }

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {

        self.transitionContext = transitionContext

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

        let initialMaskPath = UIBezierPath(rect: CGRectInset(frame, 50, 0))
        let finalMaskPath = UIBezierPath(rect: finalFrame)

        let maskLayer = CAShapeLayer()
        maskLayer.path = finalMaskPath.CGPath
        animatingView.layer.mask = maskLayer

        let maskLayerAnimation = CABasicAnimation(keyPath: "path")
        maskLayerAnimation.fromValue = initialMaskPath.CGPath
        maskLayerAnimation.toValue = finalMaskPath.CGPath
        maskLayerAnimation.duration = transitionDuration(transitionContext)
        maskLayerAnimation.delegate = self
        maskLayer.addAnimation(maskLayerAnimation, forKey: "path")
    }

    func dismissTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)

        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)

        let animatingVC = fromVC!
        let animatingView = fromView!

        let initialFrame = transitionContext.initialFrameForViewController(animatingVC)

        let initialMaskPath = UIBezierPath(rect: initialFrame)
        let finalMaskPath = UIBezierPath(rect: CGRectInset(frame, 50, 0))

        let maskLayer = CAShapeLayer()
        maskLayer.path = finalMaskPath.CGPath
        animatingView.layer.mask = maskLayer

        let maskLayerAnimation = CABasicAnimation(keyPath: "path")
        maskLayerAnimation.fromValue = initialMaskPath.CGPath
        maskLayerAnimation.toValue = finalMaskPath.CGPath
        maskLayerAnimation.duration = transitionDuration(transitionContext)
        maskLayerAnimation.delegate = self
        maskLayerAnimation.removedOnCompletion = true
        maskLayer.addAnimation(maskLayerAnimation, forKey: "path")
    }

    override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        transitionContext?.completeTransition(true)
    }
    
}