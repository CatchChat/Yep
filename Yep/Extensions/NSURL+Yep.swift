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

        let components = NSURLComponents(URL: self, resolvingAgainstBaseURL: false)!
        let allQueryItems = components.queryItems!
        return allQueryItems as [NSURLQueryItem]
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

        if let songID = queryItemForKey("i")?.value {
            return songID
        }

        if let albumID = queryItemForKey("id")?.value {
            return albumID
        }

        return nil
    }
}

