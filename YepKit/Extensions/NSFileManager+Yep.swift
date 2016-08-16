//
//  NSFileManager+Yep.swift
//  Yep
//
//  Created by NIX on 15/3/31.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

public enum FileExtension: String {
    case JPEG = "jpg"
    case MP4 = "mp4"
    case M4A = "m4a"

    public var mimeType: String {
        switch self {
        case .JPEG:
            return "image/jpeg"
        case .MP4:
            return "video/mp4"
        case .M4A:
            return "audio/m4a"
        }
    }
}

public extension NSFileManager {

    public class func yepCachesURL() -> NSURL {
        return try! NSFileManager.defaultManager().URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
    }

    // MARK: Avatar

    public class func yepAvatarCachesURL() -> NSURL? {

        let fileManager = NSFileManager.defaultManager()

        let avatarCachesURL = yepCachesURL().URLByAppendingPathComponent("avatar_caches", isDirectory: true)

        do {
            try fileManager.createDirectoryAtURL(avatarCachesURL, withIntermediateDirectories: true, attributes: nil)
            return avatarCachesURL
        } catch let error {
            println("Directory create: \(error)")
        }

        return nil
    }

    public class func yepAvatarURLWithName(name: String) -> NSURL? {

        if let avatarCachesURL = yepAvatarCachesURL() {
            return avatarCachesURL.URLByAppendingPathComponent("\(name).\(FileExtension.JPEG.rawValue)")
        }

        return nil
    }

    public class func saveAvatarImage(avatarImage: UIImage, withName name: String) -> NSURL? {

        if let avatarURL = yepAvatarURLWithName(name) {
            let imageData = UIImageJPEGRepresentation(avatarImage, 0.8)
            if NSFileManager.defaultManager().createFileAtPath(avatarURL.path!, contents: imageData, attributes: nil) {
                return avatarURL
            }
        }

        return nil
    }

    public class func deleteAvatarImageWithName(name: String) {
        if let avatarURL = yepAvatarURLWithName(name) {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(avatarURL)
            } catch let error {
                println("File delete: \(error)")
            }
        }
    }

    // MARK: Message

    public class func yepMessageCachesURL() -> NSURL? {

        let fileManager = NSFileManager.defaultManager()

        let messageCachesURL = yepCachesURL().URLByAppendingPathComponent("message_caches", isDirectory: true)

        do {
            try fileManager.createDirectoryAtURL(messageCachesURL, withIntermediateDirectories: true, attributes: nil)
            return messageCachesURL
        } catch let error {
            println("Directory create: \(error)")
        }

        return nil
    }

    // Image

    public class func yepMessageImageURLWithName(name: String) -> NSURL? {

        if let messageCachesURL = yepMessageCachesURL() {
            return messageCachesURL.URLByAppendingPathComponent("\(name).\(FileExtension.JPEG.rawValue)")
        }

        return nil
    }

    public class func saveMessageImageData(messageImageData: NSData, withName name: String) -> NSURL? {

        if let messageImageURL = yepMessageImageURLWithName(name) {
            if NSFileManager.defaultManager().createFileAtPath(messageImageURL.path!, contents: messageImageData, attributes: nil) {
                return messageImageURL
            }
        }

        return nil
    }

    public class func removeMessageImageFileWithName(name: String) {

        if name.isEmpty {
            return
        }

        if let messageImageURL = yepMessageImageURLWithName(name) {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(messageImageURL)
            } catch let error {
                println("File delete: \(error)")
            }
        }
    }

    // Audio

    public class func yepMessageAudioURLWithName(name: String) -> NSURL? {

        if let messageCachesURL = yepMessageCachesURL() {
            return messageCachesURL.URLByAppendingPathComponent("\(name).\(FileExtension.M4A.rawValue)")
        }

        return nil
    }

    public class func saveMessageAudioData(messageAudioData: NSData, withName name: String) -> NSURL? {

        if let messageAudioURL = yepMessageAudioURLWithName(name) {
            if NSFileManager.defaultManager().createFileAtPath(messageAudioURL.path!, contents: messageAudioData, attributes: nil) {
                return messageAudioURL
            }
        }

        return nil
    }

    public class func removeMessageAudioFileWithName(name: String) {

        if name.isEmpty {
            return
        }

        if let messageAudioURL = yepMessageAudioURLWithName(name) {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(messageAudioURL)
            } catch let error {
                println("File delete: \(error)")
            }
        }
    }

    // Video

    public class func yepMessageVideoURLWithName(name: String) -> NSURL? {

        if let messageCachesURL = yepMessageCachesURL() {
            return messageCachesURL.URLByAppendingPathComponent("\(name).\(FileExtension.MP4.rawValue)")
        }

        return nil
    }

    public class func saveMessageVideoData(messageVideoData: NSData, withName name: String) -> NSURL? {

        if let messageVideoURL = yepMessageVideoURLWithName(name) {
            if NSFileManager.defaultManager().createFileAtPath(messageVideoURL.path!, contents: messageVideoData, attributes: nil) {
                return messageVideoURL
            }
        }

        return nil
    }

    public class func removeMessageVideoFilesWithName(name: String, thumbnailName: String) {

        if !name.isEmpty {
            if let messageVideoURL = yepMessageVideoURLWithName(name) {
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(messageVideoURL)
                } catch let error {
                    println("File delete: \(error)")
                }
            }
        }

        if !thumbnailName.isEmpty {
            if let messageImageURL = yepMessageImageURLWithName(thumbnailName) {
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(messageImageURL)
                } catch let error {
                    println("File delete: \(error)")
                }
            }
        }
    }

    // MARK: Clean Caches

    public class func cleanCachesDirectoryAtURL(cachesDirectoryURL: NSURL) {
        let fileManager = NSFileManager.defaultManager()

        if let fileURLs = (try? fileManager.contentsOfDirectoryAtURL(cachesDirectoryURL, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions())) {
            for fileURL in fileURLs {
                do {
                    try fileManager.removeItemAtURL(fileURL)
                } catch let error {
                    println("File delete: \(error)")
                }
            }
        }
    }

    public class func cleanAvatarCaches() {
        if let avatarCachesURL = yepAvatarCachesURL() {
            cleanCachesDirectoryAtURL(avatarCachesURL)
        }
    }
    
    public class func cleanMessageCaches() {
        if let messageCachesURL = yepMessageCachesURL() {
            cleanCachesDirectoryAtURL(messageCachesURL)
        }
    }
}

