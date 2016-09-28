//
//  RegisterSelectSkillsLayout.swift
//  Yep
//
//  Created by NIX on 15/7/9.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class RegisterSelectSkillsLayout: UICollectionViewFlowLayout {

    let leftEdgeInset: CGFloat = registerPickSkillsLayoutLeftEdgeInset

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

        guard let _layoutAttributes = super.layoutAttributesForElements(in: rect) else {
            return nil
        }

        let layoutAttributes = _layoutAttributes.map({
            $0.copy() as! UICollectionViewLayoutAttributes
        })

        // 先按照每个 item 的 centerY 分组
        var rowCollections = [CGFloat: [UICollectionViewLayoutAttributes]]()

        for (_, attributes) in layoutAttributes.enumerated() {
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
            
            let rowItemsCount = rowCollection.count

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

            let rowFullWidth: CGFloat = rowCollection.map({ $0.frame.width }).reduce(0, +) + CGFloat(rowItemsCount - 1) * minimumInteritemSpacing

            let firstOffset: CGFloat
            if let collectionView = collectionView {
                firstOffset = (collectionView.frame.width - rowFullWidth) / 2
            } else {
                fatalError("not collectionView")
            }

            for attributes in rowCollection {

                var itemFrame = attributes.frame

                if attributes.representedElementCategory == .cell {
                    if previousFrame.equalTo(CGRect.zero) {
                        itemFrame.origin.x = firstOffset //+ leftEdgeInset
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

