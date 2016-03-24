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
import Kingfisher

class ImageCache {

    static let sharedInstance = ImageCache()

    let cache = NSCache()
    let cacheQueue = dispatch_queue_create("ImageCacheQueue", DISPATCH_QUEUE_SERIAL)
    let cacheAttachmentQueue = dispatch_queue_create("ImageCacheAttachmentQueue", DISPATCH_QUEUE_SERIAL)
//    let cacheQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)

    class func attachmentOriginKeyWithURLString(URLString: String) -> String {
        return "attachment-0.0-\(URLString)"
    }

    class func attachmentSideLengthKeyWithURLString(URLString: String, sideLength: CGFloat) -> String {
        return "attachment-\(sideLength)-\(URLString)"
    }
    
    func imageOfAttachment(attachment: DiscoveredAttachment, withMinSideLength: CGFloat?, completion: (url: NSURL, image: UIImage?, cacheType: CacheType) -> Void) {

        guard let attachmentURL = NSURL(string: attachment.URLString) else {
            return
        }

        var sideLength: CGFloat = 0

        if let withMinSideLength = withMinSideLength {
            sideLength = withMinSideLength
        }
        
        let attachmentOriginKey = ImageCache.attachmentOriginKeyWithURLString(attachmentURL.absoluteString)

        let attachmentSideLengthKey = ImageCache.attachmentSideLengthKeyWithURLString(attachmentURL.absoluteString, sideLength: sideLength)

        //println("attachmentSideLengthKey: \(attachmentSideLengthKey)")

        let options: KingfisherOptionsInfo = [
            .CallbackDispatchQueue(cacheAttachmentQueue),
            .ScaleFactor(UIScreen.mainScreen().scale),
        ]

        //查找当前 Size 的 Cache

        Kingfisher.ImageCache.defaultCache.retrieveImageForKey(attachmentSideLengthKey, options: options) { (image, type) -> () in

            if let image = image?.decodedImage() {
                dispatch_async(dispatch_get_main_queue()) {
                    completion(url: attachmentURL, image: image, cacheType: type)
                }

            } else {
                
                //查找原图
                
                Kingfisher.ImageCache.defaultCache.retrieveImageForKey(attachmentOriginKey, options: options) { (image, type) -> () in

                    if let image = image {
                        
                        //裁剪并存储
                        var finalImage = image
                        
                        if sideLength != 0 {
                            finalImage = finalImage.scaleToMinSideLength(sideLength)

                            let originalData = UIImageJPEGRepresentation(finalImage, 1.0)
                            //let originalData = UIImagePNGRepresentation(finalImage)
                            Kingfisher.ImageCache.defaultCache.storeImage(finalImage, originalData: originalData, forKey: attachmentSideLengthKey, toDisk: true, completionHandler: { () -> () in
                            })
                        }
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            completion(url: attachmentURL, image: finalImage, cacheType: type)
                        }
                        
                    } else {
                        
                        // 下载
                        
                        ImageDownloader.defaultDownloader.downloadImageWithURL(attachmentURL, options: options, progressBlock: { receivedSize, totalSize  in
                            
                        }, completionHandler: {  image, error , imageURL, originalData in
                            
                            if let image = image {
                                
                                Kingfisher.ImageCache.defaultCache.storeImage(image, originalData: originalData, forKey: attachmentOriginKey, toDisk: true, completionHandler: nil)
                                
                                var storeImage = image
                                
                                if sideLength != 0 {
                                    storeImage = storeImage.scaleToMinSideLength(sideLength)
                                }

                                Kingfisher.ImageCache.defaultCache.storeImage(storeImage,  originalData: UIImageJPEGRepresentation(storeImage, 1.0), forKey: attachmentSideLengthKey, toDisk: true, completionHandler: nil)
                                
                                let finalImage = storeImage.decodedImage()
                                
                                //println("Image Decode size \(storeImage.size)")
                                
                                dispatch_async(dispatch_get_main_queue()) {
                                    completion(url: attachmentURL, image: finalImage, cacheType: .None)
                                }

                            } else {
                                dispatch_async(dispatch_get_main_queue()) {
                                    completion(url: attachmentURL, image: nil, cacheType: .None)
                                }
                            }
                        })
                    }
                }
            }
        }
    }

    func imageOfMessage(message: Message, withSize size: CGSize, tailDirection: MessageImageTailDirection, completion: (loadingProgress: Double, image: UIImage?) -> Void) {

        let imageKey = "image-\(message.messageID)-\(message.localAttachmentName)-\(message.attachmentURLString)"
        // 先看看缓存
        if let image = cache.objectForKey(imageKey) as? UIImage {
            completion(loadingProgress: 1.0, image: image)

        } else {
            let messageID = message.messageID

            var fileName = message.localAttachmentName
            if message.mediaType == MessageMediaType.Video.rawValue {
                fileName = message.localThumbnailName
            }

            var imageURLString = message.attachmentURLString
            if message.mediaType == MessageMediaType.Video.rawValue {
                imageURLString = message.thumbnailURLString
            }
            
            let imageDownloadState = message.downloadState

            let preloadingPropgress: Double = fileName.isEmpty ? 0.01 : 0.5

            // 若可以，先显示 blurredThumbnailImage, Video 仍然需要

            let thumbnailKey = "thumbnail" + imageKey

            if let thumbnail = cache.objectForKey(thumbnailKey) as? UIImage {
                completion(loadingProgress: preloadingPropgress, image: thumbnail)

            } else {
                dispatch_async(self.cacheQueue) {

                    guard let realm = try? Realm() else {
                        return
                    }
                    
                    if let message = messageWithMessageID(messageID, inRealm: realm) {
                        
                        if let blurredThumbnailImage = blurredThumbnailImageOfMessage(message) {
                            let bubbleBlurredThumbnailImage = blurredThumbnailImage.bubbleImageWithTailDirection(tailDirection, size: size).decodedImage()

                            self.cache.setObject(bubbleBlurredThumbnailImage, forKey: thumbnailKey)

                            dispatch_async(dispatch_get_main_queue()) {
                                completion(loadingProgress: preloadingPropgress, image: bubbleBlurredThumbnailImage)
                            }

                        } else {
                            /*
                            // 或放个默认的图片
                            let defaultImage = tailDirection == .Left ? UIImage(named: "left_tail_image_bubble")! : UIImage(named: "right_tail_image_bubble")!

                            dispatch_async(dispatch_get_main_queue()) {
                                completion(loadingProgress: preloadingPropgress, image: defaultImage)
                            }
                            */
                        }
                    }
                }
            }

            dispatch_async(self.cacheQueue) {

                guard let realm = try? Realm() else {
                    return
                }
                
                if imageDownloadState == MessageDownloadState.Downloaded.rawValue {
                
                    if !fileName.isEmpty, let imageFileURL = NSFileManager.yepMessageImageURLWithName(fileName), image = UIImage(contentsOfFile: imageFileURL.path!) {

                        let messageImage = image.bubbleImageWithTailDirection(tailDirection, size: size).decodedImage()
                        
                        self.cache.setObject(messageImage, forKey: imageKey)
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            completion(loadingProgress: 1.0, image: messageImage)
                        }
                        
                        return

                    } else {
                        // 找不到要再给下面的下载机会
                        if let message = messageWithMessageID(messageID, inRealm: realm) {
                            let _ = try? realm.write {
                                message.downloadState = MessageDownloadState.NoDownload.rawValue
                            }
                        }
                    }
                }

                // 下载

                if imageURLString.isEmpty {
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(loadingProgress: 1.0, image: nil)
                    }

                    return
                }

                if let message = messageWithMessageID(messageID, inRealm: realm) {

                    func doDownloadAttachmentsOfMessage(message: Message) {

                        let mediaType = message.mediaType

                        YepDownloader.downloadAttachmentsOfMessage(message, reportProgress: { progress, image in
                            dispatch_async(dispatch_get_main_queue()) {
                                completion(loadingProgress: progress, image: image)
                            }

                        }, imageTransform: { image in
                            return image.bubbleImageWithTailDirection(tailDirection, size: size).decodedImage()

                        }, imageFinished: { image in

                            let messageImage = image.bubbleImageWithTailDirection(tailDirection, size: size).decodedImage()

                            self.cache.setObject(messageImage, forKey: imageKey)

                            dispatch_async(dispatch_get_main_queue()) {
                                if mediaType == MessageMediaType.Image.rawValue {
                                    completion(loadingProgress: 1.0, image: messageImage)
                                    
                                } else { // 视频的封面图片，要保障设置到
                                    completion(loadingProgress: 1.5, image: messageImage)
                                }
                            }
                        })
                    }

                    // 若过期了，刷新后再下载。这里减少一天来判断
                    if message.attachmentExpiresUnixTime < (NSDate().timeIntervalSince1970 + (60 * 60 * 24)) {

                        refreshAttachmentWithID(message.attachmentID, failureHandler: nil, completion: { newAttachmentInfo in
                            //println("newAttachmentInfo: \(newAttachmentInfo)")

                            guard let realm = try? Realm() else {
                                return
                            }

                            if let message = messageWithMessageID(messageID, inRealm: realm) {

                                if let fileInfo = newAttachmentInfo["file"] as? JSONDictionary {

                                    realm.beginWrite()

                                    if let attachmentExpiresUnixTime = fileInfo["expires_at"] as? NSTimeInterval {
                                        message.attachmentExpiresUnixTime = attachmentExpiresUnixTime
                                    }

                                    if let URLString = fileInfo["url"] as? String {
                                        message.attachmentURLString = URLString
                                    }

                                    if let URLString = fileInfo["thumb_url"] as? String {
                                        message.thumbnailURLString = URLString
                                    }

                                    let _ = try? realm.commitWrite()

                                    doDownloadAttachmentsOfMessage(message)
                                }
                            }
                        })

                    } else {
                        doDownloadAttachmentsOfMessage(message)
                    }

                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(loadingProgress: 1.0, image: nil)
                    }
                }
            }
        }
    }

    func mapImageOfMessage(message: Message, withSize size: CGSize, tailDirection: MessageImageTailDirection, bottomShadowEnabled: Bool, completion: (UIImage) -> ()) {

        let imageKey = "mapImage-\(message.messageID)-\(message.coordinate)"

        //println("mapImageOfMessage imageKey: \(imageKey)")

        // 先看看缓存
        if let image = cache.objectForKey(imageKey) as? UIImage {
            completion(image)

        } else {

            if let coordinate = message.coordinate {

                // 先放个默认的图片

                let fileName = message.localAttachmentName

                // 再保证一次，防止旧消息导致错误
                let latitude: CLLocationDegrees = coordinate.safeLatitude
                let longitude: CLLocationDegrees = coordinate.safeLongitude

                dispatch_async(self.cacheQueue) {

                    // 再看看是否已有地图图片文件

                    if !fileName.isEmpty {
                        if
                            let imageFileURL = NSFileManager.yepMessageImageURLWithName(fileName),
                            let image = UIImage(contentsOfFile: imageFileURL.path!) {

                                let mapImage = image.bubbleImageWithTailDirection(tailDirection, size: size, forMap: bottomShadowEnabled).decodedImage()

                                self.cache.setObject(mapImage, forKey: imageKey)

                                dispatch_async(dispatch_get_main_queue()) {
                                    completion(mapImage)
                                }

                                return
                        }
                    }
                    
                    let defaultImage = tailDirection == .Left ? UIImage(named: "left_tail_image_bubble")! : UIImage(named: "right_tail_image_bubble")!
                    completion(defaultImage)    

                    // 没有地图图片文件，只能生成了

                    let options = MKMapSnapshotOptions()
                    options.scale = UIScreen.mainScreen().scale
                    options.size = size

                    let locationCoordinate = CLLocationCoordinate2DMake(latitude, longitude)
                    let mapCoordinate = locationCoordinate
                    options.region = MKCoordinateRegionMakeWithDistance(mapCoordinate, 500, 500)

                    let mapSnapshotter = MKMapSnapshotter(options: options)

                    mapSnapshotter.startWithCompletionHandler { (snapshot, error) -> Void in
                        if error == nil {

                            guard let snapshot = snapshot else {
                                return
                            }

                            let image = snapshot.image
                            
                            UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)

                            let pinImage = UIImage(named: "icon_current_location")!

                            image.drawAtPoint(CGPointZero)

                            let pinCenter = snapshot.pointForCoordinate(mapCoordinate)

                            let xOffset: CGFloat
                            switch tailDirection {
                            case .Left:
                                xOffset = 3
                            case .Right:
                                xOffset = -3
                            }

                            let pinOrigin = CGPoint(x: pinCenter.x - pinImage.size.width * 0.5 + xOffset, y: pinCenter.y - pinImage.size.height * 0.5)
                            pinImage.drawAtPoint(pinOrigin)

                            let finalImage = UIGraphicsGetImageFromCurrentImageContext()

                            UIGraphicsEndImageContext()

                            // save it

                            if let data = UIImageJPEGRepresentation(finalImage, 1.0) {

                                let fileName = NSUUID().UUIDString

                                if let _ = NSFileManager.saveMessageImageData(data, withName: fileName) {

                                    dispatch_async(dispatch_get_main_queue()) {
                                        
                                        if let realm = message.realm {
                                            let _ = try? realm.write {
                                                message.localAttachmentName = fileName
                                            }
                                        }
                                    }
                                }
                            }

                            let mapImage = finalImage.bubbleImageWithTailDirection(tailDirection, size: size, forMap: bottomShadowEnabled).decodedImage()

                            self.cache.setObject(mapImage, forKey: imageKey)

                            dispatch_async(dispatch_get_main_queue()) {
                                completion(mapImage)
                            }
                        }
                    }
                }
            }
        }
    }

    func mapImageOfLocationCoordinate(locationCoordinate: CLLocationCoordinate2D, withSize size: CGSize, completion: (UIImage) -> ()) {

        let imageKey = "feedMapImage-\(size)-\(locationCoordinate)"

        // 先看看缓存
        if let image = cache.objectForKey(imageKey) as? UIImage {
            completion(image)

        } else {
            let options = MKMapSnapshotOptions()
            options.scale = UIScreen.mainScreen().scale
            let size = size
            options.size = size
            options.region = MKCoordinateRegionMakeWithDistance(locationCoordinate, 500, 500)

            let mapSnapshotter = MKMapSnapshotter(options: options)

            mapSnapshotter.startWithQueue(cacheQueue, completionHandler: { snapshot, error in
                if error == nil {

                    guard let snapshot = snapshot else {
                        return
                    }

                    let image = snapshot.image

                    self.cache.setObject(image, forKey: imageKey)

                    dispatch_async(dispatch_get_main_queue()) {
                        completion(image)
                    }
                }
            })
        }
    }
}

