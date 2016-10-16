//
//  ConversationLayout.swift
//  Yep
//
//  Created by NIX on 15/3/25.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class ConversationLayout: UICollectionViewFlowLayout {

    override func prepare() {
        super.prepare()

        minimumLineSpacing = YepConfig.ChatCell.lineSpacing
    }

    fileprivate var insertIndexPathSet = Set<IndexPath>()

    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)

        var insertIndexPathSet = Set<IndexPath>()

        for updateItem in updateItems {
            switch updateItem.updateAction {
            case .insert:
                if let indexPath = updateItem.indexPathAfterUpdate {
                    insertIndexPathSet.insert(indexPath)
                }

            default:
                break
            }
        }

        self.insertIndexPathSet = insertIndexPathSet
    }

    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {

        let attributes = layoutAttributesForItem(at: itemIndexPath)

        // ref commit: 0183ad099ed9
        if insertIndexPathSet.count == 1 {
            if insertIndexPathSet.contains(itemIndexPath) {
                attributes?.frame.origin.y += 30
                insertIndexPathSet.remove(itemIndexPath)
            }
        }

        return attributes
    }
}

