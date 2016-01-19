//
//  NSURL+Yep.swift
//  Yep
//
//  Created by nixzhu on 15/11/9.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import Foundation

private let yepHost = "soyep.com"

extension NSURL {

    private var allQueryItems: [NSURLQueryItem] {

        if let components = NSURLComponents(URL: self, resolvingAgainstBaseURL: false), queryItems = components.queryItems {
            return queryItems
        }

        return []
    }

    private func queryItemForKey(key: String) -> NSURLQueryItem? {

        let predicate = NSPredicate(format: "name=%@", key)
        return (allQueryItems as NSArray).filteredArrayUsingPredicate(predicate).first as? NSURLQueryItem
    }
    
    func yep_matchSharedFeed(completion: DiscoveredFeed -> Void) -> Bool {

        guard let host = host where host == yepHost else {
            return false
        }

        guard let pathComponents = pathComponents else {
            return false
        }

        if let first = pathComponents[safe: 1] where first == "groups" {
            if let second = pathComponents[safe: 2] where second == "share" {
                if let sharedToken = queryItemForKey("token")?.value {
                    feedWithSharedToken(sharedToken, failureHandler: nil, completion: { feed in
                        dispatch_async(dispatch_get_main_queue()) {
                            completion(feed)
                        }
                    })

                    return true
                }
            }
        }

        return false
    }

    // make sure put it in last

    func yep_matchProfile(completion: DiscoveredUser -> Void) -> Bool {

        guard let host = host where host == yepHost else {
            return false
        }

        guard let pathComponents = pathComponents else {
            return false
        }

        if let username = pathComponents[safe: 1] {

            discoverUserByUsername(username, failureHandler: nil, completion: { discoveredUser in

                dispatch_async(dispatch_get_main_queue()) {
                    completion(discoveredUser)
                }
            })

            return true
        }

        return false
    }

    // iTunes

    var yep_iTunesArtworkID: String? {

        if let artworkID = queryItemForKey("i")?.value {
            return artworkID

        } else {
            if let artworkID = lastPathComponent?.stringByReplacingOccurrencesOfString("id", withString: "") {
                return artworkID
            }
        }

        return nil
    }

    enum AppleOnlineStoreHost: String {
        case iTunesLong = "itunes.apple.com"
        case iTunesShort = "itun.es"
        case AppStoreShort = "appsto.re"
    }

    var yep_isAppleiTunesURL: Bool {

        guard let host = host, _ = AppleOnlineStoreHost(rawValue: host) else {
            return false
        }

        return true
    }

    var yep_appleAllianceURL: NSURL {

        guard self.yep_isAppleiTunesURL else {
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
}

