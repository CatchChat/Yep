//
//  ConversationLayout.swift
//  Yep
//
//  Created by NIX on 15/3/25.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ConversationLayout: UICollectionViewFlowLayout {

    var lastTimeContentSize: CGSize?
    
    override func collectionViewContentSize() -> CGSize {
        var contentSize = super.collectionViewContentSize()
        
        if let lastTimeContentSize = lastTimeContentSize {
            if lastTimeContentSize.height > contentSize.height {
                contentSize.height = lastTimeContentSize.height
            }
        } else {
            lastTimeContentSize = contentSize
        }
        
        return contentSize
    }
    
    override func finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        var attr = super.finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath)
        
//        attr?.transform = CGAffineTransformRotate(CGAffineTransformMakeScale(0.2, 0.2), CGFloat(M_PI))
//        attr?.alpha = 0
//        attr?.center = CGPointMake(attr!.center.x, attr!.center.y )
        
        return attr
    }
    
}
