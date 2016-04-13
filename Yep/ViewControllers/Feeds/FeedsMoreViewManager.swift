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

    lazy var moreView: ActionSheetView = {

        let blockFeedsItem = ActionSheetView.Item.SubtitleSwitch(title: NSLocalizedString("不看他的话题", comment: ""), titleColor: UIColor.blackColor(), subtitle: NSLocalizedString("对方的话题将不再显示在你的时间线上", comment: ""), subtitleColor: UIColor.lightGrayColor(), switchOn: false, action: { [weak self] switchOn in
                self?.toggleBlockFeedsAction?()
            }
        )

        let cancelItem = ActionSheetView.Item.Cancel

        let view = ActionSheetView(items: [
            blockFeedsItem,
            cancelItem,
            ]
        )

        return view
    }()
}