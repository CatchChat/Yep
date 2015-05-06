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


    let largerOffset: CGFloat = 80

    func presentTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as? ConversationsViewController
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as? MessageMediaViewController

        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)

        let containerView = transitionContext.containerView()

        containerView.addSubview(toView!)

        let animatingVC = toVC!
        let animatingView = toView!

        if let transitionView = transitionView {
            animatingView.addSubview(transitionView)
            transitionView.frame = frame

            animatingVC.view.backgroundColor = UIColor.clearColor()
            animatingVC.mediaView.alpha = 0

            let fullDuration = transitionDuration(transitionContext)

            UIView.animateKeyframesWithDuration(fullDuration, delay: 0.0, options: .CalculationModeCubic, animations: { () -> Void in

                UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0.2, animations: { () -> Void in
                    animatingVC.view.backgroundColor = UIColor.whiteColor()
                })

                UIView.addKeyframeWithRelativeStartTime(0.2, relativeDuration: 0.5, animations: { () -> Void in
                    transitionView.center = animatingView.center
                })


                UIView.addKeyframeWithRelativeStartTime(0.7, relativeDuration: 0.2, animations: { () -> Void in
                    let targetWidth = animatingView.bounds.width + self.largerOffset

                    let dw = targetWidth - transitionView.bounds.width
                    let ratio = targetWidth / transitionView.bounds.width
                    let height = ratio * transitionView.bounds.height
                    let dh = height - transitionView.bounds.height

                    let frame = CGRectInset(transitionView.frame, -dw * 0.5, -dh * 0.5)

                    transitionView.frame = frame
                })

                UIView.addKeyframeWithRelativeStartTime(0.9, relativeDuration: 0.0, animations: { () -> Void in
                    let ratio = (animatingView.bounds.width + self.largerOffset) / animatingView.bounds.width
                    animatingVC.mediaView.transform = CGAffineTransformMakeScale(ratio, ratio)
                    animatingVC.mediaView.alpha = 1
                    transitionView.alpha = 0
                })

                UIView.addKeyframeWithRelativeStartTime(0.9, relativeDuration: 0.1, animations: { () -> Void in
                    animatingVC.mediaView.transform = CGAffineTransformMakeScale(1.0, 1.0)
                })

            }, completion: { (finished) -> Void in
                transitionView.removeFromSuperview()

                transitionContext.completeTransition(true)
            })

        } else {
            transitionContext.completeTransition(false)
        }
    }

    func dismissTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as? MessageMediaViewController

        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)

        let animatingVC = fromVC!
        let animatingView = fromView!

        let fullDuration = transitionDuration(transitionContext)

        if let transitionView = transitionView {

            UIView.animateKeyframesWithDuration(fullDuration, delay: 0.0, options: .CalculationModeCubic, animations: { () -> Void in

                UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 0.2, animations: { () -> Void in
                    let ratio = (animatingView.bounds.width + self.largerOffset) / animatingView.bounds.width
                    animatingVC.mediaView.transform = CGAffineTransformMakeScale(ratio, ratio)
                })

                UIView.addKeyframeWithRelativeStartTime(0.2, relativeDuration: 0.0, animations: { () -> Void in
                    animatingView.addSubview(transitionView)
                    transitionView.center = animatingView.center
                    transitionView.alpha = 1

                    animatingVC.mediaView.alpha = 0
                })

                UIView.addKeyframeWithRelativeStartTime(0.2, relativeDuration: 0.6, animations: { () -> Void in
                    transitionView.frame = self.frame
                })

                UIView.addKeyframeWithRelativeStartTime(0.8, relativeDuration: 0.2, animations: { () -> Void in
                    animatingVC.view.backgroundColor = UIColor.clearColor()
                })

            }, completion: { (finished) -> Void in
                transitionView.removeFromSuperview()

                transitionContext.completeTransition(true)
            })

        } else {
            transitionContext.completeTransition(false)
        }
    }
}