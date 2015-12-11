//
//  UICollectionView+Yep.swift
//  Yep
//
//  Created by nixzhu on 15/12/11.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

extension UICollectionView {

    enum WayToUpdate {

        case None
        case ReloadData
        case Insert([NSIndexPath])

        var needsLabor: Bool {

            switch self {
            case .None:
                return false
            case .ReloadData:
                return true
            case .Insert:
                return true
            }
        }

        func performWithCollectionView(collectionView: UICollectionView) {

            switch self {
            case .None:
                println("collectionView WayToUpdate: None")
                break
            case .ReloadData:
                println("collectionView WayToUpdate: ReloadData")
                collectionView.reloadData()
            case .Insert(let indexPaths):
                println("collectionView WayToUpdate: Insert")
                collectionView.insertItemsAtIndexPaths(indexPaths)
            }
        }
    }
}

