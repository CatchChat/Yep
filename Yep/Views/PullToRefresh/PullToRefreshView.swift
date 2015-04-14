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
    
    var refreshView: YepRefreshView!

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
        
        refreshView = YepRefreshView(frame: CGRectMake(0, 100, 50, 50))
        
        refreshView.center = CGPointMake(self.bounds.width/2.0, 100)

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
        
        refreshView.updatePullRefreshWithProgress(1-progressPercentage)
        
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
            
            self.refreshView.stopFlik()
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