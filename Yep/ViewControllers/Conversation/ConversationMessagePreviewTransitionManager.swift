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
    var transitionView: UIView?



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
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as? ConversationsViewController
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as? MessageMediaViewController

        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)

        let containerView = transitionContext.containerView()

        containerView.addSubview(toView!)

        let animatingVC = toVC!
        let animatingView = toView!

        let finalFrame = transitionContext.finalFrameForViewController(animatingVC)

        let initialMaskPath = UIBezierPath(rect: frame)
        let finalMaskPath = UIBezierPath(rect: finalFrame)

        let maskLayer = CAShapeLayer()
        maskLayer.path = finalMaskPath.CGPath
        animatingView.layer.mask = maskLayer

        let maskLayerAnimation = CABasicAnimation(keyPath: "path")
        maskLayerAnimation.fromValue = finalMaskPath.CGPath
        maskLayerAnimation.toValue = finalMaskPath.CGPath
        maskLayerAnimation.duration = transitionDuration(transitionContext)
        maskLayerAnimation.delegate = self
        maskLayer.addAnimation(maskLayerAnimation, forKey: "path")



        if let transitionView = transitionView {
            animatingView.addSubview(transitionView)
            transitionView.frame = frame

            toVC?.view.backgroundColor = UIColor.clearColor()
            toVC?.mediaView.alpha = 0

            let fullDuration = transitionDuration(transitionContext)

            UIView.animateKeyframesWithDuration(fullDuration, delay: 0.0, options: .CalculationModeCubic, animations: { () -> Void in

                UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0.2, animations: { () -> Void in
                    animatingVC.view.backgroundColor = UIColor.whiteColor()
                })

                UIView.addKeyframeWithRelativeStartTime(0.2, relativeDuration: 0.5, animations: { () -> Void in
                    transitionView.center = animatingView.center
                })

                let largerOffset: CGFloat = 80

                UIView.addKeyframeWithRelativeStartTime(0.7, relativeDuration: 0.2, animations: { () -> Void in
                    let targetWidth = animatingView.bounds.width + largerOffset

                    let dw = targetWidth - transitionView.bounds.width
                    let ratio = targetWidth / transitionView.bounds.width
                    let height = ratio * transitionView.bounds.height
                    let dh = height - transitionView.bounds.height

                    let frame = CGRectInset(transitionView.frame, -dw * 0.5, -dh * 0.5)

                    transitionView.frame = frame
                })

                UIView.addKeyframeWithRelativeStartTime(0.9, relativeDuration: 0.0, animations: { () -> Void in
                    let ratio = (animatingView.bounds.width + largerOffset) / animatingView.bounds.width
                    toVC?.mediaView.transform = CGAffineTransformMakeScale(ratio, ratio)
                    toVC?.mediaView.alpha = 1
                    transitionView.alpha = 0
                })

                UIView.addKeyframeWithRelativeStartTime(0.9, relativeDuration: 0.1, animations: { () -> Void in
                    toVC?.mediaView.transform = CGAffineTransformMakeScale(1.0, 1.0)
                })

            }, completion: { (finished) -> Void in

            })

            #if YYY
            UIView.animateWithDuration(fullDuration * 0.2, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
                animatingVC.view.backgroundColor = UIColor.whiteColor()

            }, completion: { finished in
                UIView.animateWithDuration(fullDuration * 0.5, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.0, options: UIViewAnimationOptions(0), animations: { _ in
                    transitionView.center = animatingView.center

                }, completion: { finished in

                    let largerOffset: CGFloat = 80

                    UIView.animateWithDuration(fullDuration * 0.2, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.0, options: UIViewAnimationOptions(0), animations: { _ in

                        let targetWidth = animatingView.bounds.width + largerOffset

                        let dw = targetWidth - transitionView.bounds.width
                        let ratio = targetWidth / transitionView.bounds.width
                        let height = ratio * transitionView.bounds.height
                        let dh = height - transitionView.bounds.height

                        let frame = CGRectInset(transitionView.frame, -dw * 0.5, -dh * 0.5)

                        transitionView.frame = frame

                    }, completion: { finished in

                        let ratio = (animatingView.bounds.width + largerOffset) / animatingView.bounds.width
                        toVC?.mediaView.transform = CGAffineTransformMakeScale(ratio, ratio)
                        toVC?.mediaView.alpha = 1
                        transitionView.removeFromSuperview()

                        UIView.animateWithDuration(fullDuration * 0.1, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
                            toVC?.mediaView.transform = CGAffineTransformMakeScale(1.0, 1.0)
                        }, completion: { finished in
                            toVC?.mediaView.transform = CGAffineTransformIdentity
                        })
                    })
                })
            })
            #endif
        }
    }

    func dismissTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)

        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)

        let animatingVC = fromVC!
        let animatingView = fromView!

        let initialFrame = transitionContext.initialFrameForViewController(animatingVC)

        let initialMaskPath = UIBezierPath(rect: initialFrame)
        let finalMaskPath = UIBezierPath(rect: frame)

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

    #if XXX
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

        let initialMaskPath = UIBezierPath(rect: frame)
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
        let finalMaskPath = UIBezierPath(rect: frame)

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
    #endif

    override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        transitionContext?.completeTransition(true)
    }
}