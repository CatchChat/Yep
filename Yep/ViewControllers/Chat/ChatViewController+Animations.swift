//
//  ChatViewController+Animations.swift
//  Yep
//
//  Created by NIX on 16/7/11.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

extension ChatViewController {

    func trySnapContentOfTableToBottom(forceAnimation forceAnimation: Bool = false) {

        guard let tableView = tableNode.view else {
            return
        }

        //let subscribeViewHeight = isSubscribeViewShowing ? SubscribeView.height : 0
        let newContentOffsetY = tableView.contentSize.height - chatToolbar.frame.origin.y // + subscribeViewHeight

        let bottom = view.bounds.height - chatToolbar.frame.origin.y // + subscribeViewHeight

        guard newContentOffsetY + tableView.contentInset.top > 0 else {

            UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
                if let strongSelf = self {
                    strongSelf.tableNode.view?.contentInset.bottom = bottom
                    strongSelf.tableNode.view?.scrollIndicatorInsets.bottom = bottom
                }
            }, completion: { _ in })

            return
        }

        var needDoAnimation = forceAnimation

        let bottomInsetOffset = bottom - tableView.contentInset.bottom

        if bottomInsetOffset != 0 {
            needDoAnimation = true
        }

        if tableView.contentOffset.y != newContentOffsetY {
            needDoAnimation = true
        }

        guard needDoAnimation else {
            return
        }

        UIView.animateWithDuration(forceAnimation ? 0.25 : 0.1, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
            if let strongSelf = self {
                strongSelf.tableNode.view?.contentInset.bottom = bottom
                strongSelf.tableNode.view?.scrollIndicatorInsets.bottom = bottom
                strongSelf.tableNode.view?.contentOffset.y = newContentOffsetY
            }
        }, completion: { _ in })
    }
}

