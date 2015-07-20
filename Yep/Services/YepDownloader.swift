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

        struct Task {
            let downloadTask: NSURLSessionDownloadTask

            typealias FinishedAction = NSData -> Void
            let finishedAction: FinishedAction

            let progress = NSProgress()
        }
        let tasks: [Task]

        typealias ReportProgress = Double -> Void
        let reportProgress: ReportProgress?
    }

    var progressReporters = [ProgressReporter]()

    class func downloadAttachmentsOfMessage(message: Message, reportProgress: ProgressReporter.ReportProgress?) {
        downloadAttachmentsOfMessage(message, reportProgress: reportProgress, imageFinished: nil)
    }

    class func downloadAttachmentsOfMessage(message: Message, reportProgress: ProgressReporter.ReportProgress?, imageFinished: (UIImage -> Void)?) {

        let downloadState = message.downloadState

        if downloadState == MessageDownloadState.Downloaded.rawValue {
            return
        }

        let messageID = message.messageID
        let mediaType = message.mediaType

        let attachmentURLString = message.attachmentURLString
        
        if !attachmentURLString.isEmpty, let URL = NSURL(string: attachmentURLString) {

            let attachmentDownloadTask = sharedDownloader.session.downloadTaskWithURL(URL)

            var thumbnailDownloadTask: NSURLSessionDownloadTask?
            if mediaType == MessageMediaType.Video.rawValue {
                if let URL = NSURL(string: message.thumbnailURLString) {
                    thumbnailDownloadTask = sharedDownloader.session.downloadTaskWithURL(URL)
                }
            }

            let attachmentFinishedAction: ProgressReporter.Task.FinishedAction = { data in

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

            let thumbnailFinishedAction: ProgressReporter.Task.FinishedAction = { data in

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

            var tasks: [ProgressReporter.Task] = []
            tasks.append(ProgressReporter.Task(downloadTask: attachmentDownloadTask, finishedAction: attachmentFinishedAction))

            if let thumbnailDownloadTask = thumbnailDownloadTask {
                tasks.append(ProgressReporter.Task(downloadTask: thumbnailDownloadTask, finishedAction: thumbnailFinishedAction))
            }

            let progressReporter = ProgressReporter(tasks: tasks, reportProgress: reportProgress)

            sharedDownloader.progressReporters.append(progressReporter)

            tasks.map { $0.downloadTask.resume() }
        }
    }
}

extension YepDownloader: NSURLSessionDelegate {

}

extension YepDownloader: NSURLSessionDownloadDelegate {

    private func handleData(data: NSData, ofDownloadTask downloadTask: NSURLSessionDownloadTask) {

        for progressReporter in progressReporters {

            for i in 0..<progressReporter.tasks.count {
                if downloadTask == progressReporter.tasks[i].downloadTask {
                    let finishedAction = progressReporter.tasks[i].finishedAction
                    finishedAction(data)

                    println("finish data of \(downloadTask)")

                    return
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

            for i in 0..<progressReporter.tasks.count {
                if downloadTask == progressReporter.tasks[i].downloadTask {
                    progressReporter.tasks[i].progress.totalUnitCount = totalBytesExpectedToWrite
                    progressReporter.tasks[i].progress.completedUnitCount = totalBytesWritten

                    let fullProgress: Double = progressReporter.tasks.map({ $0.progress.fractionCompleted }).reduce(0, combine: { $0 + $1 }) / Double(progressReporter.tasks.count)
                    progressReporter.reportProgress?(fullProgress)

                    println("fullProgress: \(fullProgress)")

                    return
                }
            }
        }
    }

}

