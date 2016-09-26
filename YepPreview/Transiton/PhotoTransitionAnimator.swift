//
//  PhotoTransitionAnimator.swift
//  Yep
//
//  Created by NIX on 16/6/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class PhotoTransitionAnimator: NSObject {

    var startingReference: Reference?
    var endingReference: Reference?

    var startingViewForAnimation: UIView?
    var endingViewForAnimation: UIView?

    var isDismissing: Bool = false

    var animationDurationWithZooming: TimeInterval = 0.4
    var animationDurationWithoutZooming: TimeInterval = 0.3

    var animationDurationFadeRatio: TimeInterval = 4.0 / 9.0
    var animationDurationEndingViewFadeInRatio: TimeInterval = 0.1
    var animationDurationStartingViewFadeOutRatio: TimeInterval = 0.05

    var zoomingAnimationSpringDamping: CGFloat = 0.9

    var shouldPerformZoomingAnimation: Bool {
        return (startingReference != nil) && (endingReference != nil)
    }

    fileprivate class func newViewFromView(_ view: UIView) -> UIView {

        let newView: UIView

        if view.layer.contents != nil {

            if let image = (view as? UIImageView)?.image {
                newView = UIImageView(image: image)
                newView.bounds = view.bounds

            } else {
                newView = UIView()
                newView.layer.contents = view.layer.contents
                newView.layer.bounds = view.layer.bounds
            }

            newView.layer.cornerRadius = view.layer.cornerRadius
            newView.layer.masksToBounds = view.layer.masksToBounds
            newView.contentMode = view.contentMode
            newView.transform = view.transform

        } else {
            newView = view.snapshotView(afterScreenUpdates: true)!
        }

        return newView
    }

    class func newAnimationViewFromView(_ view: UIView) -> UIView {

        return newViewFromView(view)
    }

    class func centerPointForView(_ view: UIView, translatedToContainerView containerView: UIView) -> CGPoint {

        guard let superview = view.superview else {
            fatalError("No superview")
        }

        var centerPoint = view.center

        if let scrollView = superview as? UIScrollView {
            if scrollView.zoomScale != 1.0 {
                centerPoint.x += (scrollView.bounds.width - scrollView.contentSize.width) / 2 + scrollView.contentOffset.x
                centerPoint.y += (scrollView.bounds.height - scrollView.contentSize.height) / 2 + scrollView.contentOffset.y
            }
        }

        return superview.convert(centerPoint, to: containerView)
    }
}

extension PhotoTransitionAnimator: UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {

        if shouldPerformZoomingAnimation {
            return animationDurationWithZooming
        } else {
            return animationDurationWithoutZooming
        }
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        setupTransitionContainerHierarchyWithTransitionContext(transitionContext)

        performFadeAnimationWithTransitionContext(transitionContext)

        if shouldPerformZoomingAnimation {
            performZoomingAnimationWithTransitionContext(transitionContext)
        }
    }

    fileprivate func setupTransitionContainerHierarchyWithTransitionContext(_ transitionContext: UIViewControllerContextTransitioning) {

        if let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) {

            let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!

            toView.frame = transitionContext.finalFrame(for: toViewController)

            let containerView = transitionContext.containerView

            if !toView.isDescendant(of: containerView) {
                containerView.addSubview(toView)
            }
        }

        if isDismissing {
            let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)!
            let containerView = transitionContext.containerView
            containerView.bringSubview(toFront: fromView)
        }
    }

    fileprivate func performFadeAnimationWithTransitionContext(_ transitionContext: UIViewControllerContextTransitioning) {

        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)

        let viewToFade: UIView?
        let beginningAlpha: CGFloat
        let endingAlpha: CGFloat
        if isDismissing {
            viewToFade = fromView
            beginningAlpha = 1
            endingAlpha = 0
        } else {
            viewToFade = toView
            beginningAlpha = 0
            endingAlpha = 1
        }

        viewToFade?.alpha = beginningAlpha

        let duration = fadeDurationForTransitionContext(transitionContext)

        UIView.animate(withDuration: duration, animations: {
            viewToFade?.alpha = endingAlpha

        }, completion: { [unowned self] finished in
            if !self.shouldPerformZoomingAnimation {
                self.completeTransitionWithTransitionContext(transitionContext)
            }
        })
    }

    fileprivate func performZoomingAnimationWithTransitionContext(_ transitionContext: UIViewControllerContextTransitioning) {

        let containerView = transitionContext.containerView

        var _startingViewForAnimation: UIView? = self.startingViewForAnimation
        var _endingViewForAnimation: UIView? = self.startingViewForAnimation

        if _startingViewForAnimation == nil {
            if let startingReference = startingReference {
                let view = isDismissing ? startingReference.view : startingReference.imageView
                _startingViewForAnimation = PhotoTransitionAnimator.newAnimationViewFromView(view)
            }
        }

        if _endingViewForAnimation == nil {
            if let endingReference = endingReference {
                let view = isDismissing ? endingReference.imageView : endingReference.view
                _endingViewForAnimation = PhotoTransitionAnimator.newAnimationViewFromView(view)
            }
        }

        guard let startingViewForAnimation = _startingViewForAnimation else {
            return
        }
        guard let endingViewForAnimation = _endingViewForAnimation else {
            return
        }

        guard let originalStartingViewForAnimation = startingReference?.view else {
            return
        }
        guard let originalEndingViewForAnimation = endingReference?.view else {
            return
        }

        startingViewForAnimation.clipsToBounds = true
        endingViewForAnimation.clipsToBounds = true

        let endingViewForAnimationFinalFrame = originalEndingViewForAnimation.frame

        endingViewForAnimation.frame = originalStartingViewForAnimation.frame

        var startingMaskView: UIView?
        if let _startingMaskView = startingReference?.view.mask {
            startingMaskView = PhotoTransitionAnimator.newViewFromView(_startingMaskView)
            startingMaskView?.frame = startingViewForAnimation.bounds
        }
        var endingMaskView: UIView?
        if let _endingMaskView = endingReference?.view.mask {
            endingMaskView = PhotoTransitionAnimator.newViewFromView(_endingMaskView)
            endingMaskView?.frame = endingViewForAnimation.bounds
        }
        startingViewForAnimation.mask = startingMaskView
        endingViewForAnimation.mask = endingMaskView

        if let startingView = startingReference?.view {
            let translatedStartingViewCenter = PhotoTransitionAnimator.centerPointForView(startingView, translatedToContainerView: containerView)
            startingViewForAnimation.center = translatedStartingViewCenter
            endingViewForAnimation.center = translatedStartingViewCenter
        }

        if isDismissing {
            startingViewForAnimation.alpha = 1
            endingViewForAnimation.alpha = 1
        } else {
            startingViewForAnimation.alpha = 1
            endingViewForAnimation.alpha = 0
        }

        containerView.addSubview(startingViewForAnimation)
        containerView.addSubview(endingViewForAnimation)

        startingReference?.view.alpha = 0
        endingReference?.view.alpha = 0

        var translatedEndingViewFinalCenter: CGPoint?
        if let endingView = endingReference?.view {
            translatedEndingViewFinalCenter = PhotoTransitionAnimator.centerPointForView(endingView, translatedToContainerView: containerView)
        }

        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: zoomingAnimationSpringDamping, initialSpringVelocity: 0, options: [.allowAnimatedContent, .beginFromCurrentState], animations: { [unowned self] in

            endingViewForAnimation.frame = endingViewForAnimationFinalFrame
            endingMaskView?.frame = endingViewForAnimation.bounds

            if let translatedEndingViewFinalCenter = translatedEndingViewFinalCenter {
                endingViewForAnimation.center = translatedEndingViewFinalCenter
            }
            
            startingViewForAnimation.frame = endingViewForAnimationFinalFrame
            startingMaskView?.frame = startingViewForAnimation.bounds

            if let translatedEndingViewFinalCenter = translatedEndingViewFinalCenter {
                startingViewForAnimation.center = translatedEndingViewFinalCenter
            }

            if self.isDismissing {
                startingViewForAnimation.alpha = 0
            } else {
                endingViewForAnimation.alpha = 1
            }

        }, completion: { [unowned self] finished in

            self.endingReference?.view.alpha = 1
            self.startingReference?.view.alpha = 1

            startingViewForAnimation.removeFromSuperview()
            endingViewForAnimation.removeFromSuperview()

            self.completeTransitionWithTransitionContext(transitionContext)
        })
    }

    fileprivate func fadeDurationForTransitionContext(_ transitionContext: UIViewControllerContextTransitioning) -> TimeInterval {

        if shouldPerformZoomingAnimation {
            return transitionDuration(using: transitionContext) * animationDurationFadeRatio
        } else {
            return transitionDuration(using: transitionContext)
        }
    }

    fileprivate func completeTransitionWithTransitionContext(_ transitionContext: UIViewControllerContextTransitioning) {

        if transitionContext.isInteractive {
            if transitionContext.transitionWasCancelled {
                transitionContext.cancelInteractiveTransition()
            } else {
                transitionContext.finishInteractiveTransition()
            }
        }

        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
    }
}

