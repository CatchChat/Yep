//
//  PhotoTransitonController.swift
//  Yep
//
//  Created by NIX on 16/6/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class PhotoTransitonController: NSObject {

    lazy var animator = PhotoTransitionAnimator()
    lazy var interactionController = PhotoDismissalInteractionController()

    var forcesNonInteractiveDismissal = true

    var startingReference: Reference? {
        return animator.startingReference
    }

    func setStartingReference(reference: Reference?) {
        animator.startingReference = reference
    }

    var endingReference: Reference? {
        return animator.endingReference
    }

    func setEndingReference(reference: Reference?) {
        animator.endingReference = reference
    }

    func didPanWithPanGestureRecognizer(pan: UIPanGestureRecognizer, viewToPan: UIView, anchorPoint: CGPoint) {

        interactionController.didPanWithPanGestureRecognizer(pan, viewToPan: viewToPan, anchorPoint: anchorPoint)
    }
}

extension PhotoTransitonController: UIViewControllerTransitioningDelegate {

    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        animator.isDismissing = false

        return animator
    }

    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        animator.isDismissing = true

        return animator
    }

    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {

        if forcesNonInteractiveDismissal {
            return nil
        }

        if let endingView = endingReference?.imageView {
            self.animator.endingViewForAnimation = PhotoTransitionAnimator.newAnimationViewFromView(endingView)
        }

        interactionController.animator = animator
        interactionController.shouldAnimateUsingAnimator = (endingReference?.view != nil)
        interactionController.viewToHideWhenBeginningTransition = (startingReference?.view == nil) ? nil : endingReference?.view

        return interactionController
    }
}

