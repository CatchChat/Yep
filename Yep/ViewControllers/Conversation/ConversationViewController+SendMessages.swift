//
//  ConversationViewController+SendMessages.swift
//  Yep
//
//  Created by NIX on 16/6/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import AVFoundation
import YepKit

// MARK: Text

extension ConversationViewController {

    func sendText(_ text: String) {

        guard !text.isEmpty else {
            return
        }

        guard let recipient = self.recipient else {
            return
        }

        println("try sendText to recipient: \(recipient)")

        YepKit.sendText(text, toRecipient: recipient, afterCreatedMessage: { [weak self] message in

            self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true)

        }, failureHandler: { [weak self] reason, errorMessage in

            switch recipient.type {
            case .oneToOne:
                self?.promptSendMessageFailed(
                    reason: reason,
                    errorMessage: errorMessage,
                    reserveErrorMessage: String.trans_promptSendTextFailed
                )
            case .group:
                YepAlert.alertSorry(message: String.trans_promptSendTextFailed, inViewController: self)
            }

        }, completion: { [weak self] success in
            println("sendText: \(success)")

            switch recipient.type {
            case .oneToOne:
                self?.showFriendRequestViewIfNeed()
            case .group:
                self?.updateGroupToIncludeMe()
            }
        })

        if needDetectMention {
            mentionView.hide()
        }
    }
}

// MARK: Audio

extension ConversationViewController {

    func sendAudio(at fileURL: URL, with compressedDecibelSamples: [Float]) {

        guard let recipient = self.recipient else {
            return
        }
        println("try sendAudioWithURL to recipient: \(recipient)")

        // Prepare meta data

        var metaData: String? = nil

        var audioSamples = compressedDecibelSamples
        // 浮点数最多两位小数，使下面计算 metaData 时不至于太长
        for i in 0..<audioSamples.count {
            var sample = audioSamples[i]
            sample = round(sample * 100.0) / 100.0
            audioSamples[i] = sample
        }

        let audioAsset = AVURLAsset(url: fileURL, options: nil)
        let audioDuration = CMTimeGetSeconds(audioAsset.duration) as Double

        println("audioSamples: \(audioSamples)")

        let audioMetaDataInfo: [String: Any] = [
            Config.MetaData.audioDuration: audioDuration,
            Config.MetaData.audioSamples: audioSamples,
        ]

        if let audioMetaData = try? JSONSerialization.data(withJSONObject: audioMetaDataInfo, options: []) {
            let audioMetaDataString = String(data: audioMetaData, encoding: .utf8)
            metaData = audioMetaDataString
        }

        // Do send

        sendAudioInFilePath(fileURL.path, orFileData: nil, metaData: metaData, toRecipient: recipient, afterCreatedMessage: { [weak self] message in

            let audioFileName = NSUUID().uuidString
            if let audioURL = FileManager.yepMessageAudioURLWithName(audioFileName) {
                do {
                    try FileManager.default.copyItem(at: fileURL, to: audioURL)

                    if let realm = message.realm {
                        let _ = try? realm.write {
                            message.localAttachmentName = audioFileName
                            message.mediaType = MessageMediaType.audio.rawValue
                            if let metaDataString = metaData {
                                message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                            }
                        }
                    }

                } catch let error {
                    println(error)
                }
            }

            self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true)

        }, failureHandler: { [weak self] reason, errorMessage in

            switch recipient.type {
            case .oneToOne:
                self?.promptSendMessageFailed(
                    reason: reason,
                    errorMessage: errorMessage,
                    reserveErrorMessage: String.trans_promptSendAudioFailed
                )
            case .group:
                YepAlert.alertSorry(message: String.trans_promptSendAudioFailed, inViewController: self)
            }

        }, completion: { [weak self] success in
            println("sendAudio: \(success)")

            switch recipient.type {
            case .oneToOne:
                self?.showFriendRequestViewIfNeed()
            case .group:
                self?.updateGroupToIncludeMe()
            }
        })
    }
}

// MARK: Image

extension ConversationViewController {

    func sendImage(_ image: UIImage) {

        guard let recipient = self.recipient else {
            return
        }

        println("try sendImage to recipient: \(recipient)")

        // Prepare meta data

        let metaDataString = metaDataStringOfImage(image, needBlurThumbnail: true)

        // Do send

        let imageData = UIImageJPEGRepresentation(image, YepConfig.messageImageCompressionQuality())!

        sendImageInFilePath(nil, orFileData: imageData, metaData: metaDataString, toRecipient: recipient, afterCreatedMessage: { [weak self] message in

            let messageImageName = NSUUID().uuidString

            if let _ = FileManager.saveMessageImageData(imageData, withName: messageImageName) {
                if let realm = message.realm {
                    let _ = try? realm.write {
                        message.localAttachmentName = messageImageName
                        message.mediaType = MessageMediaType.image.rawValue
                        if let metaDataString = metaDataString {
                            message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                        }
                    }
                }

            } else {
                self?.alertSaveFileFailed()
            }

            self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true)

        }, failureHandler: { [weak self] reason, errorMessage in

            switch recipient.type {
            case .oneToOne:
                self?.promptSendMessageFailed(
                    reason: reason,
                    errorMessage: errorMessage,
                    reserveErrorMessage: String.trans_promptSendImageFailed
                )
            case .group:
                YepAlert.alertSorry(message: String.trans_promptSendImageFailed, inViewController: self)
            }

        }, completion: { [weak self] success in
            println("sendImage: \(success)")

            switch recipient.type {
            case .oneToOne:
                self?.showFriendRequestViewIfNeed()
            case .group:
                self?.updateGroupToIncludeMe()
            }
        })
    }
}

// MARK: Video

extension ConversationViewController {

    func sendVideo(at videoURL: URL) {

        guard let recipient = self.recipient else {
            return
        }
        println("try sendVideoWithVideoURL to recipient: \(recipient)")

        // Prepare meta data

        var metaData: String? = nil

        var thumbnailData: Data?

        if let image = thumbnailImageOfVideoInVideoURL(videoURL) {

            let imageWidth = image.size.width
            let imageHeight = image.size.height

            let thumbnailWidth: CGFloat
            let thumbnailHeight: CGFloat

            if imageWidth > imageHeight {
                thumbnailWidth = min(imageWidth, Config.MetaData.thumbnailMaxSize)
                thumbnailHeight = imageHeight * (thumbnailWidth / imageWidth)
            } else {
                thumbnailHeight = min(imageHeight, Config.MetaData.thumbnailMaxSize)
                thumbnailWidth = imageWidth * (thumbnailHeight / imageHeight)
            }

            let videoMetaDataInfo: [String: Any]

            let thumbnailSize = CGSize(width: thumbnailWidth, height: thumbnailHeight)

            if let thumbnail = image.resizeToSize(thumbnailSize, withInterpolationQuality: .low),
                let blurredThumbnail = thumbnail.blurredImage(withRadius: 5, iterations: 7, tintColor: UIColor.clear) {

                let data = UIImageJPEGRepresentation(blurredThumbnail, 0.7)!

                let string = data.base64EncodedString(options: [])

                println("video blurredThumbnail string length: \(string.lengthOfBytes(using: .utf8))\n")

                videoMetaDataInfo = [
                    Config.MetaData.videoWidth: imageWidth,
                    Config.MetaData.videoHeight: imageHeight,
                    Config.MetaData.blurredThumbnailString: string,
                ]

            } else {
                videoMetaDataInfo = [
                    Config.MetaData.videoWidth: imageWidth,
                    Config.MetaData.videoHeight: imageHeight,
                ]
            }

            if let videoMetaData = try? JSONSerialization.data(withJSONObject: videoMetaDataInfo, options: []) {
                let videoMetaDataString = NSString(data: videoMetaData, encoding: String.Encoding.utf8.rawValue) as? String
                metaData = videoMetaDataString
            }

            thumbnailData = UIImageJPEGRepresentation(image, YepConfig.messageImageCompressionQuality())
        }

        let afterCreatedMessageAction = { [weak self] (message: Message) in

            guard let videoData = try? Data(contentsOf: videoURL) else {
                return
            }

            let messageVideoName = NSUUID().uuidString

            if let _ = FileManager.saveMessageVideoData(videoData, withName: messageVideoName) {
                if let realm = message.realm {
                    let _ = try? realm.write {

                        if let thumbnailData = thumbnailData {
                            if let _ = FileManager.saveMessageImageData(thumbnailData, withName: messageVideoName) {
                                message.localThumbnailName = messageVideoName

                            } else {
                                self?.alertSaveFileFailed()
                            }
                        }

                        message.localAttachmentName = messageVideoName

                        message.mediaType = MessageMediaType.video.rawValue
                        if let metaDataString = metaData {
                            message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                        }
                    }
                }

            } else {
                self?.alertSaveFileFailed()
            }

            self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true)
        }

        sendVideoInFilePath(videoURL.path, orFileData: nil, metaData: metaData, toRecipient: recipient, afterCreatedMessage: afterCreatedMessageAction, failureHandler: { [weak self] reason, errorMessage in

            switch recipient.type {
            case .oneToOne:
                self?.promptSendMessageFailed(
                    reason: reason,
                    errorMessage: errorMessage,
                    reserveErrorMessage: String.trans_promptSendVideoFailed
                )
            case .group:
                YepAlert.alertSorry(message: String.trans_promptSendVideoFailed, inViewController: self)
            }

        }, completion: { [weak self] success in
            println("sendVideo: \(success)")

            switch recipient.type {
            case .oneToOne:
                self?.showFriendRequestViewIfNeed()
            case .group:
                self?.updateGroupToIncludeMe()
            }
        })
    }
}

// MARK: Location

extension ConversationViewController {

    func sendLocation(with locationInfo: PickLocationViewControllerLocation.Info) {

        guard let recipient = self.recipient else {
            return
        }

        println("try sendLocationInfo to recipient: \(recipient)")

        sendLocationWithLocationInfo(locationInfo, toRecipient: recipient, afterCreatedMessage: { [weak self] message in

            self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true)

        }, failureHandler: { [weak self] reason, errorMessage in

            switch recipient.type {
            case .oneToOne:
                self?.promptSendMessageFailed(
                    reason: reason,
                    errorMessage: errorMessage,
                    reserveErrorMessage: String.trans_promptSendLocationFailed
                )
            case .group:
                YepAlert.alertSorry(message: String.trans_promptSendLocationFailed, inViewController: self)
            }

        }, completion: { [weak self] success in
            println("sendLocation: \(success)")

            switch recipient.type {
            case .oneToOne:
                self?.showFriendRequestViewIfNeed()
            case .group:
                self?.updateGroupToIncludeMe()
            }
        })
    }
}

