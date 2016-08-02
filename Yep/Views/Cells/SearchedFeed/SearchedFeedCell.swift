//
//  SearchedFeedCell.swift
//  Yep
//
//  Created by NIX on 16/4/1.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class SearchedFeedCell: UITableViewCell {

    @IBOutlet weak var mediaView: FeedMediaView!
    @IBOutlet weak var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        separatorInset = YepConfig.SearchedItemCell.separatorInset
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        mediaView.hidden = true
        nameLabel.text = nil

        mediaView.clearImages()
    }

    func configureWithFeed(feed: Feed, keyword: String?) {

        if let keyword = keyword {
            nameLabel.attributedText = feed.body.yep_hightlightSearchKeyword(keyword, baseFont: YepConfig.SearchedItemCell.nicknameFont, baseColor: YepConfig.SearchedItemCell.nicknameColor)

        } else {
            nameLabel.text = feed.body
        }

        let attachments = feed.attachments.map({
            DiscoveredAttachment(metadata: $0.metadata, URLString: $0.URLString, image: nil)
        })
        mediaView.setImagesWithAttachments(attachments)
    }
}

