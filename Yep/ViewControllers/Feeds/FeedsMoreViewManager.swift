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

    private func makeBlockFeedsItem(blockedFeeds blockedFeeds: Bool) -> ActionSheetView.Item {

        return .SubtitleSwitch(
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

    private var moreViewCreated: Bool = false

    lazy var moreView: ActionSheetView = {

        let cancelItem = ActionSheetView.Item.Cancel

        let view = ActionSheetView(items: [
                self.makeBlockFeedsItem(blockedFeeds: self.blockedFeeds),
                cancelItem,
            ]
        )

        self.moreViewCreated = true

        return view
    }()
}

