//
//  PullToRefreshView.swift
//  Yep
//
//  Created by NIX on 15/4/14.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

protocol PullToRefreshViewDelegate: class {
    func pulllToRefreshViewDidRefresh(pulllToRefreshView: PullToRefreshView)
    func scrollView() -> UIScrollView
}

private let sceneHeight: CGFloat = 80

class PullToRefreshView: UIView {

    var progressPercentage: CGFloat = 0

    weak var delegate: PullToRefreshViewDelegate?

    var isRefreshing = false

    var refreshItems = [RefreshItem]()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        self.clipsToBounds = true

        setupRefreshItems()

        updateColors()
    }

    func setupRefreshItems() {
        let logoImageView = UIImageView(image: UIImage(named: "fans"))

        refreshItems = [
            RefreshItem(
                view: logoImageView,
                centerEnd: CGPoint(
                    x: CGRectGetMidX(UIScreen.mainScreen().bounds),
                    y: 200 - sceneHeight * 0.5
                ),
                parallaxRatio: 0,
                sceneHeight: sceneHeight
            ),
        ]

        for refreshItem in refreshItems {
            addSubview(refreshItem.view)
        }
    }

    func updateColors() {
        backgroundColor = UIColor(white: (1 - progressPercentage) * 1.0, alpha: 1.0)

        for refreshItem in refreshItems {
            refreshItem.updateViewTintColor(UIColor.yepTintColor().colorWithAlphaComponent(progressPercentage))
        }
    }

    func updateRefreshItemPositions() {
        for refreshItem in refreshItems {
            refreshItem.updateViewPositionForPercentage(progressPercentage)
        }
    }

    // MARK: Actions

    func beginRefreshing() {
        isRefreshing = true

        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseInOut, animations: { () -> Void in
            delegate?.scrollView().contentInset.top += sceneHeight
        }, completion: { (_) -> Void in
        })
    }

    func endRefreshingAndDoFurtherAction(furtherAction: () -> Void) {
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseInOut, animations: { () -> Void in
            delegate?.scrollView().contentInset.top -= sceneHeight

        }, completion: { (_) -> Void in
            self.isRefreshing = false

            furtherAction()

            for refreshItem in self.refreshItems {
                refreshItem.view.layer.removeAllAnimations()
            }
        })
    }
}

extension PullToRefreshView: UIScrollViewDelegate {

    func scrollViewDidScroll(scrollView: UIScrollView) {
        if isRefreshing {
            return
        }

        let refreshViewVisibleHeight = max(0, -(scrollView.contentOffset.y + scrollView.contentInset.top))
        progressPercentage = min(1, refreshViewVisibleHeight / sceneHeight)

        updateRefreshItemPositions()

        updateColors()
    }

    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if !isRefreshing && progressPercentage == 1 {

            beginRefreshing()

            targetContentOffset.memory.y = -scrollView.contentInset.top

            delegate?.pulllToRefreshViewDidRefresh(self)

            for refreshItem in refreshItems {

                CATransaction.begin()

                let angle = CGFloat(M_PI * 2)

                let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
                rotationAnimation.repeatCount = 4
                rotationAnimation.byValue = angle
                rotationAnimation.duration = 0.75
                rotationAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
                rotationAnimation.removedOnCompletion = true

                CATransaction.setCompletionBlock({ () -> Void in
                    refreshItem.view.transform = CGAffineTransformRotate(refreshItem.view.transform, angle)
                })

                refreshItem.view.layer.addAnimation(rotationAnimation, forKey: "rotationAnimation")

                CATransaction.commit()
            }
        }
    }
}

class RefreshItem {

    unowned var view: UIView

    private var centerStart: CGPoint
    private var centerEnd: CGPoint

    init(view: UIView, centerEnd: CGPoint, parallaxRatio: CGFloat, sceneHeight: CGFloat) {
        self.view = view
        self.centerEnd = centerEnd

        centerStart = CGPoint(x: centerEnd.x, y: centerEnd.y + (parallaxRatio * sceneHeight))
        self.view.center = centerStart
    }

    func updateViewPositionForPercentage(percentage: CGFloat) {
        view.center = CGPoint(
            x: centerStart.x + (centerEnd.x - centerStart.x) * percentage,
            y: centerStart.y + (centerEnd.y - centerStart.y) * percentage
        )
    }

    func updateViewTintColor(tintColor: UIColor) {
        view.tintColor = tintColor
    }
}