//
//  NSFileManager+Yep.swift
//  Yep
//
//  Created by NIX on 15/3/31.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

extension NSFileManager {
    class func yepCachesURL() -> NSURL {
        return NSFileManager.defaultManager().URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false, error: nil)!
    }

    // MARK: Avatar

    class func yepAvatarCachesURL() -> NSURL? {

        let fileManager = NSFileManager.defaultManager()

        let avatarCachesURL = yepCachesURL().URLByAppendingPathComponent("avatar_caches", isDirectory: true)

        if fileManager.createDirectoryAtURL(avatarCachesURL, withIntermediateDirectories: true, attributes: nil, error: nil) {
            return avatarCachesURL
        }

        return nil
    }

    class func yepAvatarURLWithName(name: String) -> NSURL? {

        if let avatarCachesURL = yepAvatarCachesURL() {
            return avatarCachesURL.URLByAppendingPathComponent("\(name).jpg")
        }

        return nil
    }

    class func saveAvatarImage(avatarImage: UIImage, withName name: String) -> NSURL? {

        if let avatarURL = yepAvatarURLWithName(name) {
            let imageData = UIImageJPEGRepresentation(avatarImage, 0.8)
            if NSFileManager.defaultManager().createFileAtPath(avatarURL.path!, contents: imageData, attributes: nil) {
                return avatarURL
            }
        }

        return nil
    }

    // MARK: Message

    class func yepMessageCachesURL() -> NSURL? {

        let fileManager = NSFileManager.defaultManager()

        let messageCachesURL = yepCachesURL().URLByAppendingPathComponent("message_caches", isDirectory: true)

        if fileManager.createDirectoryAtURL(messageCachesURL, withIntermediateDirectories: true, attributes: nil, error: nil) {
            return messageCachesURL
        }

        return nil
    }

    class func yepMessageImageURLWithName(name: String) -> NSURL? {

        if let messageCachesURL = yepMessageCachesURL() {
            return messageCachesURL.URLByAppendingPathComponent("\(name).jpg")
        }

        return nil
    }

    class func saveMessageImageData(messageImageData: NSData, withName name: String) -> NSURL? {

        if let messageImageURL = yepMessageImageURLWithName(name) {
            if NSFileManager.defaultManager().createFileAtPath(messageImageURL.path!, contents: messageImageData, attributes: nil) {
                return messageImageURL
            }
        }

        return nil
    }
}
