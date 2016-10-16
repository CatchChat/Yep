//
//  FileManager+Yep.swift
//  Yep
//
//  Created by NIX on 15/3/31.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

public enum FileExtension: String {
    case jpeg = "jpg"
    case mp4 = "mp4"
    case m4a = "m4a"

    public var mimeType: String {
        switch self {
        case .jpeg:
            return "image/jpeg"
        case .mp4:
            return "video/mp4"
        case .m4a:
            return "audio/m4a"
        }
    }
}

public extension FileManager {

    public class func yepCachesURL() -> URL {
        return try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }

    // MARK: Avatar

    public class func yepAvatarCachesURL() -> URL? {

        let fileManager = FileManager.default

        let avatarCachesURL = yepCachesURL().appendingPathComponent("avatar_caches", isDirectory: true)

        do {
            try fileManager.createDirectory(at: avatarCachesURL, withIntermediateDirectories: true, attributes: nil)
            return avatarCachesURL
        } catch let error {
            println("Directory create: \(error)")
        }

        return nil
    }

    public class func yepAvatarURLWithName(_ name: String) -> URL? {

        if let avatarCachesURL = yepAvatarCachesURL() {
            return avatarCachesURL.appendingPathComponent("\(name).\(FileExtension.jpeg.rawValue)")
        }

        return nil
    }

    public class func saveAvatarImage(_ avatarImage: UIImage, withName name: String) -> URL? {

        if let avatarURL = yepAvatarURLWithName(name) {
            let imageData = UIImageJPEGRepresentation(avatarImage, 0.8)
            if FileManager.default.createFile(atPath: avatarURL.path, contents: imageData, attributes: nil) {
                return avatarURL
            }
        }

        return nil
    }

    public class func deleteAvatarImageWithName(_ name: String) {
        if let avatarURL = yepAvatarURLWithName(name) {
            do {
                try FileManager.default.removeItem(at: avatarURL)
            } catch let error {
                println("File delete: \(error)")
            }
        }
    }

    // MARK: Message

    public class func yepMessageCachesURL() -> URL? {

        let fileManager = FileManager.default

        let messageCachesURL = yepCachesURL().appendingPathComponent("message_caches", isDirectory: true)

        do {
            try fileManager.createDirectory(at: messageCachesURL, withIntermediateDirectories: true, attributes: nil)
            return messageCachesURL
        } catch let error {
            println("Directory create: \(error)")
        }

        return nil
    }

    // Image

    public class func yepMessageImageURLWithName(_ name: String) -> URL? {

        if let messageCachesURL = yepMessageCachesURL() {
            return messageCachesURL.appendingPathComponent("\(name).\(FileExtension.jpeg.rawValue)")
        }

        return nil
    }

    public class func saveMessageImageData(_ messageImageData: Data, withName name: String) -> URL? {

        if let messageImageURL = yepMessageImageURLWithName(name) {
            if FileManager.default.createFile(atPath: messageImageURL.path, contents: messageImageData, attributes: nil) {
                return messageImageURL
            }
        }

        return nil
    }

    public class func removeMessageImageFileWithName(_ name: String) {

        if name.isEmpty {
            return
        }

        if let messageImageURL = yepMessageImageURLWithName(name) {
            do {
                try FileManager.default.removeItem(at: messageImageURL)
            } catch let error {
                println("File delete: \(error)")
            }
        }
    }

    // Audio

    public class func yepMessageAudioURLWithName(_ name: String) -> URL? {

        if let messageCachesURL = yepMessageCachesURL() {
            return messageCachesURL.appendingPathComponent("\(name).\(FileExtension.m4a.rawValue)")
        }

        return nil
    }

    public class func saveMessageAudioData(_ messageAudioData: Data, withName name: String) -> URL? {

        if let messageAudioURL = yepMessageAudioURLWithName(name) {
            if FileManager.default.createFile(atPath: messageAudioURL.path, contents: messageAudioData, attributes: nil) {
                return messageAudioURL
            }
        }

        return nil
    }

    public class func removeMessageAudioFileWithName(_ name: String) {

        if name.isEmpty {
            return
        }

        if let messageAudioURL = yepMessageAudioURLWithName(name) {
            do {
                try FileManager.default.removeItem(at: messageAudioURL)
            } catch let error {
                println("File delete: \(error)")
            }
        }
    }

    // Video

    public class func yepMessageVideoURLWithName(_ name: String) -> URL? {

        if let messageCachesURL = yepMessageCachesURL() {
            return messageCachesURL.appendingPathComponent("\(name).\(FileExtension.mp4.rawValue)")
        }

        return nil
    }

    public class func saveMessageVideoData(_ messageVideoData: Data, withName name: String) -> URL? {

        if let messageVideoURL = yepMessageVideoURLWithName(name) {
            if FileManager.default.createFile(atPath: messageVideoURL.path, contents: messageVideoData, attributes: nil) {
                return messageVideoURL
            }
        }

        return nil
    }

    public class func removeMessageVideoFilesWithName(_ name: String, thumbnailName: String) {

        if !name.isEmpty {
            if let messageVideoURL = yepMessageVideoURLWithName(name) {
                do {
                    try FileManager.default.removeItem(at: messageVideoURL)
                } catch let error {
                    println("File delete: \(error)")
                }
            }
        }

        if !thumbnailName.isEmpty {
            if let messageImageURL = yepMessageImageURLWithName(thumbnailName) {
                do {
                    try FileManager.default.removeItem(at: messageImageURL)
                } catch let error {
                    println("File delete: \(error)")
                }
            }
        }
    }

    // MARK: Clean Caches

    public class func cleanCachesDirectoryAtURL(_ cachesDirectoryURL: URL) {
        let fileManager = FileManager.default

        if let fileURLs = (try? fileManager.contentsOfDirectory(at: cachesDirectoryURL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions())) {
            for fileURL in fileURLs {
                do {
                    try fileManager.removeItem(at: fileURL)
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

