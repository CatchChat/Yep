//
//  SimplePullToRefreshView.swift
//  Yep
//
//  Created by NIX on 16/3/11.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

protocol SimplePullToRefreshViewDelegate: class {
    func pulllToRefreshViewDidRefresh(pulllToRefreshView: SimplePullToRefreshView)
    func scrollView() -> UIScrollView
}

private let sceneHeight: CGFloat = 80

class SimplePullToRefreshView: UIView {

    var refreshView: UIActivityIndicatorView!

    var progressPercentage: CGFloat = 0

    weak var delegate: SimplePullToRefreshViewDelegate?

    var refreshItems = [RefreshItem]()

    var isRefreshing = false {
        didSet {
            if !isRefreshing {
                refreshTimeoutTimer?.invalidate()
            }

            if isRefreshing {
                startAnimation()
            } else {
                stopAnimating()
            }
        }
    }

    var refreshTimeoutTimer: NSTimer?
    var refreshTimeoutAction: (() -> Void)? {
        didSet {
            refreshTimeoutTimer?.invalidate()
            refreshTimeoutTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: "refreshTimeout:", userInfo: nil, repeats: false)
        }
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        self.clipsToBounds = true

        setupRefreshItems()
    }

    func setupRefreshItems() {

        refreshView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        refreshView.hidesWhenStopped = false

        refreshItems = [
            RefreshItem(
                view: refreshView,
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

    func updateRefreshItemPositions() {
        for refreshItem in refreshItems {
            refreshItem.updateViewPositionForPercentage(progressPercentage)
        }
    }

    // MARK: Actions

    private func startAnimation() {
        println("startAnimation refreshItems.count: \(refreshItems.count)")
        refreshItems.forEach({
            ($0.view as? UIActivityIndicatorView)?.startAnimating()
        })
    }

    private func stopAnimating() {
        println("stopAnimating refreshItems.count: \(refreshItems.count)")
        refreshItems.forEach({
            ($0.view as? UIActivityIndicatorView)?.stopAnimating()
        })
    }

    func beginRefreshing() {

        isRefreshing = true

        UIView.animateWithDuration(0.25, delay: 0, options: .CurveEaseInOut, animations: { [weak self] in
            self?.delegate?.scrollView().contentInset.top += sceneHeight
        }, completion: { (_) -> Void in
        })
    }

    func endRefreshingAndDoFurtherAction(furtherAction: () -> Void) {

        guard isRefreshing else {
            return
        }

        isRefreshing = false

        UIView.animateWithDuration(0.25, delay: 0, options: .CurveEaseInOut, animations: { [weak self] in
            self?.delegate?.scrollView().contentInset.top -= sceneHeight

        }, completion: { _ in
            furtherAction()
        })
    }

    @objc private func refreshTimeout(timer: NSTimer) {

        println("SimplePullToRefreshView refreshTimeout")

        isRefreshing = false

        refreshTimeoutAction?()
    }
}

extension SimplePullToRefreshView: UIScrollViewDelegate {

    func scrollViewDidScroll(scrollView: UIScrollView) {

        if isRefreshing {
            return
        }

        let refreshViewVisibleHeight = max(0, -(scrollView.contentOffset.y + scrollView.contentInset.top))
        progressPercentage = min(1, refreshViewVisibleHeight / sceneHeight)

        updateRefreshItemPositions()
    }

    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {

        if !isRefreshing && progressPercentage == 1 {

            beginRefreshing()

            targetContentOffset.memory.y = -scrollView.contentInset.top

            delegate?.pulllToRefreshViewDidRefresh(self)
        }
    }

    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        
        if !isRefreshing && progressPercentage == 1 {
            
            beginRefreshing()
            
            scrollView.contentOffset.y = -scrollView.contentInset.top
            
            delegate?.pulllToRefreshViewDidRefresh(self)
        }
    }
}
