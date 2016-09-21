//
//  ImageCache.swift
//  Yep
//
//  Created by NIX on 15/3/31.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift
import YepKit
import YepNetworking
import MapKit
import Kingfisher

final class ImageCache {

    static let sharedInstance = ImageCache()

    let cache = NSCache<NSString, UIImage>()
    let cacheQueue = DispatchQueue(label: "ImageCacheQueue", attributes: [])
    let cacheAttachmentQueue = DispatchQueue(label: "ImageCacheAttachmentQueue", attributes: [])

    class func attachmentOriginKeyWithURLString(_ URLString: String) -> String {
        return "attachment-0.0-\(URLString)"
    }

    class func attachmentSideLengthKeyWithURLString(_ URLString: String, sideLength: CGFloat) -> String {
        return "attachment-\(sideLength)-\(URLString)"
    }

    func imageOfURL(_ url: URL, withMinSideLength: CGFloat?, completion: @escaping (_ url: URL, _ image: UIImage?, _ cacheType: CacheType) -> Void) {

        var sideLength: CGFloat = 0

        if let withMinSideLength = withMinSideLength {
            sideLength = withMinSideLength
        }

        let attachmentOriginKey = ImageCache.attachmentOriginKeyWithURLString(url.absoluteString)

        let attachmentSideLengthKey = ImageCache.attachmentSideLengthKeyWithURLString(url.absoluteString, sideLength: sideLength)

        //println("attachmentSideLengthKey: \(attachmentSideLengthKey)")

        let options: KingfisherOptionsInfo = [
            .callbackDispatchQueue(cacheAttachmentQueue),
            .scaleFactor(UIScreen.main.scale),
        ]

        //查找当前 Size 的 Cache

        Kingfisher.ImageCache.default.retrieveImage(forKey: attachmentSideLengthKey, options: options) { (image, type) -> () in

            if let image = image?.decodedImage() {
                SafeDispatch.async {
                    completion(url, image, type)
                }

            } else {

                //查找原图

                Kingfisher.ImageCache.default.retrieveImage(forKey: attachmentOriginKey, options: options) { (image, type) -> () in

                    if let image = image {

                        //裁剪并存储
                        var finalImage = image

                        if sideLength != 0 {
                            finalImage = finalImage.scaleToMinSideLength(sideLength)

                            let originalData = UIImageJPEGRepresentation(finalImage, 1.0)
                            //let originalData = UIImagePNGRepresentation(finalImage)
                            Kingfisher.ImageCache.default.store(finalImage, originalData: originalData, forKey: attachmentSideLengthKey, toDisk: true, completionHandler: { () -> () in
                            })
                        }

                        SafeDispatch.async {
                            completion(url, finalImage, type)
                        }

                    } else {

                        // 下载

                        ImageDownloader.default.downloadImage(with: url, options: options, progressBlock: { receivedSize, totalSize  in

                        }, completionHandler: { image, error , imageURL, originalData in

                            if let image = image {

                                Kingfisher.ImageCache.defaultCache.storeImage(image, originalData: originalData, forKey: attachmentOriginKey, toDisk: true, completionHandler: nil)

                                var storeImage = image

                                if sideLength != 0 {
                                    storeImage = storeImage.scaleToMinSideLength(sideLength)
                                }

                                Kingfisher.ImageCache.defaultCache.storeImage(storeImage,  originalData: UIImageJPEGRepresentation(storeImage, 1.0), forKey: attachmentSideLengthKey, toDisk: true, completionHandler: nil)

                                let finalImage = storeImage.decodedImage()

                                //println("Image Decode size \(storeImage.size)")

                                SafeDispatch.async {
                                    completion(url: url, image: finalImage, cacheType: .None)
                                }

                            } else {
                                SafeDispatch.async {
                                    completion(url: url, image: nil, cacheType: .None)
                                }
                            }
                        })
                    }
                }
            }
        }
    }

    func imageOfAttachment(_ attachment: DiscoveredAttachment, withMinSideLength: CGFloat?, completion: @escaping (_ url: URL, _ image: UIImage?, _ cacheType: CacheType) -> Void) {

        guard let attachmentURL = URL(string: attachment.URLString) else {
            return
        }

        imageOfURL(attachmentURL, withMinSideLength: withMinSideLength, completion: completion)
    }

    func imageOfMessage(_ message: Message, withSize size: CGSize, tailDirection: MessageImageTailDirection, completion: @escaping (_ loadingProgress: Double, _ image: UIImage?) -> Void) {

        let imageKey = message.imageKey as NSString

        // 先看看缓存
        if let image = cache.object(forKey: imageKey) {
            completion(1.0, image)

        } else {
            let messageID = message.messageID

            var fileName = message.localAttachmentName
            if message.mediaType == MessageMediaType.video.rawValue {
                fileName = message.localThumbnailName
            }

            var imageURLString = message.attachmentURLString
            if message.mediaType == MessageMediaType.video.rawValue {
                imageURLString = message.thumbnailURLString
            }
            
            let imageDownloadState = message.downloadState

            let preloadingPropgress: Double = fileName.isEmpty ? 0.01 : 0.5

            // 若可以，先显示 blurredThumbnailImage, Video 仍然需要

            let thumbnailKey: NSString = "thumbnail_\(imageKey)"

            if let thumbnail = cache.objectForKey(thumbnailKey) {
                completion(loadingProgress: preloadingPropgress, image: thumbnail)

            } else {
                self.cacheQueue.async {

                    guard let realm = try? Realm() else {
                        return
                    }
                    
                    if let message = messageWithMessageID(messageID, inRealm: realm) {
                        
                        if let blurredThumbnailImage = blurredThumbnailImageOfMessage(message) {
                            let bubbleBlurredThumbnailImage = blurredThumbnailImage.bubbleImageWithTailDirection(tailDirection, size: size).decodedImage()

                            self.cache.setObject(bubbleBlurredThumbnailImage, forKey: thumbnailKey)

                            SafeDispatch.async {
                                completion(preloadingPropgress, bubbleBlurredThumbnailImage)
                            }

                        } else {
                            /*
                            // 或放个默认的图片
                            let defaultImage = tailDirection == .Left ? UIImage(named: "left_tail_image_bubble")! : UIImage(named: "right_tail_image_bubble")!

                            SafeDispatch.async {
                                completion(loadingProgress: preloadingPropgress, image: defaultImage)
                            }
                            */
                        }
                    }
                }
            }

            self.cacheQueue.async {

                guard let realm = try? Realm() else {
                    return
                }
                
                if imageDownloadState == MessageDownloadState.downloaded.rawValue {
                
                    if !fileName.isEmpty, let imageFileURL = FileManager.yepMessageImageURLWithName(fileName), let image = UIImage(contentsOfFile: imageFileURL.path) {

                        let messageImage = image.bubbleImageWithTailDirection(tailDirection, size: size).decodedImage()
                        
                        self.cache.setObject(messageImage, forKey: imageKey)
                        
                        SafeDispatch.async {
                            completion(1.0, messageImage)
                        }
                        
                        return

                    } else {
                        // 找不到要再给下面的下载机会
                        if let message = messageWithMessageID(messageID, inRealm: realm) {
                            let _ = try? realm.write {
                                message.downloadState = MessageDownloadState.noDownload.rawValue
                            }
                        }
                    }
                }

                // 下载

                if imageURLString.isEmpty {
                    SafeDispatch.async {
                        completion(1.0, nil)
                    }

                    return
                }

                if let message = messageWithMessageID(messageID, inRealm: realm) {

                    func doDownloadAttachmentsOfMessage(_ message: Message) {

                        let mediaType = message.mediaType

                        YepDownloader.downloadAttachmentsOfMessage(message, reportProgress: { progress, image in
                            SafeDispatch.async {
                                completion(progress, image)
                            }

                        }, imageTransform: { image in
                            return image.bubbleImageWithTailDirection(tailDirection, size: size).decodedImage()

                        }, imageFinished: { image in

                            let messageImage = image.bubbleImageWithTailDirection(tailDirection, size: size).decodedImage()

                            self.cache.setObject(messageImage, forKey: imageKey)

                            SafeDispatch.async {
                                if mediaType == MessageMediaType.image.rawValue {
                                    completion(1.0, messageImage)
                                    
                                } else { // 视频的封面图片，要保障设置到
                                    completion(1.5, messageImage)
                                }
                            }
                        })
                    }

                    // 若过期了，刷新后再下载。这里减少一天来判断
                    if message.attachmentExpiresUnixTime < (Date().timeIntervalSince1970 + (60 * 60 * 24)) {

                        refreshAttachmentWithID(message.attachmentID, failureHandler: nil, completion: { newAttachmentInfo in
                            //println("newAttachmentInfo: \(newAttachmentInfo)")

                            guard let realm = try? Realm() else {
                                return
                            }

                            if let message = messageWithMessageID(messageID, inRealm: realm) {

                                if let fileInfo = newAttachmentInfo["file"] as? JSONDictionary {

                                    realm.beginWrite()

                                    if let attachmentExpiresUnixTime = fileInfo["expires_at"] as? TimeInterval {
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
                    SafeDispatch.async {
                        completion(1.0, nil)
                    }
                }
            }
        }
    }

    func mapImageOfMessage(_ message: Message, withSize size: CGSize, tailDirection: MessageImageTailDirection, bottomShadowEnabled: Bool, completion: @escaping (UIImage) -> ()) {

        let imageKey = "mapImage-\(message.messageID)-\(message.coordinate)" as NSString

        //println("mapImageOfMessage imageKey: \(imageKey)")

        // 先看看缓存
        if let image = cache.object(forKey: imageKey) {
            completion(image)

        } else {

            if let coordinate = message.coordinate {

                // 先放个默认的图片

                let imageFileURL = message.imageFileURL

                // 再保证一次，防止旧消息导致错误
                let latitude: CLLocationDegrees = coordinate.safeLatitude
                let longitude: CLLocationDegrees = coordinate.safeLongitude

                self.cacheQueue.async {

                    // 再看看是否已有地图图片文件

                    if let imageFileURL = imageFileURL, let image = UIImage(contentsOfFile: imageFileURL.path) {
                        let mapImage = image.bubbleImageWithTailDirection(tailDirection, size: size, forMap: bottomShadowEnabled).decodedImage()

                        self.cache.setObject(mapImage, forKey: imageKey)

                        SafeDispatch.async {
                            completion(mapImage)
                        }

                        return
                    }
                    
                    let defaultImage = (tailDirection == .Left) ? UIImage.yep_leftTailImageBubble.resizableImageWithCapInsets(UIEdgeInsets(top: 25, left: 27, bottom: 20, right: 20), resizingMode: .Stretch) : UIImage.yep_rightTailImageBubble.resizableImageWithCapInsets(UIEdgeInsets(top: 24, left: 20, bottom: 20, right: 27), resizingMode: .Stretch)
                    completion(defaultImage)    

                    // 没有地图图片文件，只能生成了

                    let options = MKMapSnapshotOptions()
                    options.scale = UIScreen.main.scale
                    options.size = size

                    let locationCoordinate = CLLocationCoordinate2DMake(latitude, longitude)
                    let mapCoordinate = locationCoordinate
                    options.region = MKCoordinateRegionMakeWithDistance(mapCoordinate, 500, 500)

                    let mapSnapshotter = MKMapSnapshotter(options: options)

                    mapSnapshotter.start (completionHandler: { (snapshot, error) -> Void in
                        if error == nil {

                            guard let snapshot = snapshot else {
                                return
                            }

                            let image = snapshot.image
                            
                            UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)

                            let pinImage = UIImage.yep_iconCurrentLocation

                            image.draw(at: CGPoint.zero)

                            let pinCenter = snapshot.point(for: mapCoordinate)

                            let xOffset: CGFloat
                            switch tailDirection {
                            case .left:
                                xOffset = 3
                            case .right:
                                xOffset = -3
                            }

                            let pinOrigin = CGPoint(x: pinCenter.x - pinImage.size.width * 0.5 + xOffset, y: pinCenter.y - pinImage.size.height * 0.5)
                            pinImage.draw(at: pinOrigin)

                            let finalImage = UIGraphicsGetImageFromCurrentImageContext()!

                            UIGraphicsEndImageContext()

                            // save it

                            if let data = UIImageJPEGRepresentation(finalImage, 1.0) {

                                let fileName = UUID().uuidString

                                if let _ = FileManager.saveMessageImageData(data, withName: fileName) {

                                    SafeDispatch.async {
                                        
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

                            SafeDispatch.async {
                                completion(mapImage)
                            }
                        }
                    })
                }
            }
        }
    }

    func mapImageOfLocationCoordinate(_ locationCoordinate: CLLocationCoordinate2D, withSize size: CGSize, completion: @escaping (UIImage) -> ()) {

        let imageKey: NSString = "feedMapImage-\(size)-\(locationCoordinate)"

        // 先看看缓存
        if let image = cache.object(forKey: imageKey) as? UIImage {
            completion(image)

        } else {
            let options = MKMapSnapshotOptions()
            options.scale = UIScreen.main.scale
            let size = size
            options.size = size
            options.region = MKCoordinateRegionMakeWithDistance(locationCoordinate, 500, 500)

            let mapSnapshotter = MKMapSnapshotter(options: options)

            mapSnapshotter.start(with: cacheQueue, completionHandler: { snapshot, error in
                if error == nil {

                    guard let snapshot = snapshot else {
                        return
                    }

                    let image = snapshot.image.decodedImage()

                    self.cache.setObject(image, forKey: imageKey)

                    SafeDispatch.async {
                        completion(image)
                    }
                }
            })
        }
    }
}

