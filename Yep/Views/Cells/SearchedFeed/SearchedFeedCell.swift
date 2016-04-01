//
//  SearchedFeedCell.swift
//  Yep
//
//  Created by NIX on 16/4/1.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class SearchedFeedCell: UITableViewCell {

    @IBOutlet weak var mediaView: FeedMediaView!
    @IBOutlet weak var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        mediaView.hidden = true

        mediaView.clearImages()
    }

    func configureWithFeed(feed: Feed, keyword: String?) {

        if let keyword = keyword {

            let text = feed.body
            let attributedString = NSMutableAttributedString(string: text)
            let textRange = NSMakeRange(0, (text as NSString).length)

            // highlight keyword

            let highlightTextAttributes: [String: AnyObject] = [
                NSForegroundColorAttributeName: UIColor.yepTintColor(),
            ]

            let highlightExpression = try! NSRegularExpression(pattern: keyword, options: [.CaseInsensitive])

            highlightExpression.enumerateMatchesInString(text, options: NSMatchingOptions(), range: textRange, usingBlock: { result, flags, stop in

                if let result = result {
                    attributedString.addAttributes(highlightTextAttributes, range: result.range )
                }
            })

            nameLabel.attributedText = attributedString

        } else {
            nameLabel.text = feed.body
        }

        let attachments = feed.attachments.map({
            DiscoveredAttachment(metadata: $0.metadata, URLString: $0.URLString, image: nil)
        })
        mediaView.setImagesWithAttachments(attachments)
    }

}
