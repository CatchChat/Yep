//
//  NSURL+OpenGraphTests.swift
//  Yep
//
//  Created by NIX on 16/5/20.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

extension URL {

    fileprivate var opengraphtests_queryItems: [URLQueryItem] {

        if let components = URLComponents(url: self, resolvingAgainstBaseURL: false), let queryItems = components.queryItems {
            return queryItems
        }

        return []
    }

    func opengraphtests_containsQueryItem(_ queryItem: URLQueryItem) -> Bool {

        return opengraphtests_queryItems.contains(queryItem)
    }
}

