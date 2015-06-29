//
//  YepDownloader.swift
//  Yep
//
//  Created by NIX on 15/6/29.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation
import RealmSwift

class YepDownloader: NSObject {

    static let sharedDownloader = YepDownloader()

    lazy var session: NSURLSession = {
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        return session
        }()

    class func updateAttachmentOfMessage(message: Message, withAttachmentFileName attachmentFileName: String, inRealm realm: Realm) {
        realm.write {
            message.localAttachmentName = attachmentFileName
            message.downloadState = MessageDownloadState.Downloaded.rawValue
        }
    }

    class func updateThumbnailOfMessage(message: Message, withThumbnailFileName thumbnailFileName: String, inRealm realm: Realm) {
        realm.write {
            message.localThumbnailName = thumbnailFileName
        }
    }

    struct ProgressReporter {

        let name: String

        typealias ReportAction = Double -> Void

        let reportAction: ReportAction
    }

    class func downloadAttachmentsOfMessage(message: Message, reportProgress: ProgressReporter.ReportAction?) {

        let messageID = message.messageID
        let mediaType = message.mediaType

        let attachmentURLString = message.attachmentURLString
        let downloadState = message.downloadState

        if downloadState == MessageDownloadState.Downloaded.rawValue {
            reportProgress?(1.0)
        }
        
        if !attachmentURLString.isEmpty {

            if let URL = NSURL(string: attachmentURLString) {

                let downloadTask = sharedDownloader.session.downloadTaskWithURL(URL, completionHandler: { location, response, error in

                    if let data = NSData(contentsOfURL: location) {

                        reportProgress?(1.0)

                        let fileName = NSUUID().UUIDString

                        dispatch_async(dispatch_get_main_queue()) {
                            let realm = Realm()

                            if let message = messageWithMessageID(messageID, inRealm: realm) {

                                switch mediaType {

                                case MessageMediaType.Image.rawValue:

                                    if let fileURL = NSFileManager.saveMessageImageData(data, withName: fileName) {
                                        self.updateAttachmentOfMessage(message, withAttachmentFileName: fileName, inRealm: realm)
                                    }

                                case MessageMediaType.Video.rawValue:

                                    if let fileURL = NSFileManager.saveMessageVideoData(data, withName: fileName) {
                                        self.updateAttachmentOfMessage(message, withAttachmentFileName: fileName, inRealm: realm)
                                    }

                                case MessageMediaType.Audio.rawValue:
                                    
                                    if let fileURL = NSFileManager.saveMessageAudioData(data, withName: fileName) {
                                        self.updateAttachmentOfMessage(message, withAttachmentFileName: fileName, inRealm: realm)
                                    }

                                default:
                                    break
                                }
                            }
                        }
                    }
                })

                downloadTask.resume()
            }
        }

        if mediaType == MessageMediaType.Video.rawValue {

            let thumbnailURLString = message.thumbnailURLString

            if !thumbnailURLString.isEmpty && message.localThumbnailName.isEmpty {

                if let URL = NSURL(string: thumbnailURLString) {

                    let downloadTask = sharedDownloader.session.downloadTaskWithURL(URL, completionHandler: { location, response, error in

                        if let data = NSData(contentsOfURL: location) {

                            let fileName = NSUUID().UUIDString

                            dispatch_async(dispatch_get_main_queue()) {
                                let realm = Realm()

                                if let message = messageWithMessageID(messageID, inRealm: realm) {
                                    if let fileURL = NSFileManager.saveMessageImageData(data, withName: fileName) {
                                        self.updateThumbnailOfMessage(message, withThumbnailFileName: fileName, inRealm: realm)
                                    }
                                }
                            }
                        }
                    })

                    downloadTask.resume()
                }
            }
        }
    }

}

extension YepDownloader: NSURLSessionDelegate {

}

