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

        let downloadTasks: [NSURLSessionDownloadTask]

        typealias FinishedAction = NSData -> Void
        let finishedActions: [FinishedAction]

        var progress: [NSProgress]

        typealias ReportAction = Double -> Void
        let reportProgressAction: ReportAction?
    }


    var progressReporters = [ProgressReporter]()

    class func downloadAttachmentsOfMessage(message: Message, reportProgress: ProgressReporter.ReportAction?) {
        downloadAttachmentsOfMessage(message, reportProgress: reportProgress, imageFinished: nil)
    }

    class func downloadAttachmentsOfMessage(message: Message, reportProgress: ProgressReporter.ReportAction?, imageFinished: (UIImage -> Void)?) {

        let downloadState = message.downloadState

        if downloadState == MessageDownloadState.Downloaded.rawValue {
            return
        }

        let messageID = message.messageID
        let mediaType = message.mediaType

        let attachmentURLString = message.attachmentURLString
        
        if !attachmentURLString.isEmpty, let URL = NSURL(string: attachmentURLString) {

            let downloadTasks: [NSURLSessionDownloadTask]

            let attachmentDownloadTask = sharedDownloader.session.downloadTaskWithURL(URL)

            var thumbnailDownloadTask: NSURLSessionDownloadTask?
            if mediaType == MessageMediaType.Video.rawValue {
                if let URL = NSURL(string: message.thumbnailURLString) {
                    thumbnailDownloadTask = sharedDownloader.session.downloadTaskWithURL(URL)
                }
            }

            if let thumbnailDownloadTask = thumbnailDownloadTask {
                downloadTasks = [attachmentDownloadTask, thumbnailDownloadTask]
            } else {
                downloadTasks = [attachmentDownloadTask]
            }

            let attachmentFinishedAction: ProgressReporter.FinishedAction = { data in

                dispatch_async(dispatch_get_main_queue()) {

                    let realm = Realm()

                    if let message = messageWithMessageID(messageID, inRealm: realm) {

                        if message.downloadState != MessageDownloadState.Downloaded.rawValue {

                            let fileName = NSUUID().UUIDString

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

            let thumbnailFinishedAction: ProgressReporter.FinishedAction = { data in

                dispatch_async(dispatch_get_main_queue()) {
                    let realm = Realm()

                    if let message = messageWithMessageID(messageID, inRealm: realm) {

                        if message.localThumbnailName.isEmpty {

                            let fileName = NSUUID().UUIDString

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

            var progress = [NSProgress]()
            for _ in downloadTasks {
                progress.append(NSProgress())
            }

            let progressReporter = ProgressReporter(downloadTasks: downloadTasks, finishedActions: [attachmentFinishedAction, thumbnailFinishedAction], progress: progress, reportProgressAction: reportProgress)

            sharedDownloader.progressReporters.append(progressReporter)

            downloadTasks.map { $0.resume() }
        }
    }
}

extension YepDownloader: NSURLSessionDelegate {

}

extension YepDownloader: NSURLSessionDownloadDelegate {

    private func handleData(data: NSData, ofDownloadTask downloadTask: NSURLSessionDownloadTask) {

        for progressReporter in progressReporters {

            for i in 0..<progressReporter.downloadTasks.count {
                if downloadTask == progressReporter.downloadTasks[i] {
                    let finishedAction = progressReporter.finishedActions[i]
                    finishedAction(data)

                    println("finish data of \(downloadTask)")

                    break
                }
            }
        }
    }

    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {

        if let data = NSData(contentsOfURL: location) {
            handleData(data, ofDownloadTask: downloadTask)
        }

        println("didFinishDownloadingToURL \(downloadTask.originalRequest.URL)")
    }

    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {

        for progressReporter in progressReporters {

            for i in 0..<progressReporter.downloadTasks.count {
                if downloadTask == progressReporter.downloadTasks[i] {
                    progressReporter.progress[i].totalUnitCount = totalBytesExpectedToWrite
                    progressReporter.progress[i].completedUnitCount = totalBytesWritten

                    let fullProgress: Double = progressReporter.progress.map({ $0.fractionCompleted }).reduce(0, combine: { $0 + $1 }) / Double(progressReporter.progress.count)
                    progressReporter.reportProgressAction?(fullProgress)

                    println("fullProgress: \(fullProgress)")

                    break
                }
            }
        }
    }

}

