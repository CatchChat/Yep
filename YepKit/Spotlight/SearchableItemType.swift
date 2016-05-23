//
//  SearchableItemType.swift
//  Yep
//
//  Created by NIX on 16/3/30.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import CoreSpotlight

public enum SearchableItemType: String {

    case User
    case Feed
}

public func searchableItemID(searchableItemType itemType: SearchableItemType, itemID: String) -> String {

    return "\(itemType)/\(itemID)"
}

public func searchableItem(searchableItemID searchableItemID: String) -> (itemType: SearchableItemType, itemID: String)? {

    let parts = searchableItemID.componentsSeparatedByString("/")

    guard parts.count == 2 else {
        return nil
    }

    guard let itemType = SearchableItemType(rawValue: parts[0]) else {
        return nil
    }

    return (itemType: itemType, itemID: parts[1])
}

public func deleteSearchableItems(searchableItemType itemType: SearchableItemType, itemIDs: [String]) {

    guard !itemIDs.isEmpty else {
        return
    }

    let toDeleteSearchableItemIDs = itemIDs.map({
        searchableItemID(searchableItemType: itemType, itemID: $0)
    })

    CSSearchableIndex.defaultSearchableIndex().deleteSearchableItemsWithIdentifiers(toDeleteSearchableItemIDs, completionHandler: { error in
        if error != nil {
            println(error!.localizedDescription)

        } else {
            if itemIDs.count == 1 {
                println("deleteSearchableItem \(itemType): \(itemIDs[0]) OK")
            } else {
                println("deleteSearchableItems \(itemType): count \(itemIDs.count) OK")
            }
        }
    })
}

