//
//  AttributedStringCache.swift
//  Yep
//
//  Created by NIX on 16/8/2.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

class AttributedStringCache {

    static var sharedDictionary: [String: NSAttributedString] = [:]

    class func valueForKey(key: String) -> NSAttributedString? {

        return sharedDictionary[key]
    }

    class func setValue(attributedString: NSAttributedString, forKey key: String) {

        guard !key.isEmpty else {
            return
        }

        sharedDictionary[key] = attributedString
    }
}

