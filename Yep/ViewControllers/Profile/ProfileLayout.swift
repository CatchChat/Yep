//
//  ProfileLayout.swift
//  Yep
//
//  Created by NIX on 15/4/8.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ProfileLayout: UICollectionViewFlowLayout {

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

        return layoutAttributes
    }

    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
}
