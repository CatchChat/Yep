//
//  ChatRightTextURLCell.swift
//  Yep
//
//  Created by nixzhu on 16/1/18.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import Ruler

final class ChatRightTextURLCell: ChatRightTextCell {

    var openGraphURL: NSURL?
    var tapOpenGraphURLAction: ((URL: NSURL) -> Void)?
    
    lazy var feedURLContainerView: FeedURLContainerView = {
        let view = FeedURLContainerView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        view.directionLeading = false
        view.compressionMode = false

        view.tapAction = { [weak self] in
            guard let URL = self?.openGraphURL else {
                return
            }

            self?.tapOpenGraphURLAction?(URL: URL)
        }

        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(feedURLContainerView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureWithMessage(message: Message, layoutCache: ChatTextCellLayoutCache, mediaTapAction: MediaTapAction?) {

        bottomGap = 100 + 10

        super.configureWithMessage(message, layoutCache: layoutCache, mediaTapAction: mediaTapAction)

        UIView.setAnimationsEnabled(false); do {
            let minWidth: CGFloat = Ruler.iPhoneHorizontal(190, 220, 220).value
            let fullWidth = UIScreen.mainScreen().bounds.width
            let width = max(minWidth, textContainerView.frame.width + 12 * 2 - 1)
            let feedURLContainerViewFrame = CGRect(x: fullWidth - 65 - width - 1, y: CGRectGetMaxY(textContainerView.frame) + 8, width: width, height: 100)
            feedURLContainerView.frame = feedURLContainerViewFrame
        }
        UIView.setAnimationsEnabled(true)

        if let openGraphInfo = message.openGraphInfo {
            feedURLContainerView.configureWithOpenGraphInfoType(openGraphInfo)
            openGraphURL = openGraphInfo.URL
        }
    }
}

