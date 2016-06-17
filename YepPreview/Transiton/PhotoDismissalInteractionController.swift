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

    func didPanWithPanGestureRecognizer(pan: UIPanGestureRecognizer, viewToPan: UIView, anchorPoint: CGPoint) {

        let fromView = transitionContext!.viewForKey(UITransitionContextFromViewKey)!
        let translatedPanGesturePoint = pan.translationInView(fromView)
        let newCenterPoint = CGPoint(x: anchorPoint.x, y: anchorPoint.y + translatedPanGesturePoint.y)

        let viewToPan = viewToPan
        viewToPan.center = newCenterPoint

        let verticalDelta = newCenterPoint.y - anchorPoint.y
        let backgroundAlpha = backgroundAlphaForPanningWithVerticalDelta(verticalDelta)
        fromView.backgroundColor = fromView.backgroundColor?.colorWithAlphaComponent(backgroundAlpha)

        if pan.state == .Ended {

        }
    }

    private func backgroundAlphaForPanningWithVerticalDelta(verticalDelta: CGFloat) -> CGFloat {

        let startingAlpha: CGFloat = 1
        let finalAlpha: CGFloat = 0.1
        let totalAvailableAlpha = startingAlpha - finalAlpha

        let fromView = transitionContext!.viewForKey(UITransitionContextFromViewKey)!

        let maximumDelta = fromView.bounds.height / 2
        let deltaAsPercentageOfMaximum = min(abs(verticalDelta) / maximumDelta, 1)

        return startingAlpha - (deltaAsPercentageOfMaximum * totalAvailableAlpha)
    }
}

