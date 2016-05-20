//
//  NSURL+OpenGraph.swift
//  Yep
//
//  Created by NIX on 16/5/20.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

extension NSURL {

    var opengraph_appleAllianceURL: NSURL {

        guard self.opengraph_isAppleiTunesURL else {
            return self
        }

        guard let URLComponents = NSURLComponents(URL: self, resolvingAgainstBaseURL: false) else {
            return self
        }

        let queryItem = NSURLQueryItem(name: "at", value: "1010l9k7")

        if URLComponents.queryItems == nil {
            URLComponents.queryItems = [queryItem]
        } else {
            URLComponents.queryItems?.append(queryItem)
        }

        guard let resultURL = URLComponents.URL else {
            return self
        }

        return resultURL
    }
    
    enum AppleOnlineStoreHost: String {
        case iTunesLong = "itunes.apple.com"
        case iTunesShort = "itun.es"
        case AppStoreShort = "appsto.re"
    }

    var opengraph_isAppleiTunesURL: Bool {

        guard let host = host, _ = AppleOnlineStoreHost(rawValue: host) else {
            return false
        }

        return true
    }
}

