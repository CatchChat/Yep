//
//  AvatarCache.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Realm

class AvatarCache {
    static let sharedInstance = AvatarCache()

    var cache = NSCache()

//    func roundImageNamed(name: String, ofRadius radius: CGFloat) -> UIImage {
//        let roundImageKey = "round-\(name)-\(radius)"
//        
//        if let roundImage = cache.objectForKey(roundImageKey) as? UIImage {
//            return roundImage
//
//        } else {
//            if let image = UIImage(named: name) {
//
//                let roundImage = image.roundImageOfRadius(radius)
//
//                cache.setObject(roundImage, forKey: roundImageKey)
//
//                return roundImage
//            }
//        }
//
//        return defaultRoundAvatarOfRadius(radius)
//    }

    func defaultRoundAvatarOfRadius(radius: CGFloat) -> UIImage {
        let facelessRouncImageKey = "round-faceless-\(radius)"

        if let roundImage = cache.objectForKey(facelessRouncImageKey) as? UIImage {
            return roundImage

        } else {
            let image = UIImage(named: "default_avatar")! // NOTICE: we need default_avatar indeed

            let roundImage = image.roundImageOfRadius(radius)

            cache.setObject(roundImage, forKey: facelessRouncImageKey)
            
            return roundImage
        }
    }

//    func roundImageFromURL(url: NSURL, ofRadius radius: CGFloat, completion: (UIImage) -> ()) {
//        let roundImageKey = "round-\(url.hashValue)"
//
//        if let roundImage = cache.objectForKey(roundImageKey) as? UIImage {
//            completion(roundImage)
//
//        } else {
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
//                if let data = NSData(contentsOfURL: url) {
//                    let image = UIImage(data: data)!
//
//                    let roundImage = image.roundImageOfRadius(radius)
//
//                    self.cache.setObject(roundImage, forKey: roundImageKey)
//
//                    completion(roundImage)
//                }
//            }
//        }
//    }

    func avatarFromURL(url: NSURL, completion: (UIImage) -> ()) {
        let normalImageKey = "normal-\(url.hashValue)"

        let avatarURLString = url.absoluteString!

        // 先看看缓存
        if let normalImage = cache.objectForKey(normalImageKey) as? UIImage {
            completion(normalImage)

        } else {
            if
                let avatar = avatarWithAvatarURLString(avatarURLString),
                let avatarFileURL = NSFileManager.yepAvatarURLWithName(avatar.avatarFileName),
                let image = UIImage(contentsOfFile: avatarFileURL.path!) {

                    self.cache.setObject(image, forKey: normalImageKey)

                    completion(image)

            } else {
                // 没办法，下载吧
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    if let data = NSData(contentsOfURL: url) {
                        let image = UIImage(data: data)!

                        // TODO 裁减 image

                        dispatch_async(dispatch_get_main_queue()) {

                            var avatar = avatarWithAvatarURLString(avatarURLString)

                            if avatar == nil {
                                
                                let avatarFileName = NSUUID().UUIDString

                                if let avatarURL = NSFileManager.saveAvatarImage(image, withName: avatarFileName) {
                                    let realm = RLMRealm.defaultRealm()

                                    realm.beginWriteTransaction()

                                    let newAvatar = Avatar()
                                    newAvatar.avatarURLString = avatarURLString
                                    newAvatar.avatarFileName = avatarFileName

                                    realm.addObject(newAvatar)
                                    
                                    realm.commitWriteTransaction()
                                }
                            }
                        }
                        
                        self.cache.setObject(image, forKey: normalImageKey)
                        
                        completion(image)

                    } else {
                        completion(UIImage(named: "default_avatar")!)
                    }
                }
            }
        }
    }

    func roundAvatarWithAvatarURLString(avatarURLString: String, withRadius radius: CGFloat, completion: (UIImage) -> ()) {
        if avatarURLString.isEmpty {
            completion(defaultRoundAvatarOfRadius(radius))

            return
        }

        if let url = NSURL(string: avatarURLString) {
            let roundImageKey = "round-\(url.hashValue)"

            // 先看看缓存
            if let roundImage = cache.objectForKey(roundImageKey) as? UIImage {
                completion(roundImage)

            } else {
                // 再看看是否已下载
                if let avatar = avatarWithAvatarURLString(avatarURLString) {

                    if
                        let avatarFileURL = NSFileManager.yepAvatarURLWithName(avatar.avatarFileName),
                        let image = UIImage(contentsOfFile: avatarFileURL.path!) {
                        let roundImage = image.roundImageOfRadius(radius)

                        self.cache.setObject(roundImage, forKey: roundImageKey)

                        completion(roundImage)

                        return
                    }
                }

                // 没办法，下载吧
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    if let data = NSData(contentsOfURL: url) {
                        let image = UIImage(data: data)!

                        // TODO 裁减 image

                        dispatch_async(dispatch_get_main_queue()) {
                            let realm = RLMRealm.defaultRealm()

                            realm.beginWriteTransaction()

                            var avatar = avatarWithAvatarURLString(avatarURLString)

                            if avatar == nil {
                                let avatarFileName = NSUUID().UUIDString

                                if let avatarURL = NSFileManager.saveAvatarImage(image, withName: avatarFileName) {
                                    let newAvatar = Avatar()
                                    newAvatar.avatarURLString = avatarURLString
                                    newAvatar.avatarFileName = avatarFileName

                                    realm.addObject(newAvatar)
                                }
                            }
                            
                            realm.commitWriteTransaction()
                        }

                        let roundImage = image.roundImageOfRadius(radius)
                        
                        self.cache.setObject(roundImage, forKey: roundImageKey)
                        
                        completion(roundImage)
                    }
                }
            }
            
        } else {
            completion(defaultRoundAvatarOfRadius(radius))
        }

    }

    func roundAvatarOfUser(user: User, withRadius radius: CGFloat, completion: (UIImage) -> ()) {

        if user.avatarURLString.isEmpty {
            completion(defaultRoundAvatarOfRadius(radius))

            return
        }

        if let url = NSURL(string: user.avatarURLString) {
            let roundImageKey = "round-\(url.hashValue)"

            // 先看看缓存
            if let roundImage = cache.objectForKey(roundImageKey) as? UIImage {
                completion(roundImage)

            } else {

                // 再看看是否已下载
                if let avatar = user.avatar {
                    if avatar.avatarURLString == user.avatarURLString {

                        if
                            let avatarFileURL = NSFileManager.yepAvatarURLWithName(avatar.avatarFileName),
                            let image = UIImage(contentsOfFile: avatarFileURL.path!) {
                            let roundImage = image.roundImageOfRadius(radius)

                            self.cache.setObject(roundImage, forKey: roundImageKey)

                            completion(roundImage)

                            return
                        }

                    } else {
                        // 换了 Avatar，删除旧的 // TODO: need test
                        dispatch_async(dispatch_get_main_queue()) {
                            let realm = RLMRealm.defaultRealm()

                            realm.beginWriteTransaction()

                            // 不能直接使用 user.avatar, 因为 realm 不同
                            let avatar = avatarWithAvatarURLString(user.avatar!.avatarURLString)
                            realm.deleteObject(avatar)

                            realm.commitWriteTransaction()
                        }
                    }
                }

                // 没办法，下载吧
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    if let data = NSData(contentsOfURL: url) {
                        let image = UIImage(data: data)!

                        // TODO 裁减 image

                        dispatch_async(dispatch_get_main_queue()) {
                            let realm = RLMRealm.defaultRealm()

                            realm.beginWriteTransaction()

                            var avatar = avatarWithAvatarURLString(user.avatarURLString)

                            if avatar == nil {
                                let avatarFileName = NSUUID().UUIDString
                                if let avatarURL = NSFileManager.saveAvatarImage(image, withName: avatarFileName) {
                                    let newAvatar = Avatar()
                                    newAvatar.avatarURLString = user.avatarURLString
                                    newAvatar.avatarFileName = avatarFileName

                                    realm.addObject(newAvatar)

                                    avatar = newAvatar
                                }
                            }
                            
                            if let avatar = avatar {
                                user.avatar = avatar
                            }
                            
                            realm.commitWriteTransaction()
                        }

                        let roundImage = image.roundImageOfRadius(radius)

                        self.cache.setObject(roundImage, forKey: roundImageKey)

                        completion(roundImage)
                    }
                }
            }

        } else {
            completion(defaultRoundAvatarOfRadius(radius))
        }
    }

}



