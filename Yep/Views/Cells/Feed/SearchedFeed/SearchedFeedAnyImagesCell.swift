//
//  SearchedFeedAnyImagesCell.swift
//  Yep
//
//  Created by NIX on 16/4/21.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class SearchedFeedAnyImagesCell: SearchedFeedBasicCell {

    override class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + YepConfig.SearchedFeedNormalImagesCell.imageSize.height + 10

        return ceil(height)
    }

    lazy var mediaCollectionView: UICollectionView = {

        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 5
        layout.scrollDirection = .Horizontal

        let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: layout)
        collectionView.scrollsToTop = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 10)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.clearColor()

        collectionView.registerNibOf(FeedMediaCell)

        collectionView.dataSource = self
        collectionView.delegate = self

        let backgroundView = TouchClosuresView(frame: collectionView.bounds)
        backgroundView.touchesBeganAction = { [weak self] in
            if let strongSelf = self {
                strongSelf.touchesBeganAction?(strongSelf)
            }
        }
        backgroundView.touchesEndedAction = { [weak self] in
            if let strongSelf = self {
                if strongSelf.editing {
                    return
                }
                strongSelf.touchesEndedAction?(strongSelf)
            }
        }
        backgroundView.touchesCancelledAction = { [weak self] in
            if let strongSelf = self {
                strongSelf.touchesCancelledAction?(strongSelf)
            }
        }
        collectionView.backgroundView = backgroundView

        return collectionView
    }()

    var tapImagesAction: FeedTapImagesAction?

    var attachments = [DiscoveredAttachment]() {
        didSet {

            mediaCollectionView.reloadData()
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(mediaCollectionView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        attachments = []
    }

    override func configureWithFeed(feed: DiscoveredFeed, layout: SearchedFeedCellLayout, keyword: String?) {

        super.configureWithFeed(feed, layout: layout, keyword: keyword)

        if let attachment = feed.attachment, case let .Images(attachments) = attachment {
            self.attachments = attachments
        }

        let anyImagesLayout = layout.anyImagesLayout!
        mediaCollectionView.frame = anyImagesLayout.mediaCollectionViewFrame
    }
}

extension SearchedFeedAnyImagesCell: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attachments.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell: FeedMediaCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

        if let attachment = attachments[safe: indexPath.item] {
            cell.configureWithAttachment(attachment, bigger: (attachments.count == 1))
        }

        return cell
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        return YepConfig.SearchedFeedNormalImagesCell.imageSize
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        guard let firstAttachment = attachments.first where !firstAttachment.isTemporary else {
            return
        }

        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! FeedMediaCell

        let transitionViews: [UIView?] = (0..<attachments.count).map({
            let cell = collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: $0, inSection: indexPath.section)) as? FeedMediaCell
            return cell?.imageView
        })
        tapImagesAction?(transitionViews: transitionViews, attachments: attachments, image: cell.imageView.image, index: indexPath.item)
    }
}
