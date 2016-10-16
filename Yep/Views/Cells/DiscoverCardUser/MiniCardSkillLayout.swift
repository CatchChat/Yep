//
//  MiniCardSkillLayout.swift
//  Yep
//
//  Created by zhowkevin on 15/10/12.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class MiniCardSkillLayout: UICollectionViewFlowLayout {

    var scrollUpAction: ((_ progress: CGFloat) -> Void)?

    let leftEdgeInset: CGFloat = 0
    
    override func prepare() {
        self.minimumLineSpacing = 5
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        guard let _layoutAttributes = super.layoutAttributesForElements(in: rect) else {
            return nil
        }

        let layoutAttributes = _layoutAttributes.map({
            $0.copy() as! UICollectionViewLayoutAttributes
        })

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
                

                    if previousFrame.equalTo(CGRect.zero) {
                        itemFrame.origin.x = leftEdgeInset
                    } else {
                        itemFrame.origin.x = previousFrame.maxX + minimumInteritemSpacing
                    }
                    
                    attributes.frame = itemFrame

                
                previousFrame = itemFrame
            }
        }
        
        return layoutAttributes
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}

