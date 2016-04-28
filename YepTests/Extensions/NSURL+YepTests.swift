//
//  NSURL+YepTests.swift
//  Yep
//
//  Created by NIX on 16/4/28.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

extension NSURL {

    private var yeptests_queryItems: [NSURLQueryItem] {

        if let components = NSURLComponents(URL: self, resolvingAgainstBaseURL: false), queryItems = components.queryItems {
            return queryItems
        }

        return []
    }

    func yeptests_containsQueryItem(queryItem: NSURLQueryItem) -> Bool {

        return yeptests_queryItems.contains(queryItem)
    }
}

