//
//  ImageCache.swift
//  Yep
//
//  Created by NIX on 15/3/31.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit


class ImageCache {
    static let sharedInstance = ImageCache()

    var cache = NSCache()

    func rightMessageImageOfFileName(fileName: String, completion: (UIImage) -> ()) {
        if fileName.isEmpty {
            completion(UIImage())

            return
        }

        let imageKey = "image-\(fileName)"

        // 先看看缓存
        if let image = cache.objectForKey(imageKey) as? UIImage {
            completion(image)

        } else {
            if
                let imageFileURL = NSFileManager.yepMessageImageURLWithName(fileName),
                let image = UIImage(contentsOfFile: imageFileURL.path!) {

                    let rightMessageImage = image.bubbleImageWithTailDirection(.Right, size: CGSize(width: 200, height: 150))
                    
                    self.cache.setObject(rightMessageImage, forKey: imageKey)

                    completion(rightMessageImage)

            } else {
                // TODO: 下载
            }
        }
    }
}