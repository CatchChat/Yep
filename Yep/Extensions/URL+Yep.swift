//
//  URL+Yep.swift
//  Yep
//
//  Created by nixzhu on 15/11/9.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import Foundation
import YepKit

extension URL {

    fileprivate var allQueryItems: [URLQueryItem] {

        if let components = URLComponents(url: self, resolvingAgainstBaseURL: false), let queryItems = components.queryItems {
            return queryItems
        }

        return []
    }

    fileprivate func queryItemForKey(_ key: String) -> URLQueryItem? {

        let predicate = NSPredicate(format: "name=%@", key)
        return (allQueryItems as NSArray).filtered(using: predicate).first as? URLQueryItem
    }
    
    func yep_matchSharedFeed(_ completion: @escaping (_ feed: DiscoveredFeed?) -> Void) -> Bool {

        guard let host = host, host == yepHost else {
            return false
        }

        guard
            let first = pathComponents[safe: 1], first == "groups",
            let second = pathComponents[safe: 2], second == "share",
            let sharedToken = queryItemForKey("token")?.value else {
                return false
        }

        feedWithSharedToken(sharedToken, failureHandler: { reason, errorMessage in
            SafeDispatch.async {
                completion(nil)
            }

        }, completion: { feed in
            SafeDispatch.async {
                completion(feed)
            }
        })

        return true
    }

    // make sure put it in last

    func yep_matchProfile(_ completion: @escaping (DiscoveredUser) -> Void) -> Bool {

        guard let host = host, host == yepHost else {
            return false
        }

        if let username = pathComponents[safe: 1] {

            discoverUserByUsername(username, failureHandler: nil, completion: { discoveredUser in

                SafeDispatch.async {
                    completion(discoveredUser)
                }
            })

            return true
        }

        return false
    }
}

extension URL {

    var yep_isNetworkURL: Bool {

        guard let scheme = scheme else {
            return false
        }

        switch scheme {
        case "http", "https":
            return true
        default:
            return false
        }
    }

    var yep_validSchemeNetworkURL: URL? {

        let scheme = self.scheme ?? ""

        if scheme.isEmpty {

            guard var URLComponents = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
                return nil
            }

            URLComponents.scheme = "http"

            return URLComponents.url

        } else {
            if yep_isNetworkURL {
                return self

            } else {
                return nil
            }
        }
    }
}

