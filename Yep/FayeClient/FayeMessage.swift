//
//  FayeMessage.swift
//  Yep
//
//  Created by NIX on 16/5/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

public struct FayeMessage {

    let ID: String?
    let channel: String
    let clientID: String
    let successful: Bool
    let authSuccessful: Bool?
    let version: String
    let minimunVersion: String?
    let supportedConnectionTypes: [String]
    let advice: [String: AnyObject]
    let error: String?
    let subscription: String?
    let timestamp: NSDate?
    let data: [String: AnyObject]
    let ext: [String: AnyObject]

    static func messageFromDictionary(info: [String: AnyObject]) -> FayeMessage? {

        let ID = info["id"] as? String
        guard let channel = info["channel"] as? String else { return nil }
        guard let clientID = info["clientId"] as? String else { return nil }
        guard let successful = info["successful"] as? Bool else { return nil }
        let authSuccessful = info["authSuccessful"] as? Bool
        guard let version = info["version"] as? String else { return nil }
        let minimumVersion = info["minimumVersion"] as? String
        guard let supportedConnectionTypes = info["supportedConnectionTypes"] as? [String] else { return nil }
        let advice = (info["advice"] as? [String: AnyObject]) ?? [:]
        let error = info["error"] as? String
        let subscription = info["subscription"] as? String
        let timestamp: NSDate?
        if let timestampUnixTime = info["timestamp"] as? NSTimeInterval {
            timestamp = NSDate(timeIntervalSince1970: timestampUnixTime)
        } else {
            timestamp = nil
        }
        let data = (info["data"] as? [String: AnyObject]) ?? [:]
        let ext = (info["ext"] as? [String: AnyObject]) ?? [:]

        return FayeMessage(ID: ID, channel: channel, clientID: clientID, successful: successful, authSuccessful: authSuccessful, version: version, minimunVersion: minimumVersion, supportedConnectionTypes: supportedConnectionTypes, advice: advice, error: error, subscription: subscription, timestamp: timestamp, data: data, ext: ext)
    }
}

