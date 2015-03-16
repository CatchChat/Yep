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

    func roundImage(named name: String, ofRadius radius: CGFloat) -> UIImage {
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

        // default
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
}