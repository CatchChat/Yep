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

    class func deleteAllMessageCaches() {
        if let messagesCachesURL = yepMessageCachesURL() {
            let fileManager = NSFileManager.defaultManager()

            if let fileURLs = fileManager.contentsOfDirectoryAtURL(messagesCachesURL, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.allZeros, error: nil) as? [NSURL] {
                for fileURL in fileURLs {
                    fileManager.removeItemAtURL(fileURL, error: nil)
                }
            }
        }
    }

    // Image
    
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

    // Audio

    class func yepMessageAudioURLWithName(name: String) -> NSURL? {

        if let messageCachesURL = yepMessageCachesURL() {
            return messageCachesURL.URLByAppendingPathComponent("\(name).m4a")
        }

        return nil
    }

    class func saveMessageAudioData(messageAudioData: NSData, withName name: String) -> NSURL? {

        if let messageAudioURL = yepMessageAudioURLWithName(name) {
            if NSFileManager.defaultManager().createFileAtPath(messageAudioURL.path!, contents: messageAudioData, attributes: nil) {
                return messageAudioURL
            }
        }

        return nil
    }

    // Video

    class func yepMessageVideoURLWithName(name: String) -> NSURL? {

        if let messageCachesURL = yepMessageCachesURL() {
            return messageCachesURL.URLByAppendingPathComponent("\(name).mp4")
        }

        return nil
    }

    class func saveMessageVideoData(messageVideoData: NSData, withName name: String) -> NSURL? {

        if let messageVideoURL = yepMessageVideoURLWithName(name) {
            if NSFileManager.defaultManager().createFileAtPath(messageVideoURL.path!, contents: messageVideoData, attributes: nil) {
                return messageVideoURL
            }
        }

        return nil
    }

}
