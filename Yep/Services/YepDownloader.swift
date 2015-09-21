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
        let _ = try? realm.write {
            message.localAttachmentName = attachmentFileName

            if message.mediaType == MessageMediaType.Video.rawValue {
                if !message.localThumbnailName.isEmpty {
                    message.downloadState = MessageDownloadState.Downloaded.rawValue
                }

            } else {
                message.downloadState = MessageDownloadState.Downloaded.rawValue
            }
        }
    }

    class func updateThumbnailOfMessage(message: Message, withThumbnailFileName thumbnailFileName: String, inRealm realm: Realm) {
        let _ = try? realm.write {
            message.localThumbnailName = thumbnailFileName

            if message.mediaType == MessageMediaType.Video.rawValue {
                if !message.localAttachmentName.isEmpty {
                    message.downloadState = MessageDownloadState.Downloaded.rawValue
                }
            }
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
        var finishedTasksCount = 0

        typealias ReportProgress = Double -> Void
        let reportProgress: ReportProgress?

        init(tasks: [Task], reportProgress: ReportProgress?) {
            self.tasks = tasks
            self.reportProgress = reportProgress
        }

        var totalProgress: Double {

            let completedUnitCount = tasks.map({ $0.progress.completedUnitCount }).reduce(0, combine: +)
            let totalUnitCount = tasks.map({ $0.progress.totalUnitCount }).reduce(0, combine: +)

            return Double(completedUnitCount) / Double(totalUnitCount)
        }
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

        var attachmentDownloadTask: NSURLSessionDownloadTask?
        var attachmentFinishedAction: ProgressReporter.Task.FinishedAction?

        let attachmentURLString = message.attachmentURLString
        
        if !attachmentURLString.isEmpty && message.localAttachmentName.isEmpty, let URL = NSURL(string: attachmentURLString) {

            attachmentDownloadTask = sharedDownloader.session.downloadTaskWithURL(URL)

            attachmentFinishedAction = { data in

                dispatch_async(dispatch_get_main_queue()) {

                    guard let realm = try? Realm() else {
                        return
                    }

                    if let message = messageWithMessageID(messageID, inRealm: realm) {

                        if message.localAttachmentName.isEmpty {

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
        }

        var thumbnailDownloadTask: NSURLSessionDownloadTask?
        var thumbnailFinishedAction: ProgressReporter.Task.FinishedAction?

        if mediaType == MessageMediaType.Video.rawValue {

            let thumbnailURLString = message.thumbnailURLString

            if !thumbnailURLString.isEmpty && message.localThumbnailName.isEmpty, let URL = NSURL(string: thumbnailURLString) {

                thumbnailDownloadTask = sharedDownloader.session.downloadTaskWithURL(URL)

                thumbnailFinishedAction = { data in

                    dispatch_async(dispatch_get_main_queue()) {
                        guard let realm = try? Realm() else {
                            return
                        }

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
            }
        }

        var tasks: [ProgressReporter.Task] = []

        if let attachmentDownloadTask = attachmentDownloadTask, attachmentFinishedAction = attachmentFinishedAction {
            tasks.append(ProgressReporter.Task(downloadTask: attachmentDownloadTask, finishedAction: attachmentFinishedAction))
        }

        if let thumbnailDownloadTask = thumbnailDownloadTask, thumbnailFinishedAction = thumbnailFinishedAction {
            tasks.append(ProgressReporter.Task(downloadTask: thumbnailDownloadTask, finishedAction: thumbnailFinishedAction))
        }

        if tasks.count > 0 {

            let progressReporter = ProgressReporter(tasks: tasks, reportProgress: reportProgress)

            sharedDownloader.progressReporters.append(progressReporter)

            tasks.map { $0.downloadTask.resume() }

        } else {
            print("Can NOT download attachments of message: \(mediaType), \(messageID)")
        }
    }
}

extension YepDownloader: NSURLSessionDelegate {

}

extension YepDownloader: NSURLSessionDownloadDelegate {

    private func handleData(data: NSData, ofDownloadTask downloadTask: NSURLSessionDownloadTask) {

        for i in 0..<progressReporters.count {

            for j in 0..<progressReporters[i].tasks.count {

                if downloadTask == progressReporters[i].tasks[j].downloadTask {

                    let finishedAction = progressReporters[i].tasks[j].finishedAction
                    finishedAction(data)

                    progressReporters[i].finishedTasksCount++

                    // 若任务都已完成，移除此 progressReporter
                    if progressReporters[i].finishedTasksCount == progressReporters[i].tasks.count {
                        progressReporters.removeAtIndex(i)
                    }
                    
                    return
                }
            }
        }
    }

    private func reportProgressAssociatedWithDownloadTask(downloadTask: NSURLSessionDownloadTask, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {

        for progressReporter in progressReporters {

            for i in 0..<progressReporter.tasks.count {

                if downloadTask == progressReporter.tasks[i].downloadTask {

                    progressReporter.tasks[i].progress.totalUnitCount = totalBytesExpectedToWrite
                    progressReporter.tasks[i].progress.completedUnitCount = totalBytesWritten

                    progressReporter.reportProgress?(progressReporter.totalProgress)

                    return
                }
            }
        }
    }

    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {

        if let data = NSData(contentsOfURL: location) {
            handleData(data, ofDownloadTask: downloadTask)
        }
    }

    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {

        reportProgressAssociatedWithDownloadTask(downloadTask, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }
}

