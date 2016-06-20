//
//  PhotoTransitonController.swift
//  Yep
//
//  Created by NIX on 16/6/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class PhotoTransitonController: NSObject, UIViewControllerTransitioningDelegate {

    lazy var animator = PhotoTransitionAnimator()
    lazy var interactionController = PhotoDismissalInteractionController()

    var startingView: UIView? {
        return animator.startingView
    }

    func setStartingView(view: UIView) {
        animator.startingView = view
    }

    var endingView: UIView? {
        return animator.endingView
    }

    func setEndingView(view: UIView) {
        animator.endingView = view
    }

    func didPanWithPanGestureRecognizer(pan: UIPanGestureRecognizer, viewToPan: UIView, anchorPoint: CGPoint) {

        interactionController.didPanWithPanGestureRecognizer(pan, viewToPan: viewToPan, anchorPoint: anchorPoint)
    }
}
