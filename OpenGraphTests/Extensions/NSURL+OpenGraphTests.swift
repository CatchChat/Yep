//
//  NSURL+OpenGraphTests.swift
//  Yep
//
//  Created by NIX on 16/5/20.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

extension NSURL {

    private var opengraphtests_queryItems: [NSURLQueryItem] {

        if let components = NSURLComponents(URL: self, resolvingAgainstBaseURL: false), queryItems = components.queryItems {
            return queryItems
        }

        return []
    }

    func opengraphtests_containsQueryItem(queryItem: NSURLQueryItem) -> Bool {

        return opengraphtests_queryItems.contains(queryItem)
    }
}

