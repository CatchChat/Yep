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

    func roundImageNamed(name: String, ofRadius radius: CGFloat) -> UIImage {
        let roundImageKey = "\(name)-\(radius)"
        
        if let roundImage = cache.objectForKey(roundImageKey) as? UIImage {
            return roundImage

        } else {
            if let image = UIImage(named: name) {

                let roundImage = image.roundImageOfRadius(radius)

                cache.setObject(roundImage, forKey: roundImageKey)

                return roundImage
            }
        }

        return defaultRoundAvatarOfRadius(radius)
    }

    func defaultRoundAvatarOfRadius(radius: CGFloat) -> UIImage {
        let facelessRouncImageKey = "faceless-\(radius)"

        if let roundImage = cache.objectForKey(facelessRouncImageKey) as? UIImage {
            return roundImage

        } else {
            let image = UIImage(named: "default_avatar")! // NOTICE: we need default_avatar indeed

            let roundImage = image.roundImageOfRadius(radius)

            cache.setObject(roundImage, forKey: facelessRouncImageKey)
            
            return roundImage
        }
    }

    func roundImageFromURL(url: NSURL, ofRadius radius: CGFloat, completion: (UIImage) -> ()) {
        let roundImageKey = "\(url.hashValue)"

        if let roundImage = cache.objectForKey(roundImageKey) as? UIImage {
            completion(roundImage)

        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                if let data = NSData(contentsOfURL: url) {
                    let image = UIImage(data: data)!

                    let roundImage = image.roundImageOfRadius(radius)

                    self.cache.setObject(roundImage, forKey: roundImageKey)

                    completion(roundImage)
                }
            }
        }
    }

    func roundAvatarOfUser(user: User, withRadius radius: CGFloat, completion: (UIImage) -> ()) {

        if user.avatarURLString.isEmpty {
            completion(defaultRoundAvatarOfRadius(radius))

            return
        }

        if let url = NSURL(string: user.avatarURLString) {
            let roundImageKey = "\(url.hashValue)"

            // 先看看缓存
            if let roundImage = cache.objectForKey(roundImageKey) as? UIImage {
                completion(roundImage)

            } else {

                // 再看看是否已下载
                if let avatar = user.avatar {
                    if avatar.avatarURLString == user.avatarURLString {
                        let image = UIImage(data: avatar.imageData)!

                        let roundImage = image.roundImageOfRadius(radius)

                        self.cache.setObject(roundImage, forKey: roundImageKey)

                        completion(roundImage)

                        return

                    } else {
                        // 换了 Avatar，删除旧的 // TODO: need test
                        dispatch_async(dispatch_get_main_queue()) {
                            let realm = RLMRealm.defaultRealm()
                            realm.beginWriteTransaction()

                            let avatar = user.avatar
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

                        let imageData = UIImageJPEGRepresentation(image, 0.8)

                        dispatch_async(dispatch_get_main_queue()) {
                            let realm = RLMRealm.defaultRealm()
                            realm.beginWriteTransaction()

                            let avatar = Avatar()
                            avatar.avatarURLString = user.avatarURLString
                            avatar.imageData = imageData

                            user.avatar = avatar

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


