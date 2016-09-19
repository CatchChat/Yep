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

    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        if operation == .push {
            if (fromVC is SearchTriggerRepresentation) && (toVC is SearchActionRepresentation) {
                isPresentation = true
                return self
            }

        } else if operation == .pop {
            if (fromVC is SearchActionRepresentation) && (toVC is SearchTriggerRepresentation) {
                isPresentation = false
                return self
            }
        }

        return nil
    }
}

extension SearchTransition: UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {

        if isPresentation {
            return 0.25
        } else {
            return 0.45
        }
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        if isPresentation {
            presentTransition(transitionContext)

        } else {
            dismissTransition(transitionContext)
        }
    }

    fileprivate func presentTransition(_ transitionContext: UIViewControllerContextTransitioning) {

        //let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as! SearchFeedsViewController

        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)!

        let containerView = transitionContext.containerView

        containerView.addSubview(toView)

        toView.alpha = 0

        let fullDuration = transitionDuration(using: transitionContext)

        UIView.animate(withDuration: fullDuration, delay: 0.0, options: .layoutSubviews, animations: {
            toView.alpha = 1

        }, completion: { _ in
            transitionContext.completeTransition(true)
        })
    }

    fileprivate func dismissTransition(_ transitionContext: UIViewControllerContextTransitioning) {

        let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let searchActionRepresentation = fromVC as! SearchActionRepresentation

        let containerView = transitionContext.containerView

        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)!
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)!

        containerView.addSubview(toView)
        containerView.addSubview(fromView)

        fromView.alpha = 1
        searchActionRepresentation.searchBar.setShowsCancelButton(false, animated: true)

        let fullDuration = transitionDuration(using: transitionContext)

        UIView.animate(withDuration: fullDuration * 0.6, delay: 0.0, options: UIViewAnimationOptions(), animations: {

            searchActionRepresentation.searchBarTopConstraint.constant = 64
            fromVC.view.layoutIfNeeded()

        }, completion: { _ in

            UIView.animate(withDuration: fullDuration * 0.4, delay: 0.0, options: UIViewAnimationOptions(), animations: { _ in
                fromView.alpha = 0
                
            }, completion: { _ in
                transitionContext.completeTransition(true)
            })
        })
    }
}

