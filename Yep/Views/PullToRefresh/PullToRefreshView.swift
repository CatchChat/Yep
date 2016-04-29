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

final class PullToRefreshView: UIView {
    
    var refreshView: YepRefreshView!

    var progressPercentage: CGFloat = 0

    weak var delegate: PullToRefreshViewDelegate?

    var refreshItems = [RefreshItem]()

    var isRefreshing = false {
        didSet {
            if !isRefreshing {
                refreshTimeoutTimer?.invalidate()
            }
        }
    }

    var refreshTimeoutTimer: NSTimer?
    var refreshTimeoutAction: (() -> Void)? {
        didSet {
            refreshTimeoutTimer?.invalidate()
            refreshTimeoutTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: #selector(PullToRefreshView.refreshTimeout(_:)), userInfo: nil, repeats: false)
        }
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        self.clipsToBounds = true

        setupRefreshItems()

        updateColors()
    }

    func setupRefreshItems() {
        
        refreshView = YepRefreshView(frame: CGRectMake(0, 0, 50, 50))

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

    func updateColors() {
        refreshView.updateShapePositionWithProgressPercentage(progressPercentage)
    }

    func updateRefreshItemPositions() {
        for refreshItem in refreshItems {
            refreshItem.updateViewPositionForPercentage(progressPercentage)
        }
    }

    // MARK: Actions

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

        }, completion: { (_) -> Void in

            furtherAction()
            
            self.refreshView.stopFlashing()

            self.refreshView.updateRamdonShapePositions()
        })
    }

    func refreshTimeout(timer: NSTimer) {
        println("PullToRefreshView refreshTimeout")
        refreshTimeoutAction?()
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

final class RefreshItem {

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