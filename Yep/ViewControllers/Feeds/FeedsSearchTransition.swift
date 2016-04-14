//
//  FeedsSearchTransition.swift
//  Yep
//
//  Created by NIX on 16/4/11.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class FeedsSearchTransition: NSObject {

    var isPresentation = true
}

extension FeedsSearchTransition: UINavigationControllerDelegate {

    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        if operation == .Push {
            if (fromVC is FeedsViewController) && (toVC is SearchFeedsViewController) {
                isPresentation = true
                return self
            }

        } else if operation == .Pop {
            if (fromVC is SearchFeedsViewController) && (toVC is FeedsViewController) {
                isPresentation = false
                return self
            }
        }

        return nil
    }
}

extension FeedsSearchTransition: UIViewControllerAnimatedTransitioning {

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {

        if isPresentation {
            return 0.25
        } else {
            return 0.45
        }
    }

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {

        if isPresentation {
            presentTransition(transitionContext)

        } else {
            dismissTransition(transitionContext)
        }
    }

    private func presentTransition(transitionContext: UIViewControllerContextTransitioning) {

        //let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as! SearchFeedsViewController

        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!

        let containerView = transitionContext.containerView()!

        containerView.addSubview(toView)

        toView.alpha = 0

        let fullDuration = transitionDuration(transitionContext)

        UIView.animateWithDuration(fullDuration, delay: 0.0, options: [.CurveEaseInOut, .LayoutSubviews], animations: { _ in
            toView.alpha = 1

        }, completion: { finished in
            transitionContext.completeTransition(true)
        })
    }

    private func dismissTransition(transitionContext: UIViewControllerContextTransitioning) {

        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as! SearchFeedsViewController

        let containerView = transitionContext.containerView()!

        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)!
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!

        containerView.addSubview(toView)
        containerView.addSubview(fromView)

        fromView.alpha = 1
        fromVC.searchBar.setShowsCancelButton(false, animated: true)

        let fullDuration = transitionDuration(transitionContext)

        UIView.animateWithDuration(fullDuration * 0.6, delay: 0.0, options: [.CurveEaseInOut], animations: { _ in

            fromVC.searchBarTopConstraint.constant = 44
            fromVC.view.layoutIfNeeded()

        }, completion: { finished in

            UIView.animateWithDuration(fullDuration * 0.4, delay: 0.0, options: [.CurveEaseInOut], animations: { _ in
                fromView.alpha = 0
                
            }, completion: { finished in
                transitionContext.completeTransition(true)
            })
        })
    }
}