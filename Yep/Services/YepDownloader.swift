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

        let downloadTask: NSURLSessionDownloadTask

        typealias ReportAction = Double -> Void

        let reportProgressAction: ReportAction?

        let finishedAction: NSData -> Void
    }

    var progressReporters = [ProgressReporter]()

    class func downloadAttachmentsOfMessage(message: Message, reportProgress: ProgressReporter.ReportAction?) {
        downloadAttachmentsOfMessage(message, reportProgress: reportProgress, imageFinished: nil)
    }

    class func downloadAttachmentsOfMessage(message: Message, reportProgress: ProgressReporter.ReportAction?, imageFinished: (UIImage -> Void)?) {

        let messageID = message.messageID
        let mediaType = message.mediaType

        let attachmentURLString = message.attachmentURLString
        let downloadState = message.downloadState

        if downloadState == MessageDownloadState.Downloaded.rawValue {
            reportProgress?(1.0)

            return
        }
        
        if !attachmentURLString.isEmpty, let URL = NSURL(string: attachmentURLString) {

            let downloadTask = sharedDownloader.session.downloadTaskWithURL(URL)

            let progressReporter = ProgressReporter(downloadTask: downloadTask, reportProgressAction: reportProgress) { data in

                let fileName = NSUUID().UUIDString

                dispatch_async(dispatch_get_main_queue()) {

                    let realm = Realm()

                    if let message = messageWithMessageID(messageID, inRealm: realm) {

                        if message.downloadState != MessageDownloadState.Downloaded.rawValue {

                            switch mediaType {

                            case MessageMediaType.Image.rawValue:

                                if let fileURL = NSFileManager.saveMessageImageData(data, withName: fileName) {

                                    self.updateAttachmentOfMessage(message, withAttachmentFileName: fileName, inRealm: realm)

                                    if let image = UIImage(data: data) {
                                        imageFinished?(image)
                                    }
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
            }

            sharedDownloader.progressReporters.append(progressReporter)

            downloadTask.resume()
        }

        if mediaType == MessageMediaType.Video.rawValue {

            let thumbnailURLString = message.thumbnailURLString

            if !thumbnailURLString.isEmpty && message.localThumbnailName.isEmpty, let URL = NSURL(string: thumbnailURLString) {

                let downloadTask = sharedDownloader.session.downloadTaskWithURL(URL, completionHandler: { location, response, error in

                    if let location = location, data = NSData(contentsOfURL: location) {

                        let fileName = NSUUID().UUIDString

                        dispatch_async(dispatch_get_main_queue()) {
                            let realm = Realm()

                            if let message = messageWithMessageID(messageID, inRealm: realm) {

                                if message.localThumbnailName.isEmpty {

                                    if let fileURL = NSFileManager.saveMessageImageData(data, withName: fileName) {

                                        self.updateThumbnailOfMessage(message, withThumbnailFileName: fileName, inRealm: realm)

                                        if let image = UIImage(data: data) {
                                            imageFinished?(image)
                                        }
                                    }
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

extension YepDownloader: NSURLSessionDelegate {

}

extension YepDownloader: NSURLSessionDownloadDelegate {

    private func reportProgress(progress: Double, ofDownloadTask downloadTask: NSURLSessionDownloadTask) {
        progressReporters.filter({ $0.downloadTask == downloadTask }).map({ $0.reportProgressAction?(progress) })
    }

    private func handleData(data: NSData, ofDownloadTask downloadTask: NSURLSessionDownloadTask) {
        progressReporters.filter({ $0.downloadTask == downloadTask }).map({ $0.finishedAction(data) })
    }

    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {

        if let data = NSData(contentsOfURL: location) {
            handleData(data, ofDownloadTask: downloadTask)
        }

        reportProgress(1.0, ofDownloadTask: downloadTask)

        println("didFinishDownloadingToURL \(downloadTask.originalRequest.URL)")
    }

    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {

        let progress: Double = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)

        reportProgress(progress, ofDownloadTask: downloadTask)

        //println("downloadTask progress \(progress)")
    }
}

