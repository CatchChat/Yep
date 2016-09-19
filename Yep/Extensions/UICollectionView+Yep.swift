//
//  UICollectionView+Yep.swift
//  Yep
//
//  Created by nixzhu on 15/12/11.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

extension UICollectionView {

    enum WayToUpdate {

        case none
        case reloadData
        case insert([IndexPath])

        var needsLabor: Bool {

            switch self {
            case .none:
                return false
            case .reloadData:
                return true
            case .insert:
                return true
            }
        }

        func performWithCollectionView(_ collectionView: UICollectionView) {

            switch self {

            case .none:
                println("collectionView WayToUpdate: None")
                break

            case .reloadData:
                println("collectionView WayToUpdate: ReloadData")
                SafeDispatch.async {
                    collectionView.reloadData()
                }

            case .insert(let indexPaths):
                println("collectionView WayToUpdate: Insert")
                SafeDispatch.async {
                    collectionView.insertItemsAtIndexPaths(indexPaths)
                }
            }
        }
    }
}

extension UICollectionView {

    func registerClassOf<T: UICollectionViewCell>(_: T.Type) where T: Reusable {

        register(T.self, forCellWithReuseIdentifier: T.yep_reuseIdentifier)
    }

    func registerNibOf<T: UICollectionViewCell>(_: T.Type) where T: Reusable, T: NibLoadable {

        let nib = UINib(nibName: T.yep_nibName, bundle: nil)
        register(nib, forCellWithReuseIdentifier: T.yep_reuseIdentifier)
    }

    func registerHeaderNibOf<T: UICollectionReusableView>(_: T.Type) where T: Reusable, T: NibLoadable {

        let nib = UINib(nibName: T.yep_nibName, bundle: nil)
        register(nib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: T.yep_reuseIdentifier)
    }

    func registerFooterClassOf<T: UICollectionReusableView>(_: T.Type) where T: Reusable {

        register(T.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: T.yep_reuseIdentifier)
    }

    func dequeueReusableCell<T: UICollectionViewCell>(forIndexPath indexPath: IndexPath) -> T where T: Reusable {
        
        guard let cell = self.dequeueReusableCell(withReuseIdentifier: T.yep_reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.yep_reuseIdentifier)")
        }

        return cell
    }

    func dequeueReusableSupplementaryView<T: UICollectionReusableView>(ofKind kind: String, forIndexPath indexPath: IndexPath) -> T where T: Reusable {

        guard let view = self.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: T.yep_reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue supplementary view with identifier: \(T.yep_reuseIdentifier), kind: \(kind)")
        }

        return view
    }
}

