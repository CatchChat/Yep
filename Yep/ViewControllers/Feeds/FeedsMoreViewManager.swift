//
//  FeedsMoreViewManager.swift
//  Yep
//
//  Created by NIX on 16/4/13.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

class FeedsMoreViewManager {

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
        return .SubtitleSwitch(title: NSLocalizedString("不看他的话题", comment: ""), titleColor: UIColor.blackColor(), subtitle: NSLocalizedString("对方的话题将不再显示在你的时间线上", comment: ""), subtitleColor: UIColor.lightGrayColor(), switchOn: blockedFeeds, action: { [weak self] switchOn in
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