//
//  NSURL+OpenGraph.swift
//  Yep
//
//  Created by NIX on 16/5/20.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

extension URL {

    fileprivate var opengraph_allQueryItems: [URLQueryItem] {

        if let components = URLComponents(url: self, resolvingAgainstBaseURL: false), let queryItems = components.queryItems {
            return queryItems
        }

        return []
    }

    fileprivate func opengraph_queryItemForKey(_ key: String) -> URLQueryItem? {

        let predicate = NSPredicate(format: "name=%@", key)
        return (opengraph_allQueryItems as NSArray).filtered(using: predicate).first as? URLQueryItem
    }
}

extension URL {

    var opengraph_appleAllianceURL: URL {

        guard self.opengraph_isAppleiTunesURL else {
            return self
        }

        guard var URLComponents = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }

        let queryItem = URLQueryItem(name: "at", value: "1010l9k7")

        if URLComponents.queryItems == nil {
            URLComponents.queryItems = [queryItem]
        } else {
            URLComponents.queryItems?.append(queryItem)
        }

        guard let resultURL = URLComponents.url else {
            return self
        }

        return resultURL
    }

    var yep_iTunesArtworkID: String? {

        if let artworkID = opengraph_queryItemForKey("i")?.value {
            return artworkID

        } else {
            let artworkID = lastPathComponent.replacingOccurrences(of: "id", with: "")
            return artworkID
        }
    }
    
    enum AppleOnlineStoreHost: String {
        case iTunesLong = "itunes.apple.com"
        case iTunesShort = "itun.es"
        case appStoreShort = "appsto.re"
    }

    var opengraph_isAppleiTunesURL: Bool {

        guard let host = host, let _ = AppleOnlineStoreHost(rawValue: host) else {
            return false
        }

        return true
    }
}

