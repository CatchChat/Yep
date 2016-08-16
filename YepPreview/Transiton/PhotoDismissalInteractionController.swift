//
//  PhotoDismissalInteractionController.swift
//  Yep
//
//  Created by NIX on 16/6/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class PhotoDismissalInteractionController: NSObject {

    var animator: UIViewControllerAnimatedTransitioning?
    var transitionContext: UIViewControllerContextTransitioning?
    var viewToHideWhenBeginningTransition: UIView?

    var shouldAnimateUsingAnimator = true

    private let panDismissDistanceRatio: CGFloat = 50.0 / 667.0
    private let panDismissMaximumDuration: CGFloat = 0.45
    private let returnToCenterVelocityAnimationRatio: CGFloat = 0.00007

    func didPanWithPanGestureRecognizer(pan: UIPanGestureRecognizer, viewToPan: UIView, anchorPoint: CGPoint) {

        guard let fromView = transitionContext?.viewForKey(UITransitionContextFromViewKey) else {
            return
        }

        let translatedPanGesturePoint = pan.translationInView(fromView)
        let newCenterPoint = CGPoint(x: anchorPoint.x, y: anchorPoint.y + translatedPanGesturePoint.y)

        let viewToPan = viewToPan
        viewToPan.center = newCenterPoint

        let verticalDelta = newCenterPoint.y - anchorPoint.y
        let backgroundAlpha = backgroundAlphaForPanningWithVerticalDelta(verticalDelta)
        fromView.backgroundColor = fromView.backgroundColor?.colorWithAlphaComponent(backgroundAlpha)

        if pan.state == .Ended {
            finishPanWithPanGestureRecognizer(pan, verticalDelta: verticalDelta, viewToPan: viewToPan, anchorPoint: anchorPoint)
        }
    }

    private func backgroundAlphaForPanningWithVerticalDelta(verticalDelta: CGFloat) -> CGFloat {

        guard let fromView = transitionContext?.viewForKey(UITransitionContextFromViewKey) else {
            return 1
        }

        let startingAlpha: CGFloat = 1
        let finalAlpha: CGFloat = 0.1
        let totalAvailableAlpha = startingAlpha - finalAlpha

        let maximumDelta = fromView.bounds.height / 2
        let deltaAsPercentageOfMaximum = min(abs(verticalDelta) / maximumDelta, 1)

        return startingAlpha - (deltaAsPercentageOfMaximum * totalAvailableAlpha)
    }

    private func finishPanWithPanGestureRecognizer(pan: UIPanGestureRecognizer, verticalDelta: CGFloat, viewToPan: UIView, anchorPoint: CGPoint) {

        guard let fromView = transitionContext?.viewForKey(UITransitionContextFromViewKey) else {
            return
        }

        let velocityY = pan.velocityInView(pan.view).y
        var animationDuration = (abs(velocityY) * returnToCenterVelocityAnimationRatio) + 0.2

        let animationCurve: UIViewAnimationOptions = [.CurveEaseOut]
        var finalPageViewCenterPoint = anchorPoint
        var finalBackgroundAlpha: CGFloat = 1.0

        let dismissDistance = panDismissDistanceRatio * fromView.bounds.height
        let isDismissing = abs(verticalDelta) > dismissDistance

        var didAnimateUsingAnimator = false

        if isDismissing {
            if shouldAnimateUsingAnimator {
                if let transitionContext = transitionContext {
                    animator?.animateTransition(transitionContext)
                }

                didAnimateUsingAnimator = true

            } else {
                let isPositiveDelta = verticalDelta >= 0
                let modifier: CGFloat = isPositiveDelta ? 1 : -1

                let finalCenterY = fromView.bounds.midY + modifier * fromView.bounds.height
                finalPageViewCenterPoint = CGPoint(x: fromView.center.x, y: finalCenterY)

                animationDuration = abs(finalPageViewCenterPoint.y - viewToPan.center.y) / abs(velocityY)
                animationDuration = min(animationDuration, panDismissMaximumDuration)

                finalBackgroundAlpha = 0
            }
        }

        if !didAnimateUsingAnimator {

            UIView.animateWithDuration(NSTimeInterval(animationDuration), delay: 0, options: animationCurve, animations: {
                viewToPan.center = finalPageViewCenterPoint
                fromView.backgroundColor = fromView.backgroundColor?.colorWithAlphaComponent(finalBackgroundAlpha)

            }, completion: { [unowned self] finished in
                if isDismissing {
                    self.transitionContext?.finishInteractiveTransition()
                } else {
                    self.transitionContext?.cancelInteractiveTransition()
                }

                self.viewToHideWhenBeginningTransition?.alpha = 1

                let didComplete = isDismissing && !(self.transitionContext?.transitionWasCancelled() ?? true)
                self.transitionContext?.completeTransition(didComplete)

                self.transitionContext = nil
            })

        } else {
            self.transitionContext = nil
        }
    }
}

extension PhotoDismissalInteractionController: UIViewControllerInteractiveTransitioning {

    func startInteractiveTransition(transitionContext: UIViewControllerContextTransitioning) {

        viewToHideWhenBeginningTransition?.alpha = 0
        
        self.transitionContext = transitionContext
    }
}

