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

private func deleteSearchableItem(searchableItemType itemType: SearchableItemType, itemID: String, printOK: Bool) {

    if #available(iOS 9.0, *) {

        let toDeleteSearchableItemID = searchableItemID(searchableItemType: itemType, itemID: itemID)

        CSSearchableIndex.defaultSearchableIndex().deleteSearchableItemsWithIdentifiers([toDeleteSearchableItemID], completionHandler: { error in
            if error != nil {
                println(error!.localizedDescription)

            } else {
                if printOK {
                    println("deleteSearchableItem \(itemType): \(itemID) OK")
                }
            }
        })
    }
}

func deleteSearchableItemOfUser(userID userID: String, printOK: Bool = true) {

    deleteSearchableItem(searchableItemType: .User, itemID: userID, printOK: printOK)
}

func deleteSearchableItemOfFeed(feedID feedID: String, printOK: Bool = true) {

    deleteSearchableItem(searchableItemType: .Feed, itemID: feedID, printOK: printOK)
}

