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

extension UICollectionView {

    func registerClassOf<T: UICollectionViewCell where T: Reusable>(_: T.Type) {

        registerClass(T.self, forCellWithReuseIdentifier: T.reuseIdentifier)
    }

    func registerNibOf<T: UICollectionViewCell where T: Reusable, T: NibLoadable>(_: T.Type) {

        let bundle = NSBundle(forClass: T.self)
        let nib = UINib(nibName: T.nibName, bundle: bundle)

        registerNib(nib, forCellWithReuseIdentifier: T.reuseIdentifier)
    }

    func registerHeaderNibOf<T: UICollectionReusableView where T: Reusable, T: NibLoadable>(_: T.Type) {

        let bundle = NSBundle(forClass: T.self)
        let nib = UINib(nibName: T.nibName, bundle: bundle)

        registerNib(nib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: T.reuseIdentifier)
    }

    func registerFooterClassOf<T: UICollectionReusableView where T: Reusable>(_: T.Type) {

        registerClass(T.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: T.reuseIdentifier)
    }

    func dequeueReusableCell<T: UICollectionViewCell where T: Reusable>(forIndexPath indexPath: NSIndexPath) -> T {
        
        guard let cell = dequeueReusableCellWithReuseIdentifier(T.reuseIdentifier, forIndexPath: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }

        return cell
    }

    func dequeueReusableSupplementaryView<T: UICollectionReusableView where T: Reusable>(ofKind kind: String, forIndexPath indexPath: NSIndexPath) -> T {

        guard let view = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: T.reuseIdentifier, forIndexPath: indexPath) as? T else {
            fatalError("Could not dequeue supplementary view with identifier: \(T.reuseIdentifier), kind: \(kind)")
        }

        return view
    }

}

