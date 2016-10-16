//
//  RegisterSkillsLayout.swift
//  Yep
//
//  Created by kevinzhow on 15/4/19.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class RegisterSkillsLayout: UICollectionViewFlowLayout {
    
    var animator: UIDynamicAnimator!
    
    var visibleIndexPaths = NSMutableSet()
    
    var lastContentOffset = CGPoint(x: 0, y: 0)
    var lastScrollDelta: CGFloat!
    var lastTouchLocation: CGPoint!
    
    let kScrollPaddingRect: CGFloat = 100.0
    let kScrollRefreshThreshold: CGFloat = 50.0
    let kScrollResistanceCoefficient: CGFloat = 1 / 600.0

    override init() {
        super.init()
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        animator = UIDynamicAnimator(collectionViewLayout: self)
    }
    
    override func prepare() {
        super.prepare()

        let contentOffset = self.collectionView!.contentOffset
        
        // only refresh the set of UIAttachmentBehaviours if we've moved more than the scroll threshold since last load
        if (abs(contentOffset.y - lastContentOffset.y) < kScrollRefreshThreshold) && visibleIndexPaths.count > 0 {
            return
        }

        lastContentOffset = contentOffset
        
        let padding = kScrollPaddingRect
        let currentRect = CGRect(x: 0, y: contentOffset.y - padding, width: self.collectionView!.frame.size.width, height: self.collectionView!.frame.size.height + 3 * padding)
        
        let itemsInCurrentRect = super.layoutAttributesForElements(in: currentRect)! as NSArray
        let indexPathsInVisibleRect = NSSet(array: itemsInCurrentRect.value(forKey: "indexPath") as! [AnyObject])
        
        // Remove behaviours that are no longer visible
        
        for behaviour in animator!.behaviors as! [UIAttachmentBehavior] {

            guard let items = behaviour.items as? [UICollectionViewLayoutAttributes] else {
                continue
            }

            let indexPath = items.first?.indexPath
            
            let isInVisibleIndexPaths = indexPathsInVisibleRect.member(indexPath!) != nil
            if (!isInVisibleIndexPaths){
                animator.removeBehavior(behaviour)
                visibleIndexPaths.remove(indexPath!)
            }
        }
        
        // Find newly visible indexes
        let newVisibleItems = itemsInCurrentRect.filtered(using: NSPredicate(block: { (item, bindings) -> Bool in
            let isInVisibleIndexPaths = self.visibleIndexPaths.member((item! as AnyObject).indexPath) != nil
            return !isInVisibleIndexPaths
        }))

        for attribute in newVisibleItems as! [UICollectionViewLayoutAttributes] {
            let spring = UIAttachmentBehavior(item: attribute, attachedToAnchor: attribute.center)
            spring.length = 0
            spring.frequency = 1.5
            spring.damping = 0.8
            
            // If our touchLocation is not (0,0), we need to adjust our item's center
            if (lastScrollDelta != nil) {
                self.adjustSpring(spring, touchLocation: lastTouchLocation, scrollDelta: lastScrollDelta)
            }
            animator.addBehavior(spring)
            visibleIndexPaths.add(attribute.indexPath)
        }
    }
    
    func adjustSpring(_ spring: UIAttachmentBehavior, touchLocation: CGPoint, scrollDelta: CGFloat) {
        let anchorPoint = spring.anchorPoint
        let distanceFromTouch = fabs(touchLocation.y - anchorPoint.y)
        let scrollResistance = distanceFromTouch * kScrollResistanceCoefficient
        
        let attributes = spring.items.first as! UICollectionViewLayoutAttributes
        
        attributes.center.y += lastScrollDelta > 0 ? min(scrollDelta, scrollDelta * scrollResistance) : max(scrollDelta, scrollDelta * scrollResistance)
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if let layoutAttributes = animator!.layoutAttributesForCell(at: indexPath) {
            return layoutAttributes
        } else {
            let layoutAttributes = super.layoutAttributesForItem(at: indexPath)
            return layoutAttributes
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var newRect = rect
        let padding:CGFloat = kScrollPaddingRect
        newRect.size.height += 3.0 * padding
        newRect.origin.y -= padding
        return animator?.items(in: newRect) as? [UICollectionViewLayoutAttributes]
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        let scrollView = collectionView! as UIScrollView
        
        lastScrollDelta = newBounds.origin.y - scrollView.bounds.origin.y
        
        lastTouchLocation = scrollView.panGestureRecognizer.location(in: scrollView)
        
        for behaviour in animator!.behaviors as! [UIAttachmentBehavior] {
            adjustSpring(behaviour, touchLocation: lastTouchLocation, scrollDelta: lastScrollDelta)

            if let firstItem = behaviour.items.first {
                animator?.updateItem(usingCurrentState: firstItem)
            }
        }
        
        return false
    }
    
    func reset() {
        animator.removeAllBehaviors()
        visibleIndexPaths.removeAllObjects()
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
        attributes.frame = CGRect(x: 0, y: 0, width: 320, height: 50)
        
        return attributes
    }
}

