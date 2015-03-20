//
//  AvatarCache.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

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
}