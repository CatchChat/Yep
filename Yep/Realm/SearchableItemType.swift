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

func relatedUniqueIdentifier(searchableItemType itemType: SearchableItemType, searchableItemID itemID: String) -> String {

    return "\(itemType)/\(itemID)"
}