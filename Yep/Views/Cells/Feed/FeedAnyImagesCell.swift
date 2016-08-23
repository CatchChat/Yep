//
//  FeedAnyImagesCell.swift
//  Yep
//
//  Created by nixzhu on 15/9/30.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepPreview
import AsyncDisplayKit

private let screenWidth: CGFloat = UIScreen.mainScreen().bounds.width

typealias FeedTapMediaAction = (transitionReference: Reference, image: UIImage?, attachments: [DiscoveredAttachment], index: Int) -> Void

typealias FeedTapImagesAction = (transitionReferences: [Reference?], attachments: [DiscoveredAttachment], image: UIImage?, index: Int) -> Void

final class FeedAnyImagesCell: FeedBasicCell {

    override class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + YepConfig.FeedNormalImagesCell.imageSize.height + 15
        return ceil(height)
    }

    lazy var mediaCollectionNode: ASCollectionNode = {

        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 5
        layout.scrollDirection = .Horizontal
        layout.itemSize = YepConfig.FeedNormalImagesCell.imageSize

        let node = ASCollectionNode(collectionViewLayout: layout)

        node.view.scrollsToTop = false
        node.view.contentInset = UIEdgeInsets(top: 0, left: 15 + 40 + 10, bottom: 0, right: 15)
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

    override func configureWithFeed(feed: DiscoveredFeed, layout: FeedCellLayout, needShowSkill: Bool) {

        super.configureWithFeed(feed, layout: layout, needShowSkill: needShowSkill)

        if let attachment = feed.attachment, case let .Images(attachments) = attachment {
            self.attachments = attachments
        }

        let anyImagesLayout = layout.anyImagesLayout!
        mediaCollectionNode.frame = anyImagesLayout.mediaCollectionViewFrame
    }
}

extension FeedAnyImagesCell: ASCollectionDataSource, ASCollectionDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attachments.count
    }

    func collectionView(collectionView: ASCollectionView, nodeForItemAtIndexPath indexPath: NSIndexPath) -> ASCellNode {

        let node = FeedImageCellNode()
        if let attachment = attachments[safe: indexPath.item] {
            node.configureWithAttachment(attachment, imageSize: YepConfig.FeedNormalImagesCell.imageSize)
        }
        return node
    }

    func collectionView(collectionView: ASCollectionView, constrainedSizeForNodeAtIndexPath indexPath: NSIndexPath) -> ASSizeRange {

        let size = YepConfig.FeedNormalImagesCell.imageSize
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
                return (node as? Previewable)?.transitionReference
            }
        })
        tapImagesAction?(transitionReferences: references, attachments: attachments, image: node.imageNode.image, index: indexPath.item)
    }
}

