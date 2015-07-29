//
//  ConversationMessagePreviewNavigationControllerDelegate.swift
//  Yep
//
//  Created by NIX on 15/5/25.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ConversationMessagePreviewNavigationControllerDelegate: NSObject, UINavigationControllerDelegate, UIViewControllerAnimatedTransitioning {

    // MARK: UINavigationControllerDelegate

    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        if operation == .Push {
            if fromVC.isKindOfClass(ConversationViewController.self) && toVC.isKindOfClass(MessageMediaViewController.self) {
                isPresentation = true
                
                return self
            }

        } else if operation == .Pop {
            if fromVC.isKindOfClass(MessageMediaViewController.self) && toVC.isKindOfClass(ConversationViewController.self) {
                isPresentation = false

                return self
            }
        }

        return nil
    }

    // MARK: UIViewControllerAnimatedTransitioning

    var snapshot: UIView?

    var frame = CGRectZero

    var thumbnailImage: UIImage? {
        willSet {
            let imageView = UIImageView()
            imageView.contentMode = .ScaleAspectFit
            imageView.image = newValue
            imageView.alpha = 0
            thumbnailImageView = imageView
        }
    }
    var thumbnailImageView: UIImageView?

    var transitionView: UIView? {
        didSet {
            if let transitionView = transitionView {
                transitionViewSnapshot = transitionView.snapshotViewAfterScreenUpdates(true)
            }
        }
    }
    var transitionViewSnapshot: UIView?

    var isPresentation = true

    var transitionContext: UIViewControllerContextTransitioning?

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
//        return 2
        return isPresentation ? 0.35 : 0.35
    }

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {

        self.transitionContext = transitionContext

        if isPresentation {
            presentTransition(transitionContext)
        } else {
            dismissTransition(transitionContext)
        }
    }


    let largerOffset: CGFloat = 0//80

    func presentTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as? ConversationsViewController
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as? MessageMediaViewController

        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)

        let containerView = transitionContext.containerView()

        if let snapshot = snapshot {
            snapshot.alpha = 0

            let transitionViewCover = UIView(frame: frame)
            transitionViewCover.backgroundColor = UIColor.whiteColor()
            snapshot.addSubview(transitionViewCover)

            containerView.addSubview(snapshot)
        }

//        let blackColorView = UIView()
//        blackColorView.frame = containerView.bounds
//        blackColorView.backgroundColor = UIColor.blackColor()
//        blackColorView.alpha = 0
//        containerView.addSubview(blackColorView)

        containerView.addSubview(toView!)

        let animatingVC = toVC!
        let animatingView = toView!

        if let transitionViewSnapshot = transitionViewSnapshot, thumbnailImageView = thumbnailImageView {

            animatingVC.view.backgroundColor = UIColor.clearColor()
            animatingVC.mediaView.alpha = 0
            animatingVC.mediaControlView.alpha = 0


            transitionViewSnapshot.frame = frame
            animatingView.addSubview(transitionViewSnapshot)

            thumbnailImageView.frame = frame
            animatingView.addSubview(thumbnailImageView)

            snapshot?.alpha = 1


            let fullDuration = transitionDuration(transitionContext)

//            transitionView?.alpha = 0
//            println("transitionView \(transitionView)")

            UIView.animateKeyframesWithDuration(fullDuration, delay: 0.0, options: .CalculationModeLinear, animations: { () -> Void in

                UIView.addKeyframeWithRelativeStartTime(0.5, relativeDuration: 0.4, animations: { () -> Void in
                    animatingVC.view.backgroundColor = UIColor.blackColor()
                })

//                UIView.addKeyframeWithRelativeStartTime(0.3, relativeDuration: fullDuration - 0.3, animations: { () -> Void in
//                    blackColorView.alpha = 1
//                })

//                UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 0.3, animations: { () -> Void in
//                    transitionViewSnapshot.center = animatingView.center
//                })

                UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 0.9, animations: { () -> Void in
                    let targetWidth = animatingView.bounds.width + self.largerOffset

                    let dw = targetWidth - transitionViewSnapshot.bounds.width
                    let ratio = targetWidth / transitionViewSnapshot.bounds.width
                    let height = ratio * transitionViewSnapshot.bounds.height
                    let dh = height - transitionViewSnapshot.bounds.height

                    let frame = CGRectInset(transitionViewSnapshot.frame, -dw * 0.5, -dh * 0.5)

                    transitionViewSnapshot.frame = frame
                    transitionViewSnapshot.center = animatingView.center

                    thumbnailImageView.frame = frame
                    thumbnailImageView.center = animatingView.center

                    transitionViewSnapshot.alpha = 0
                    thumbnailImageView.alpha = 1
                })

                UIView.addKeyframeWithRelativeStartTime(0.9, relativeDuration: 0.1, animations: { () -> Void in
//                    let ratio = (animatingView.bounds.width + self.largerOffset) / animatingView.bounds.width
//                    animatingVC.mediaView.transform = CGAffineTransformMakeScale(ratio, ratio)
                    animatingVC.mediaView.alpha = 1
                    animatingVC.mediaControlView.alpha = 1

                    //transitionViewSnapshot.alpha = 0
                })

//                UIView.addKeyframeWithRelativeStartTime(0.9, relativeDuration: 0.1, animations: { () -> Void in
//                    animatingVC.mediaView.transform = CGAffineTransformMakeScale(1.0, 1.0)
//                })

            }, completion: { (finished) -> Void in

                animatingVC.view.backgroundColor = UIColor.blackColor()

                transitionViewSnapshot.removeFromSuperview()

                //self.snapshot?.removeFromSuperview()

                transitionContext.completeTransition(true)
            })

        } else {
            transitionContext.completeTransition(false)
        }
    }

    func dismissTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as? MessageMediaViewController

        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)

        let containerView = transitionContext.containerView()

        containerView.addSubview(toView!)

        if let snapshot = snapshot {
            containerView.addSubview(snapshot)
        }

        containerView.addSubview(fromView!)

        let animatingVC = fromVC!
        let animatingView = fromView!

        let fullDuration = transitionDuration(transitionContext)

        if let transitionViewSnapshot = transitionViewSnapshot, thumbnailImageView = thumbnailImageView {

            self.transitionView?.alpha = 0

            UIView.animateKeyframesWithDuration(fullDuration, delay: 0.0, options: .CalculationModeLinear, animations: { () -> Void in

                UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 1.0, animations: { () -> Void in
                    animatingVC.view.backgroundColor = UIColor.clearColor()
                })

                UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 0.2, animations: { () -> Void in
                    let ratio = (animatingView.bounds.width + self.largerOffset) / animatingView.bounds.width
                    animatingVC.mediaView.transform = CGAffineTransformMakeScale(ratio, ratio)
                    animatingVC.mediaControlView.alpha = 0
                })

                UIView.addKeyframeWithRelativeStartTime(0.2, relativeDuration: 0.0, animations: { () -> Void in
                    animatingView.addSubview(transitionViewSnapshot)
//                    transitionViewSnapshot.center = animatingView.center
                    transitionViewSnapshot.alpha = 0
                    thumbnailImageView.alpha = 1
                    animatingVC.mediaView.alpha = 0
                })

                UIView.addKeyframeWithRelativeStartTime(0.2, relativeDuration: 0.6, animations: { () -> Void in
                    transitionViewSnapshot.frame = self.frame
                    thumbnailImageView.frame = self.frame

                    transitionViewSnapshot.alpha = 1
                    thumbnailImageView.alpha = 0
                })

                
            }, completion: { (finished) -> Void in

                self.transitionView?.alpha = 1

                transitionViewSnapshot.removeFromSuperview()

                self.snapshot?.removeFromSuperview()

                transitionContext.completeTransition(true)
            })

        } else {
            transitionContext.completeTransition(false)
        }
    }
}

