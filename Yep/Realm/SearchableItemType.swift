//
//  SearchableItemType.swift
//  Yep
//
//  Created by NIX on 16/3/30.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import CoreSpotlight

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

func deleteSearchableItemOfUser(userID userID: String) {
    if #available(iOS 9.0, *) {
        let feedSearchableItemID = searchableItemID(searchableItemType: .User, itemID: userID)
        CSSearchableIndex.defaultSearchableIndex().deleteSearchableItemsWithIdentifiers([feedSearchableItemID], completionHandler: { error in
            if error != nil {
                println(error!.localizedDescription)

            } else {
                println("deleteSearchableItemOfUser: \(userID) OK")
            }
        })
    }
}

func deleteSearchableItemOfFeed(feedID feedID: String) {
    if #available(iOS 9.0, *) {
        let feedSearchableItemID = searchableItemID(searchableItemType: .Feed, itemID: feedID)
        CSSearchableIndex.defaultSearchableIndex().deleteSearchableItemsWithIdentifiers([feedSearchableItemID], completionHandler: { error in
            if error != nil {
                println(error!.localizedDescription)

            } else {
                println("deleteSearchableItemOfFeed: \(feedID) OK")
            }
        })
    }
}

