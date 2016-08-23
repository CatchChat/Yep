//
//  SearchedFeedAnyImagesCell.swift
//  Yep
//
//  Created by NIX on 16/4/21.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepPreview
import AsyncDisplayKit

final class SearchedFeedAnyImagesCell: SearchedFeedBasicCell {

    override class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + YepConfig.SearchedFeedNormalImagesCell.imageSize.height + 10
        return ceil(height)
    }

    lazy var mediaCollectionNode: ASCollectionNode = {

        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 5
        layout.scrollDirection = .Horizontal
        layout.itemSize = YepConfig.SearchedFeedNormalImagesCell.imageSize

        let node = ASCollectionNode(collectionViewLayout: layout)

        node.view.scrollsToTop = false
        node.view.contentInset = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 10)
        node.view.showsHorizontalScrollIndicator = false
        node.view.backgroundColor = UIColor.clearColor()

        node.dataSource = self
        node.delegate = self

        let backgroundView = TouchClosuresView(frame: node.view.bounds)
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
        node.view.backgroundView = backgroundView
        
        return node
    }()

    var tapImagesAction: FeedTapImagesAction?

    var attachments = [DiscoveredAttachment]() {
        didSet {
            mediaCollectionNode.reloadData()
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(mediaCollectionNode.view)
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
        mediaCollectionNode.frame = anyImagesLayout.mediaCollectionViewFrame
    }
}

extension SearchedFeedAnyImagesCell: ASCollectionDataSource, ASCollectionDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attachments.count
    }

    func collectionView(collectionView: ASCollectionView, nodeForItemAtIndexPath indexPath: NSIndexPath) -> ASCellNode {

        let node = FeedImageCellNode()
        if let attachment = attachments[safe: indexPath.item] {
            node.configureWithAttachment(attachment, imageSize: YepConfig.SearchedFeedNormalImagesCell.imageSize)
        }
        return node
    }

    func collectionView(collectionView: ASCollectionView, constrainedSizeForNodeAtIndexPath indexPath: NSIndexPath) -> ASSizeRange {

        let size = YepConfig.SearchedFeedNormalImagesCell.imageSize
        return ASSizeRange(min: size, max: size)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        guard let firstAttachment = attachments.first where !firstAttachment.isTemporary else {
            return
        }

        guard let node = mediaCollectionNode.view.nodeForItemAtIndexPath(indexPath) as? FeedImageCellNode else {
            return
        }

        let references: [Reference?] = (0..<attachments.count).map({
            let indexPath = NSIndexPath(forItem: $0, inSection: indexPath.section)
            let node = mediaCollectionNode.view.nodeForItemAtIndexPath(indexPath) as? FeedImageCellNode

            if node?.view.superview == nil {
                return nil
            } else {
                return node?.transitionReference
            }
        })
        tapImagesAction?(transitionReferences: references, attachments: attachments, image: node.imageNode.image, index: indexPath.item)
    }
}

