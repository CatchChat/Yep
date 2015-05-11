//
//  ProfileLayout.swift
//  Yep
//
//  Created by NIX on 15/4/8.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ProfileLayout: UICollectionViewFlowLayout {

    let leftEdgeInset: CGFloat = 38

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
        let layoutAttributes = super.layoutAttributesForElementsInRect(rect) as! [UICollectionViewLayoutAttributes]
        let contentInset = collectionView!.contentInset
        let contentOffset = collectionView!.contentOffset

        let minY = -contentInset.top

        if contentOffset.y < minY {
            let deltaY = abs(contentOffset.y - minY)

            for (index, attributes) in enumerate(layoutAttributes) {
                if index == 0 {
                    var frame = attributes.frame
                    frame.size.height = max(minY, CGRectGetWidth(collectionView!.bounds) * profileAvatarAspectRatio + deltaY)
                    frame.origin.y = CGRectGetMinY(frame) - deltaY
                    attributes.frame = frame

                    break
                }
            }
        }

        // 先按照每个 item 的 centerY 分组
        var rowCollections = [CGFloat: [UICollectionViewLayoutAttributes]]()
        for (index, attributes) in enumerate(layoutAttributes) {
            let centerY = CGRectGetMidY(attributes.frame)

            if let rowCollection = rowCollections[centerY] {
                var rowCollection = rowCollection
                rowCollection.append(attributes)
                rowCollections[centerY] = rowCollection

            } else {
                rowCollections[centerY] = [attributes]
            }
        }

        // 再调整每一行的 item 的 frame
        for (key, rowCollection) in rowCollections {
            let rowItemsCount = rowCollection.count

            // 每一行总的 InteritemSpacing
            let aggregateInteritemSpacing = minimumInteritemSpacing * CGFloat(rowItemsCount - 1)

            // 每一行所有 items 的宽度
            var aggregateItemsWidth: CGFloat = 0
            for attributes in rowCollection {
                aggregateItemsWidth += CGRectGetWidth(attributes.frame)
            }

            // 计算出有效的 width 和需要偏移的 offset
            let alignmentWidth = aggregateItemsWidth + aggregateInteritemSpacing
            let alignmentOffsetX = (CGRectGetWidth(collectionView!.bounds) - alignmentWidth) / 2

            // 调整每个 item 的 origin.x 即可
            var previousFrame = CGRectZero
            for attributes in rowCollection {
                var itemFrame = attributes.frame

                if attributes.representedElementCategory == .Cell && (attributes.indexPath.section == ProfileViewController.ProfileSection.Master.rawValue || attributes.indexPath.section == ProfileViewController.ProfileSection.Learning.rawValue) {
                    if CGRectEqualToRect(previousFrame, CGRectZero) {
                        itemFrame.origin.x = leftEdgeInset
                    } else {
                        itemFrame.origin.x = CGRectGetMaxX(previousFrame) + minimumInteritemSpacing
                    }
                }

                attributes.frame = itemFrame

                previousFrame = itemFrame
            }
        }

        return layoutAttributes
    }

    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
}
