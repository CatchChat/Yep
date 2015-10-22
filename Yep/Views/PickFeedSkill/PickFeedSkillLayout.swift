//
//  PickFeedSkillLayout.swift
//  Yep
//
//  Created by nixzhu on 15/10/22.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class PickFeedSkillLayout: UICollectionViewFlowLayout {

    override func prepareLayout() {
        super.prepareLayout()

        minimumLineSpacing = 0
    }

    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {

        if let cv = self.collectionView {

            let cvBounds = cv.bounds
            let halfWidth = cvBounds.size.width * 0.5;
            let proposedContentOffsetCenterX = proposedContentOffset.x + halfWidth;

            if let attributesForVisibleCells = layoutAttributesForElementsInRect(cvBounds) {

                var candidateAttributes : UICollectionViewLayoutAttributes?
                for attributes in attributesForVisibleCells {

                    // == Skip comparison with non-cell items (headers and footers) == //
                    if attributes.representedElementCategory != UICollectionElementCategory.Cell {
                        continue
                    }

                    if let candAttrs = candidateAttributes {

                        let a = attributes.center.x - proposedContentOffsetCenterX
                        let b = candAttrs.center.x - proposedContentOffsetCenterX

                        if abs(a) < abs(b) {
                            candidateAttributes = attributes;
                        }

                    } else { // == First time in the loop == //

                        candidateAttributes = attributes;
                        continue;
                    }
                }

                return CGPoint(x: round(candidateAttributes!.center.x - halfWidth), y: proposedContentOffset.y)
            }
        }

        // Fallback
        return super.targetContentOffsetForProposedContentOffset(proposedContentOffset)
    }
}

