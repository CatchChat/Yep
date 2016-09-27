//
//  ProfileLayout.swift
//  Yep
//
//  Created by NIX on 15/4/8.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class ProfileLayout: UICollectionViewFlowLayout {

    var scrollUpAction: ((_ progress: CGFloat) -> Void)?

    fileprivate let topBarsHeight: CGFloat = 64

    fileprivate let leftEdgeInset: CGFloat = YepConfig.Profile.leftEdgeInset

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

        guard let layoutAttributes = super.layoutAttributesForElements(in: rect) else {
            return nil
        }

        let contentInset = collectionView!.contentInset
        let contentOffset = collectionView!.contentOffset

        let minY = -contentInset.top

        if contentOffset.y < minY {
            let deltaY = abs(contentOffset.y - minY)

            for attributes in layoutAttributes {
                if (attributes.indexPath as NSIndexPath).section == ProfileViewController.Section.header.rawValue {
                    var frame = attributes.frame
                    frame.size.height = max(minY, collectionView!.bounds.width * profileAvatarAspectRatio + deltaY)
                    frame.origin.y = frame.minY - deltaY
                    attributes.frame = frame

                    break
                }
            }

        } else {
            let coverHeight = collectionView!.bounds.width * profileAvatarAspectRatio
            let coverHideHeight = coverHeight - topBarsHeight

            if contentOffset.y > coverHideHeight {

                let deltaY = abs(contentOffset.y - minY)

                for attributes in layoutAttributes {
                    if (attributes.indexPath as NSIndexPath).section == ProfileViewController.Section.header.rawValue {
                        var frame = attributes.frame
                        frame.origin.y = deltaY - coverHideHeight
                        attributes.frame = frame
                        attributes.zIndex = 1000

                        break
                    }
                }
            }

            let progress: CGFloat
            if coverHideHeight > contentOffset.y {
                progress = 1.0 - (coverHideHeight - contentOffset.y) / coverHideHeight
            } else {
                progress = 1.0
            }
            scrollUpAction?(progress)
        }

        // 先按照每个 item 的 centerY 分组
        var rowCollections = [CGFloat: [UICollectionViewLayoutAttributes]]()

        for attributes in layoutAttributes {
            let centerY = attributes.frame.midY

            if let rowCollection = rowCollections[centerY] {
                var rowCollection = rowCollection
                rowCollection.append(attributes)
                rowCollections[centerY] = rowCollection

            } else {
                rowCollections[centerY] = [attributes]
            }
        }

        // 再调整每一行的 item 的 frame
        for (_, rowCollection) in rowCollections {
            //let rowItemsCount = rowCollection.count

            // 每一行总的 InteritemSpacing
            //let aggregateInteritemSpacing = minimumInteritemSpacing * CGFloat(rowItemsCount - 1)

            // 每一行所有 items 的宽度
            var aggregateItemsWidth: CGFloat = 0
            for attributes in rowCollection {
                aggregateItemsWidth += attributes.frame.width
            }

            // 计算出有效的 width 和需要偏移的 offset
            //let alignmentWidth = aggregateItemsWidth + aggregateInteritemSpacing
            //let alignmentOffsetX = (CGRectGetWidth(collectionView!.bounds) - alignmentWidth) / 2

            // 调整每个 item 的 origin.x 即可
            var previousFrame = CGRect.zero
            for attributes in rowCollection {
                var itemFrame = attributes.frame

                if attributes.representedElementCategory == .cell && ((attributes.indexPath as NSIndexPath).section == ProfileViewController.Section.master.rawValue || (attributes.indexPath as NSIndexPath).section == ProfileViewController.Section.learning.rawValue) {
                    if previousFrame.equalTo(CGRect.zero) {
                        itemFrame.origin.x = leftEdgeInset
                    } else {
                        itemFrame.origin.x = previousFrame.maxX + minimumInteritemSpacing
                    }

                    attributes.frame = itemFrame
                }

                previousFrame = itemFrame
            }
        }

        return layoutAttributes
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}

