//
//  FeedsMoreViewManager.swift
//  Yep
//
//  Created by NIX on 16/4/13.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

final class FeedsMoreViewManager {

    var toggleBlockFeedsAction: (() -> Void)?

    var blockedFeeds: Bool = true {
        didSet {
            if moreViewCreated {
                moreView.items[0] = makeBlockFeedsItem(blockedFeeds: blockedFeeds)
                moreView.refreshItems()
            }
        }
    }

    fileprivate func makeBlockFeedsItem(blockedFeeds: Bool) -> ActionSheetView.Item {

        return .subtitleSwitch(
            title: String.trans_titleHideFeedsFromThisUser,
            titleColor: UIColor(red: 63/255.0, green: 63/255.0, blue: 63/255.0, alpha: 1),
            subtitle: String.trans_promptFeedsByThisCreatorWillNotAppear,
            subtitleColor: UIColor.yep_mangmorGrayColor(),
            switchOn: blockedFeeds,
            action: { [weak self] switchOn in
                self?.toggleBlockFeedsAction?()
            }
        )
    }

    fileprivate var moreViewCreated: Bool = false

    lazy var moreView: ActionSheetView = {

        let cancelItem = ActionSheetView.Item.cancel

        let view = ActionSheetView(items: [
                self.makeBlockFeedsItem(blockedFeeds: self.blockedFeeds),
                cancelItem,
            ]
        )

        self.moreViewCreated = true

        return view
    }()
}

