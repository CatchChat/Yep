//
//  SearchTransition.swift
//  Yep
//
//  Created by NIX on 16/4/22.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

final class SearchTransition: NSObject {

    var isPresentation = true
}

extension SearchTransition: UINavigationControllerDelegate {

    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        if operation == .Push {
            if (fromVC is SearchTriggerRepresentation) && (toVC is SearchActionRepresentation) {
                isPresentation = true
                return self
            }

        } else if operation == .Pop {
            if (fromVC is SearchActionRepresentation) && (toVC is SearchTriggerRepresentation) {
                isPresentation = false
                return self
            }
        }

        return nil
    }
}

extension SearchTransition: UIViewControllerAnimatedTransitioning {

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

        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let searchActionRepresentation = fromVC as! SearchActionRepresentation

        let containerView = transitionContext.containerView()!

        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)!
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!

        containerView.addSubview(toView)
        containerView.addSubview(fromView)

        fromView.alpha = 1
        searchActionRepresentation.searchBar.setShowsCancelButton(false, animated: true)

        let fullDuration = transitionDuration(transitionContext)

        UIView.animateWithDuration(fullDuration * 0.6, delay: 0.0, options: [.CurveEaseInOut], animations: { _ in

            searchActionRepresentation.searchBarTopConstraint.constant = 64
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

