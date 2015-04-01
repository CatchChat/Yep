//
//  ImageCache.swift
//  Yep
//
//  Created by NIX on 15/3/31.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Realm

class ImageCache {
    static let sharedInstance = ImageCache()

    var cache = NSCache()

    func imageOfMessage(message: Message, withSize size: CGSize, tailDirection: MessageImageTailDirection, completion: (UIImage) -> ()) {

        let imageKey = "image-\(message.messageID)-\(message.localAttachmentName)-\(message.attachmentURLString)"

        // 先看看缓存
        if let image = cache.objectForKey(imageKey) as? UIImage {
            completion(image)

        } else {

            let fileName = message.localAttachmentName
            let attachmentURLString = message.attachmentURLString

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {

                if !fileName.isEmpty {
                    if
                        let imageFileURL = NSFileManager.yepMessageImageURLWithName(fileName),
                        let image = UIImage(contentsOfFile: imageFileURL.path!) {

                            let messageImage = image.bubbleImageWithTailDirection(tailDirection, size: size)

                            self.cache.setObject(messageImage, forKey: imageKey)
                            
                            completion(messageImage)

                            return
                    }
                }

                // 下载

                if attachmentURLString.isEmpty {
                    completion(UIImage())

                    return
                }

                let url = NSURL(string: attachmentURLString)!

                if let data = NSData(contentsOfURL: url) {
                    let image = UIImage(data: data)!

                    let messageImageName = NSUUID().UUIDString

                    let messageImageURL = NSFileManager.saveMessageImageData(data, withName: messageImageName)

                    dispatch_async(dispatch_get_main_queue()) {
                        let realm = message.realm
                        realm.beginWriteTransaction()
                        message.localAttachmentName = messageImageName
                        realm.commitWriteTransaction()
                    }

                    let messageImage = image.bubbleImageWithTailDirection(tailDirection, size: size)

                    self.cache.setObject(messageImage, forKey: imageKey)
                    
                    completion(messageImage)
                }
            }



        }
    }
}