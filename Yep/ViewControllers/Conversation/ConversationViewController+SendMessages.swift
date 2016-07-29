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
import YepNetworking

// MARK: Text

extension ConversationViewController {

    func send(text: String) {

        if text.isEmpty {
            return
        }

        if let withFriend = conversation.withFriend {

            println("try sendText to User: \(withFriend.userID)")
            println("my userID: \(YepUserDefaults.userID.value)")

            sendText(text, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { [weak self] message in

                SafeDispatch.async {
                    self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                    })
                }

            }, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                self?.promptSendMessageFailed(
                    reason: reason,
                    errorMessage: errorMessage,
                    reserveErrorMessage: NSLocalizedString("Failed to send text!\nTry tap on message to resend.", comment: "")
                )

            }, completion: { [weak self] success in
                println("sendText to friend: \(success)")

                self?.showFriendRequestViewIfNeed()
            })

        } else if let withGroup = conversation.withGroup {

            sendText(text, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { [weak self] message in

                SafeDispatch.async {
                    self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                    })
                }

                }, failureHandler: { [weak self] reason, errorMessage in
                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                    SafeDispatch.async {
                        YepAlert.alertSorry(message: NSLocalizedString("Failed to send text!\nTry tap on message to resend.", comment: ""), inViewController: self)
                    }

                }, completion: { [weak self] success in
                    println("sendText to group: \(success)")

                    self?.updateGroupToIncludeMe()
                })
        }

        if needDetectMention {
            mentionView.hide()
        }
    }
}

// MARK: Audio

extension ConversationViewController {

    func sendAudioWithURL(fileURL: NSURL, compressedDecibelSamples: [Float]) {

        // Prepare meta data

        var metaData: String? = nil

        var audioSamples = compressedDecibelSamples
        // 浮点数最多两位小数，使下面计算 metaData 时不至于太长
        for i in 0..<audioSamples.count {
            var sample = audioSamples[i]
            sample = round(sample * 100.0) / 100.0
            audioSamples[i] = sample
        }

        let audioAsset = AVURLAsset(URL: fileURL, options: nil)
        let audioDuration = CMTimeGetSeconds(audioAsset.duration) as Double

        println("\nComporessed \(audioSamples)")

        let audioMetaDataInfo = [
            Config.MetaData.audioDuration: audioDuration,
            Config.MetaData.audioSamples: audioSamples,
        ]

        if let audioMetaData = try? NSJSONSerialization.dataWithJSONObject(audioMetaDataInfo, options: []) {
            let audioMetaDataString = NSString(data: audioMetaData, encoding: NSUTF8StringEncoding) as? String
            metaData = audioMetaDataString
        }

        // Do send

        if let withFriend = conversation.withFriend {
            sendAudioInFilePath(fileURL.path!, orFileData: nil, metaData: metaData, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { [weak self] message in

                SafeDispatch.async {
                    let audioFileName = NSUUID().UUIDString
                    if let audioURL = NSFileManager.yepMessageAudioURLWithName(audioFileName) {
                        do {
                            try NSFileManager.defaultManager().copyItemAtURL(fileURL, toURL: audioURL)

                            if let realm = message.realm {
                                let _ = try? realm.write {
                                    message.localAttachmentName = audioFileName
                                    message.mediaType = MessageMediaType.Audio.rawValue
                                    if let metaDataString = metaData {
                                        message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                                    }
                                }
                            }

                        } catch let error {
                            println(error)
                        }
                    }

                    self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                    })
                }

            }, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                self?.promptSendMessageFailed(
                    reason: reason,
                    errorMessage: errorMessage,
                    reserveErrorMessage: NSLocalizedString("Failed to send audio!\nTry tap on message to resend.", comment: "")
                )

            }, completion: { [weak self] success in
                println("send audio to friend: \(success)")

                self?.showFriendRequestViewIfNeed()
            })

        } else if let withGroup = conversation.withGroup {
            sendAudioInFilePath(fileURL.path!, orFileData: nil, metaData: metaData, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { [weak self] message in

                SafeDispatch.async {
                    if let realm = message.realm {
                        let _ = try? realm.write {
                            message.localAttachmentName = fileURL.URLByDeletingPathExtension?.lastPathComponent ?? ""
                            message.mediaType = MessageMediaType.Audio.rawValue
                            if let metaDataString = metaData {
                                message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                            }
                        }

                        self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                        })
                    }
                }

            }, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                YepAlert.alertSorry(message: NSLocalizedString("Failed to send audio!\nTry tap on message to resend.", comment: ""), inViewController: self)

            }, completion: { [weak self] success in
                println("send audio to group: \(success)")

                self?.updateGroupToIncludeMe()
            })
        }
    }
}

// MARK: Image

extension ConversationViewController {

    func sendImage(image: UIImage) {

        // Prepare meta data

        let metaDataString = metaDataStringOfImage(image, needBlurThumbnail: true)

        // Do send

        let imageData = UIImageJPEGRepresentation(image, YepConfig.messageImageCompressionQuality())!

        let messageImageName = NSUUID().UUIDString

        if let withFriend = conversation.withFriend {

            sendImageInFilePath(nil, orFileData: imageData, metaData: metaDataString, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { [weak self] message in

                SafeDispatch.async {

                    if let _ = NSFileManager.saveMessageImageData(imageData, withName: messageImageName) {
                        if let realm = message.realm {
                            let _ = try? realm.write {
                                message.localAttachmentName = messageImageName
                                message.mediaType = MessageMediaType.Image.rawValue
                                if let metaDataString = metaDataString {
                                    message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                                }
                            }
                        }

                    } else {
                        self?.alertSaveFileFailed()
                    }

                    self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                    })
                }

            }, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                self?.promptSendMessageFailed(
                    reason: reason,
                    errorMessage: errorMessage,
                    reserveErrorMessage: NSLocalizedString("Failed to send image!\nTry tap on message to resend.", comment: "")
                )

            }, completion: { [weak self] success in
                println("send image to friend: \(success)")

                self?.showFriendRequestViewIfNeed()
            })

        } else if let withGroup = conversation.withGroup {

            sendImageInFilePath(nil, orFileData: imageData, metaData: metaDataString, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { [weak self] message in

                SafeDispatch.async {
                    if let _ = NSFileManager.saveMessageImageData(imageData, withName: messageImageName) {
                        if let realm = message.realm {
                            let _ = try? realm.write {
                                message.localAttachmentName = messageImageName
                                message.mediaType = MessageMediaType.Image.rawValue
                                if let metaDataString = metaDataString {
                                    message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                                }
                            }
                        }

                    } else {
                        self?.alertSaveFileFailed()
                    }

                    self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                    })
                }

            }, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                YepAlert.alertSorry(message: NSLocalizedString("Failed to send image!\nTry tap on message to resend.", comment: ""), inViewController: self)

            }, completion: { [weak self] success in
                println("send image to group: \(success)")

                self?.updateGroupToIncludeMe()
            })
        }
    }
}

// MARK: Video

extension ConversationViewController {

    func sendVideoWithVideoURL(videoURL: NSURL) {

        // Prepare meta data

        var metaData: String? = nil

        var thumbnailData: NSData?

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

            let videoMetaDataInfo: [String: AnyObject]

            let thumbnailSize = CGSize(width: thumbnailWidth, height: thumbnailHeight)

            if let thumbnail = image.resizeToSize(thumbnailSize, withInterpolationQuality: CGInterpolationQuality.Low) {
                let blurredThumbnail = thumbnail.blurredImageWithRadius(5, iterations: 7, tintColor: UIColor.clearColor())

                let data = UIImageJPEGRepresentation(blurredThumbnail, 0.7)!

                let string = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))

                println("video blurredThumbnail string length: \(string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))\n")

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

            if let videoMetaData = try? NSJSONSerialization.dataWithJSONObject(videoMetaDataInfo, options: []) {
                let videoMetaDataString = NSString(data: videoMetaData, encoding: NSUTF8StringEncoding) as? String
                metaData = videoMetaDataString
            }

            thumbnailData = UIImageJPEGRepresentation(image, YepConfig.messageImageCompressionQuality())
        }

        let messageVideoName = NSUUID().UUIDString

        let afterCreatedMessageAction = { [weak self] (message: Message) in

            SafeDispatch.async {

                if let videoData = NSData(contentsOfURL: videoURL) {

                    if let _ = NSFileManager.saveMessageVideoData(videoData, withName: messageVideoName) {
                        if let realm = message.realm {
                            let _ = try? realm.write {

                                if let thumbnailData = thumbnailData {
                                    if let _ = NSFileManager.saveMessageImageData(thumbnailData, withName: messageVideoName) {
                                        message.localThumbnailName = messageVideoName

                                    } else {
                                        self?.alertSaveFileFailed()
                                    }
                                }

                                message.localAttachmentName = messageVideoName

                                message.mediaType = MessageMediaType.Video.rawValue
                                if let metaDataString = metaData {
                                    message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                                }
                            }
                        }

                    } else {
                        self?.alertSaveFileFailed()
                    }

                    self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                    })
                }
            }
        }

        if let withFriend = conversation.withFriend {

            sendVideoInFilePath(videoURL.path!, orFileData: nil, metaData: metaData, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: afterCreatedMessageAction, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                self?.promptSendMessageFailed(
                    reason: reason,
                    errorMessage: errorMessage,
                    reserveErrorMessage: NSLocalizedString("Failed to send video!\nTry tap on message to resend.", comment: "")
                )

            }, completion: { [weak self] success in
                println("send video to friend: \(success)")

                self?.showFriendRequestViewIfNeed()
            })

        } else if let withGroup = conversation.withGroup {

            sendVideoInFilePath(videoURL.path!, orFileData: nil, metaData: metaData, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: afterCreatedMessageAction, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                YepAlert.alertSorry(message: NSLocalizedString("Failed to send video!\nTry tap on message to resend.", comment: ""), inViewController: self)

            }, completion: { [weak self] success in
                println("send video to group: \(success)")

                self?.updateGroupToIncludeMe()
            })
        }
    }
}

// MARK: Location

extension ConversationViewController {

    func sendLocationInfo(locationInfo: PickLocationViewControllerLocation.Info, toUser user: User) {

        sendLocationWithLocationInfo(locationInfo, toRecipient: user.userID, recipientType: "User", afterCreatedMessage: { message in

            SafeDispatch.async { [weak self] in
                self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                })
            }

        }, failureHandler: { [weak self] reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            self?.promptSendMessageFailed(
                reason: reason,
                errorMessage: errorMessage,
                reserveErrorMessage: NSLocalizedString("Failed to send location!\nTry tap on message to resend.", comment: "")
            )

        }, completion: { [weak self] success in
            println("send location to friend: \(success)")

            self?.showFriendRequestViewIfNeed()
        })
    }

    func sendLocationInfo(locationInfo: PickLocationViewControllerLocation.Info, toGroup group: Group) {

        sendLocationWithLocationInfo(locationInfo, toRecipient: group.groupID, recipientType: "Circle", afterCreatedMessage: { message in
            SafeDispatch.async { [weak self] in
                self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                })
            }

        }, failureHandler: { [weak self] reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            YepAlert.alertSorry(message: NSLocalizedString("Failed to send location!\nTry tap on message to resend.", comment: ""), inViewController: self)

        }, completion: { [weak self] success in
            println("send location to group: \(success)")

            self?.updateGroupToIncludeMe()
        })
    }
}

