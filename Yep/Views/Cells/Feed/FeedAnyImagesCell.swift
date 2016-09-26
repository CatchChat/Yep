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

private let screenWidth: CGFloat = UIScreen.main.bounds.width

typealias FeedTapMediaAction = (_ transitionReference: Reference, _ image: UIImage?, _ attachments: [DiscoveredAttachment], _ index: Int) -> Void

typealias FeedTapImagesAction = (_ transitionReferences: [Reference?], _ attachments: [DiscoveredAttachment], _ image: UIImage?, _ index: Int) -> Void

final class FeedAnyImagesCell: FeedBasicCell {

    override class func heightOfFeed(_ feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + YepConfig.FeedNormalImagesCell.imageSize.height + 15
        return ceil(height)
    }

    lazy var mediaCollectionNode: ASCollectionNode = {

        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 5
        layout.scrollDirection = .horizontal
        layout.itemSize = YepConfig.FeedNormalImagesCell.imageSize

        let node = ASCollectionNode(collectionViewLayout: layout)

        node.view.scrollsToTop = false
        node.view.contentInset = UIEdgeInsets(top: 0, left: 15 + 40 + 10, bottom: 0, right: 15)
        node.view.showsHorizontalScrollIndicator = false
        node.view.backgroundColor = UIColor.clear

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
                if strongSelf.isEditing {
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

    override func configureWithFeed(_ feed: DiscoveredFeed, layout: FeedCellLayout, needShowSkill: Bool) {

        super.configureWithFeed(feed, layout: layout, needShowSkill: needShowSkill)

        if let attachment = feed.attachment, case let .images(attachments) = attachment {
            self.attachments = attachments
        }

        let anyImagesLayout = layout.anyImagesLayout!
        mediaCollectionNode.frame = anyImagesLayout.mediaCollectionViewFrame
    }
}

extension FeedAnyImagesCell: ASCollectionDataSource, ASCollectionDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attachments.count
    }

    func collectionView(_ collectionView: ASCollectionView, nodeForItemAt indexPath: IndexPath) -> ASCellNode {

        let node = FeedImageCellNode()
        if let attachment = attachments[safe: indexPath.item] {
            node.configureWithAttachment(attachment, imageSize: YepConfig.FeedNormalImagesCell.imageSize)
        }
        return node
    }

    func collectionView(_ collectionView: ASCollectionView, constrainedSizeForNodeAt indexPath: IndexPath) -> ASSizeRange {

        let size = YepConfig.FeedNormalImagesCell.imageSize
        return ASSizeRange(min: size, max: size)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        guard let firstAttachment = attachments.first , !firstAttachment.isTemporary else {
            return
        }

        guard let node = mediaCollectionNode.view.nodeForItem(at: indexPath) as? FeedImageCellNode else {
            return
        }

        let references: [Reference?] = (0..<attachments.count).map({
            let indexPath = IndexPath(item: $0, section: indexPath.section)
            let node = mediaCollectionNode.view.nodeForItem(at: indexPath) as? FeedImageCellNode

            if node?.view.superview == nil {
                return nil
            } else {
                return (node as? Previewable)?.transitionReference
            }
        })
        tapImagesAction?(references, attachments, node.imageNode.image, indexPath.item)
    }
}

