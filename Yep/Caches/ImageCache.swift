//
//  ImageCache.swift
//  Yep
//
//  Created by NIX on 15/3/31.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift
import MapKit

class ImageCache {
    static let sharedInstance = ImageCache()

    let cache = NSCache()

    func imageOfMessage(message: Message, withSize size: CGSize, tailDirection: MessageImageTailDirection, completion: (loadingProgress: Double, image: UIImage?) -> Void) {

        let imageKey = "image-\(message.messageID)-\(message.localAttachmentName)-\(message.attachmentURLString)"

        // 先看看缓存
        if let image = cache.objectForKey(imageKey) as? UIImage {
            completion(loadingProgress: 1.0, image: image)

        } else {
            let messageID = message.messageID

            // 若可以，先显示 blurredThumbnailImage

            let thumbnailKey = "thumbnail" + imageKey

            if let thumbnail = cache.objectForKey(thumbnailKey) as? UIImage {
                completion(loadingProgress: 0.5, image: thumbnail)

            } else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                    if let message = messageWithMessageID(messageID, inRealm: Realm()) {
                        if let blurredThumbnailImage = blurredThumbnailImageOfMessage(message) {
                            let bubbleBlurredThumbnailImage = blurredThumbnailImage.bubbleImageWithTailDirection(tailDirection, size: size)

                            self.cache.setObject(bubbleBlurredThumbnailImage, forKey: thumbnailKey)

                            dispatch_async(dispatch_get_main_queue()) {
                                completion(loadingProgress: 0.5, image: bubbleBlurredThumbnailImage)
                            }

                        } else {
                            // 或放个默认的图片
                            let defaultImage = tailDirection == .Left ? UIImage(named: "left_tail_image_bubble")! : UIImage(named: "right_tail_image_bubble")!
                            dispatch_async(dispatch_get_main_queue()) {
                                completion(loadingProgress: 0.5, image: defaultImage)
                            }
                        }
                    }
                }
            }

            var fileName = message.localAttachmentName
            if message.mediaType == MessageMediaType.Video.rawValue {
                fileName = message.localThumbnailName
            }

            var imageURLString = message.attachmentURLString
            if message.mediaType == MessageMediaType.Video.rawValue {
                imageURLString = message.thumbnailURLString
            }

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {

                if !fileName.isEmpty {
                    if
                        let imageFileURL = NSFileManager.yepMessageImageURLWithName(fileName),
                        let image = UIImage(contentsOfFile: imageFileURL.path!) {

                            let messageImage = image.bubbleImageWithTailDirection(tailDirection, size: size)

                            self.cache.setObject(messageImage, forKey: imageKey)
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                completion(loadingProgress: 1.0, image: messageImage)
                            }

                            return
                    }
                }

                // 下载

                if imageURLString.isEmpty {
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(loadingProgress: 1.0, image: nil)
                    }

                    return
                }

                if let message = messageWithMessageID(messageID, inRealm: Realm()) {

                    YepDownloader.downloadAttachmentsOfMessage(message, reportProgress: { progress in
                        dispatch_async(dispatch_get_main_queue()) {
                            if progress < 1.0 {
                                completion(loadingProgress: progress, image: nil)
                            }
                        }

                    }, imageFinished: { image in

                        let messageImage = image.bubbleImageWithTailDirection(tailDirection, size: size)

                        self.cache.setObject(messageImage, forKey: imageKey)

                        dispatch_async(dispatch_get_main_queue()) {
                            completion(loadingProgress: 1.0, image: messageImage)
                        }
                    })

                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(loadingProgress: 1.0, image: nil)
                    }
                }
            }
        }
    }

    func mapImageOfMessage(message: Message, withSize size: CGSize, tailDirection: MessageImageTailDirection, completion: (UIImage) -> ()) {
        let imageKey = "mapImage-\(message.coordinate)"

        // 先看看缓存
        if let image = cache.objectForKey(imageKey) as? UIImage {
            completion(image)

        } else {

            if let coordinate = message.coordinate {
                let options = MKMapSnapshotOptions()
                options.scale = UIScreen.mainScreen().scale
                options.size = size

                let locationCoordinate = CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude)
                options.region = MKCoordinateRegionMakeWithDistance(locationCoordinate, 500, 500)

                let mapSnapshotter = MKMapSnapshotter(options: options)

                // 先放个默认的图片
                let defaultImage = tailDirection == .Left ? UIImage(named: "left_tail_image_bubble")! : UIImage(named: "right_tail_image_bubble")!
                completion(defaultImage)
                
                mapSnapshotter.startWithCompletionHandler { (snapshot, error) -> Void in
                    if error == nil {

                        let image = snapshot.image

                        UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)

                        let pinImage = UIImage(named: "icon_current_location")!

                        image.drawAtPoint(CGPointZero)

                        let pinCenter = snapshot.pointForCoordinate(locationCoordinate)
                        let pinOrigin = CGPoint(x: pinCenter.x - pinImage.size.width * 0.5, y: pinCenter.y - pinImage.size.height * 0.5)
                        pinImage.drawAtPoint(pinOrigin)

                        let finalImage = UIGraphicsGetImageFromCurrentImageContext()

                        UIGraphicsEndImageContext()

                        let mapImage = finalImage.bubbleImageWithTailDirection(tailDirection, size: size)

                        self.cache.setObject(mapImage, forKey: imageKey)

                        completion(mapImage)
                    }
                }
            }
        }
    }
}