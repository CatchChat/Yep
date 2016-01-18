//
//  ChatLeftTextURLCell.swift
//  Yep
//
//  Created by nixzhu on 16/1/18.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class ChatLeftTextURLCell: ChatLeftTextCell {

    lazy var feedURLContainerView: FeedURLContainerView = {
        let view = FeedURLContainerView()
        view.compressionMode = false
        return view
    }()

    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.addSubview(feedURLContainerView)
    }

    override func configureWithMessage(message: Message, textContentLabelWidth: CGFloat, collectionView: UICollectionView, indexPath: NSIndexPath) {

        super.configureWithMessage(message, textContentLabelWidth: textContentLabelWidth, collectionView: collectionView, indexPath: indexPath)

        let frame = CGRect(x: textContainerView.frame.origin.x, y: textContainerView.frame.origin.y + 10, width: 220, height: 100)
        feedURLContainerView.frame = frame
    }
}

