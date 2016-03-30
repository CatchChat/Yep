//
//  SearchableItemType.swift
//  Yep
//
//  Created by NIX on 16/3/30.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

enum SearchableItemType: String {

    case User
    case Feed
}

func searchableItemID(searchableItemType itemType: SearchableItemType, itemID: String) -> String {

    return "\(itemType)/\(itemID)"
}

func searchableItem(searchableItemID searchableItemID: String) -> (itemType: SearchableItemType, itemID: String)? {

    let parts = searchableItemID.componentsSeparatedByString("/")

    guard parts.count == 2 else {
        return nil
    }

    guard let itemType = SearchableItemType(rawValue: parts[0]) else {
        return nil
    }

    return (itemType: itemType, itemID: parts[1])
}
