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

private let sceneHeight: CGFloat = 100

class PullToRefreshView: UIView {

    var progressPercentage: CGFloat = 0
    weak var delegate: PullToRefreshViewDelegate?

    var isRefreshing = false

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        updateBackgroundColor()
    }

    func updateBackgroundColor() {
        backgroundColor = UIColor(white: (1 - progressPercentage) * 0.7, alpha: 1.0)
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

        updateBackgroundColor()
    }

    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if !isRefreshing && progressPercentage == 1 {

            beginRefreshing()

            targetContentOffset.memory.y = -scrollView.contentInset.top

            delegate?.pulllToRefreshViewDidRefresh(self)
        }
    }
}