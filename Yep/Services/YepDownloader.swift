//
//  YepDownloader.swift
//  Yep
//
//  Created by NIX on 15/6/29.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation
import RealmSwift
import ImageIO

class YepDownloader: NSObject {

    static let sharedDownloader = YepDownloader()

    lazy var session: NSURLSession = {
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        return session
    }()

    private class func updateAttachmentOfMessage(message: Message, withAttachmentFileName attachmentFileName: String, inRealm realm: Realm) {

        message.localAttachmentName = attachmentFileName

        if message.mediaType == MessageMediaType.Video.rawValue {
            if !message.localThumbnailName.isEmpty {
                message.downloadState = MessageDownloadState.Downloaded.rawValue
            }

        } else {
            message.downloadState = MessageDownloadState.Downloaded.rawValue
        }
    }

    private class func updateThumbnailOfMessage(message: Message, withThumbnailFileName thumbnailFileName: String, inRealm realm: Realm) {

        message.localThumbnailName = thumbnailFileName

        if message.mediaType == MessageMediaType.Video.rawValue {
            if !message.localAttachmentName.isEmpty {
                message.downloadState = MessageDownloadState.Downloaded.rawValue
            }
        }
    }

    struct ProgressReporter {

        struct Task {
            let downloadTask: NSURLSessionDataTask

            typealias FinishedAction = NSData -> Void
            let finishedAction: FinishedAction

            let progress = NSProgress()
            let tempData = NSMutableData()
            let imageSource = CGImageSourceCreateIncremental(nil)
            let imageTransform: (UIImage -> UIImage)?
        }
        let tasks: [Task]
        var finishedTasksCount = 0

        typealias ReportProgress = (progress: Double, image: UIImage?) -> Void
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
        downloadAttachmentsOfMessage(message, reportProgress: reportProgress, imageTransform: nil, imageFinished: nil)
    }

    class func downloadAttachmentsOfMessage(message: Message, reportProgress: ProgressReporter.ReportProgress?, imageTransform: (UIImage -> UIImage)?, imageFinished: (UIImage -> Void)?) {

        let downloadState = message.downloadState

        if downloadState == MessageDownloadState.Downloaded.rawValue {
            return
        }

        let messageID = message.messageID
        let mediaType = message.mediaType

        var attachmentDownloadTask: NSURLSessionDataTask?
        var attachmentFinishedAction: ProgressReporter.Task.FinishedAction?

        let attachmentURLString = message.attachmentURLString
        
        if !attachmentURLString.isEmpty && message.localAttachmentName.isEmpty, let URL = NSURL(string: attachmentURLString) {

            attachmentDownloadTask = sharedDownloader.session.dataTaskWithURL(URL)

            attachmentFinishedAction = { data in

                dispatch_async(dispatch_get_main_queue()) {

                    guard let realm = try? Realm() else {
                        return
                    }

                    if let message = messageWithMessageID(messageID, inRealm: realm) {

                        if message.localAttachmentName.isEmpty {

                            let fileName = NSUUID().UUIDString

                            realm.beginWrite()

                            switch mediaType {

                            case MessageMediaType.Image.rawValue:

                                if let _ = NSFileManager.saveMessageImageData(data, withName: fileName) {

                                    self.updateAttachmentOfMessage(message, withAttachmentFileName: fileName, inRealm: realm)

                                    if let image = UIImage(data: data) {
                                        imageFinished?(image)
                                    }
                                }

                            case MessageMediaType.Video.rawValue:

                                if let _ = NSFileManager.saveMessageVideoData(data, withName: fileName) {
                                    self.updateAttachmentOfMessage(message, withAttachmentFileName: fileName, inRealm: realm)
                                }

                            case MessageMediaType.Audio.rawValue:

                                if let _ = NSFileManager.saveMessageAudioData(data, withName: fileName) {
                                    self.updateAttachmentOfMessage(message, withAttachmentFileName: fileName, inRealm: realm)
                                }
                                
                            default:
                                break
                            }

                            let _ = try? realm.commitWrite()
                        }
                    }
                }
            }
        }

        var thumbnailDownloadTask: NSURLSessionDataTask?
        var thumbnailFinishedAction: ProgressReporter.Task.FinishedAction?

        if mediaType == MessageMediaType.Video.rawValue {

            let thumbnailURLString = message.thumbnailURLString

            if !thumbnailURLString.isEmpty && message.localThumbnailName.isEmpty, let URL = NSURL(string: thumbnailURLString) {

                thumbnailDownloadTask = sharedDownloader.session.dataTaskWithURL(URL)

                thumbnailFinishedAction = { data in

                    dispatch_async(dispatch_get_main_queue()) {
                        guard let realm = try? Realm() else {
                            return
                        }

                        if let message = messageWithMessageID(messageID, inRealm: realm) {

                            if message.localThumbnailName.isEmpty {

                                let fileName = NSUUID().UUIDString

                                if let _ = NSFileManager.saveMessageImageData(data, withName: fileName) {

                                    realm.beginWrite()
                                    self.updateThumbnailOfMessage(message, withThumbnailFileName: fileName, inRealm: realm)
                                    let _ = try? realm.commitWrite()

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
            tasks.append(ProgressReporter.Task(downloadTask: attachmentDownloadTask, finishedAction: attachmentFinishedAction, imageTransform: imageTransform))
        }

        if let thumbnailDownloadTask = thumbnailDownloadTask, thumbnailFinishedAction = thumbnailFinishedAction {
            tasks.append(ProgressReporter.Task(downloadTask: thumbnailDownloadTask, finishedAction: thumbnailFinishedAction, imageTransform: imageTransform))
        }

        if tasks.count > 0 {

            let progressReporter = ProgressReporter(tasks: tasks, reportProgress: reportProgress)

            sharedDownloader.progressReporters.append(progressReporter)

            tasks.forEach { $0.downloadTask.resume() }

        } else {
            println("Can NOT download attachments of message: \(mediaType), \(messageID)")
        }
    }

    class func downloadDataFromURL(URL: NSURL, reportProgress: ProgressReporter.ReportProgress?, finishedAction: ProgressReporter.Task.FinishedAction) {

        let downloadTask = sharedDownloader.session.dataTaskWithURL(URL)
        let task = ProgressReporter.Task(downloadTask: downloadTask, finishedAction: finishedAction, imageTransform: nil)

        let progressReporter = ProgressReporter(tasks: [task], reportProgress: reportProgress)
        sharedDownloader.progressReporters.append(progressReporter)

        downloadTask.resume()
    }
}

extension YepDownloader: NSURLSessionDelegate {

}

extension YepDownloader: NSURLSessionDataDelegate {

    private func reportProgressAssociatedWithDownloadTask(downloadTask: NSURLSessionDataTask, totalBytes: Int64) {

        for progressReporter in progressReporters {

            for i in 0..<progressReporter.tasks.count {

                if downloadTask == progressReporter.tasks[i].downloadTask {

                    progressReporter.tasks[i].progress.totalUnitCount = totalBytes

                    progressReporter.reportProgress?(progress: progressReporter.totalProgress, image: nil)
                    
                    return
                }
            }
        }
    }

    private func reportProgressAssociatedWithDownloadTask(downloadTask: NSURLSessionDataTask, didReceiveData data: NSData) -> Bool {

        for progressReporter in progressReporters {

            for i in 0..<progressReporter.tasks.count {

                if downloadTask == progressReporter.tasks[i].downloadTask {

                    let didReceiveDataBytes = Int64(data.length)
                    progressReporter.tasks[i].progress.completedUnitCount += didReceiveDataBytes
                    progressReporter.tasks[i].tempData.appendData(data)

                    let progress = progressReporter.tasks[i].progress
                    let final = progress.completedUnitCount == progress.totalUnitCount
                    /*
                    progressReporter.reportProgress?(progress: progressReporter.totalProgress, image: nil)
                    */
                    let imageSource = progressReporter.tasks[i].imageSource
                    let data = progressReporter.tasks[i].tempData

                    CGImageSourceUpdateData(imageSource, data, final)

                    var tranformedImage: UIImage?
                    if let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) {
                        /*
                        let image = UIImage(CGImage: cgImage)
                        if let imageTransform = progressReporter.tasks[i].imageTransform {
                            tranformedImage = imageTransform(image)
                        }
                        */
                        let image = UIImage(CGImage: cgImage.yep_extendedCanvasCGImage)
                        if progressReporter.totalProgress < 1 {
                            let blurPercent = CGFloat(1 - progressReporter.totalProgress)
                            let radius = 5 * blurPercent
                            let iterations = UInt(10 * blurPercent)
                            //println("radius: \(radius), iterations: \(iterations)")
                            if let blurredImage = image.blurredImageWithRadius(radius, iterations: iterations, tintColor: UIColor.clearColor()) {
                                if let imageTransform = progressReporter.tasks[i].imageTransform {
                                    tranformedImage = imageTransform(blurredImage)
                                }
                            }
                        }
                    }

                    progressReporter.reportProgress?(progress: progressReporter.totalProgress, image: tranformedImage)

                    return final
                }
            }
        }

        return false
    }

    private func finishDownloadTask(downloadTask: NSURLSessionDataTask) {

        for i in 0..<progressReporters.count {

            for j in 0..<progressReporters[i].tasks.count {

                if downloadTask == progressReporters[i].tasks[j].downloadTask {

                    let finishedAction = progressReporters[i].tasks[j].finishedAction
                    let data = progressReporters[i].tasks[j].tempData
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

    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        //println("YepDownloader begin, expectedContentLength:\(response.expectedContentLength)")
        reportProgressAssociatedWithDownloadTask(dataTask, totalBytes: response.expectedContentLength)
        completionHandler(.Allow)
    }

    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        //println("YepDownloader data.length: \(data.length)")

        let finish = reportProgressAssociatedWithDownloadTask(dataTask, didReceiveData: data)

        if finish {
            //println("YepDownloader finish")
            finishDownloadTask(dataTask)
        }
    }
}

/*
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

        guard let response = downloadTask.response as? NSHTTPURLResponse else {
            return
        }
        
        // 从 s3 下载附件，状态码以 200 为准（有可能 token 不对，返回数据就不是附件文件，或其它特殊情况）
        
        if response.statusCode == 200 {
            if let data = NSData(contentsOfURL: location) {
                handleData(data, ofDownloadTask: downloadTask)
            }

        } else {
            println("YepDownloader failed to download: \(downloadTask.originalRequest?.URL)")
        }
    }

    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {

        reportProgressAssociatedWithDownloadTask(downloadTask, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }
}
*/
