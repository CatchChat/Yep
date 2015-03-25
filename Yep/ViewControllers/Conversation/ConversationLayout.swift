//
//  ConversationLayout.swift
//  Yep
//
//  Created by NIX on 15/3/25.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ConversationLayout: UICollectionViewFlowLayout {

    var animator: UIDynamicAnimator?

    var needUpdate = false {
        willSet {
            if newValue {
                animator = nil
            }
        }
    }

    // 减震
    var springDampling: CGFloat = 0.5 {
        willSet {
            for spring in animator!.behaviors as! [UIAttachmentBehavior] {
                spring.damping = newValue
            }
        }
    }

    // 频率
    var springFrequency: CGFloat = 0.8 {
        willSet {
            for spring in animator!.behaviors as! [UIAttachmentBehavior] {
                spring.frequency = newValue
            }
        }
    }

    // 阻力系数
    var resistanceFactor: CGFloat = 1100


    override func prepareLayout() {
        super.prepareLayout()

        if animator == nil {
            needUpdate = false

            animator = UIDynamicAnimator(collectionViewLayout: self)

            if let items = super.layoutAttributesForElementsInRect(CGRect(origin: CGPointZero, size: self.collectionViewContentSize())) as? [UICollectionViewLayoutAttributes] {

                for item in items {
                    addSpringForItem(item)
                }
            }
        }
    }

    private func addSpringForItem(item: UICollectionViewLayoutAttributes) {
        let spring = UIAttachmentBehavior(item: item, attachedToAnchor: item.center)

        spring.length = 0
        spring.damping = springDampling
        spring.frequency = springFrequency

        animator!.addBehavior(spring)
    }

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
        return animator!.itemsInRect(rect)
    }

    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {

        return animator!.layoutAttributesForCellAtIndexPath(indexPath)
    }

    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        let scrollView = collectionView! as UIScrollView

        let scrollDelta = newBounds.origin.y - scrollView.bounds.origin.y

        let touchLocation = scrollView.panGestureRecognizer.locationInView(scrollView)

        for spring in animator!.behaviors as! [UIAttachmentBehavior] {
            let anchorPoint = spring.anchorPoint
            let distanceFromTouch = abs(touchLocation.y - anchorPoint.y)
            let scrollResistance = distanceFromTouch / resistanceFactor

            let attributes = spring.items.first as! UICollectionViewLayoutAttributes

            attributes.center.y += scrollDelta > 0 ? min(scrollDelta, scrollDelta * scrollResistance) : max(scrollDelta, scrollDelta * scrollResistance)

            animator!.updateItemUsingCurrentState(attributes)
        }

        return false
    }

}
