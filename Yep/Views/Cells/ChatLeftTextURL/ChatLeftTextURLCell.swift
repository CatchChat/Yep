//
//  ChatLeftTextURLCell.swift
//  Yep
//
//  Created by nixzhu on 16/1/18.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import Ruler

final class ChatLeftTextURLCell: ChatLeftTextCell {

    var openGraphURL: NSURL?
    var tapOpenGraphURLAction: ((URL: NSURL) -> Void)?

    lazy var feedURLContainerView: FeedURLContainerView = {
        let view = FeedURLContainerView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        view.directionLeading = true
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

    override func configureWithMessage(message: Message, layoutCache: ChatTextCellLayoutCache) {

        bottomGap = 100 + 10

        super.configureWithMessage(message, layoutCache: layoutCache)

        UIView.setAnimationsEnabled(false); do {
            let minWidth: CGFloat = Ruler.iPhoneHorizontal(190, 220, 220).value
            let width = max(minWidth, textContentTextView.frame.width + 12 * 2 - 1)
            let feedURLContainerViewFrame = CGRect(x: textContentTextView.frame.origin.x - 12 + 1, y: CGRectGetMaxY(textContentTextView.frame) + 8, width: width, height: 100)
            feedURLContainerView.frame = feedURLContainerViewFrame
        }
        UIView.setAnimationsEnabled(true)

        if let openGraphInfo = message.openGraphInfo {
            feedURLContainerView.configureWithOpenGraphInfoType(openGraphInfo)
            openGraphURL = openGraphInfo.URL
        }
    }
}

