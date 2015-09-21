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
        return try! NSFileManager.defaultManager().URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
    }

    // MARK: Avatar

    class func yepAvatarCachesURL() -> NSURL? {

        let fileManager = NSFileManager.defaultManager()

        let avatarCachesURL = yepCachesURL().URLByAppendingPathComponent("avatar_caches", isDirectory: true)

        do {
            try fileManager.createDirectoryAtURL(avatarCachesURL, withIntermediateDirectories: true, attributes: nil)
            return avatarCachesURL
        } catch _ {
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

    class func deleteAvatarImageWithName(name: String) {
        if let avatarURL = yepAvatarURLWithName(name) {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(avatarURL)
            } catch _ {
            }
        }
    }

    // MARK: Message

    class func yepMessageCachesURL() -> NSURL? {

        let fileManager = NSFileManager.defaultManager()

        let messageCachesURL = yepCachesURL().URLByAppendingPathComponent("message_caches", isDirectory: true)

        do {
            try fileManager.createDirectoryAtURL(messageCachesURL, withIntermediateDirectories: true, attributes: nil)
            return messageCachesURL
        } catch _ {
        }

        return nil
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

    class func removeMessageImageFileWithName(name: String) {

        if name.isEmpty {
            return
        }

        if let messageImageURL = yepMessageImageURLWithName(name) {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(messageImageURL)
            } catch _ {
            }
        }
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

    class func removeMessageAudioFileWithName(name: String) {

        if name.isEmpty {
            return
        }

        if let messageAudioURL = yepMessageAudioURLWithName(name) {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(messageAudioURL)
            } catch _ {
            }
        }
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

    class func removeMessageVideoFilesWithName(name: String, thumbnailName: String) {

        if !name.isEmpty {
            if let messageVideoURL = yepMessageVideoURLWithName(name) {
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(messageVideoURL)
                } catch _ {
                }
            }
        }

        if !thumbnailName.isEmpty {
            if let messageImageURL = yepMessageImageURLWithName(thumbnailName) {
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(messageImageURL)
                } catch _ {
                }
            }
        }
    }

    // MARK: Clean Caches

    class func cleanCachesDirectoryAtURL(cachesDirectoryURL: NSURL) {
        let fileManager = NSFileManager.defaultManager()

        if let fileURLs = (try? fileManager.contentsOfDirectoryAtURL(cachesDirectoryURL, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions())) {
            for fileURL in fileURLs {
                do {
                    try fileManager.removeItemAtURL(fileURL)
                } catch _ {
                }
            }
        }
    }

    class func cleanAvatarCaches() {
        if let avatarCachesURL = yepAvatarCachesURL() {
            cleanCachesDirectoryAtURL(avatarCachesURL)
        }
    }

    class func cleanMessageCaches() {
        if let messageCachesURL = yepMessageCachesURL() {
            cleanCachesDirectoryAtURL(messageCachesURL)
        }
    }

}
