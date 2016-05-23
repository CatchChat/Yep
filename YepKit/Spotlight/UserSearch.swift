//
//  UserSearch.swift
//  Yep
//
//  Created by NIX on 16/3/30.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import CoreSpotlight
import MobileCoreServices.UTType

public let userDomainIdentifier = "Catch-Inc.Yep.User"

@available(iOS 9.0, *)
public extension User {

    public var attributeSet: CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        attributeSet.title = compositedName
        attributeSet.contentDescription = introduction
        attributeSet.thumbnailData = avatar?.roundMini
        attributeSet.keywords = [nickname, username]
        return attributeSet
    }
}
