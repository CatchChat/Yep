//
//  ChatViewController+SendMessages.swift
//  Yep
//
//  Created by NIX on 16/7/11.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepNetworking
import RealmSwift

// MARK: Text

extension ChatViewController {

    func send(text text: String) {

        guard let recipient = conversation.recipient else {
            return
        }

        println("try sendText to recipient: \(recipient)")

        sendText(text, toRecipient: recipient.ID, recipientType: recipient.type.nameForServer, afterCreatedMessage: { message in

             SafeDispatch.async { [weak self] in
                self?.update(withMessageIDs: nil, messageAge: .New, scrollToBottom: true, success: { _ in
                })
             }

        }, failureHandler: { reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            /*
             self?.promptSendMessageFailed(
             reason: reason,
             errorMessage: errorMessage,
             reserveErrorMessage: NSLocalizedString("Failed to send text!\nTry tap on message to resend.", comment: "")
             )
             */

        }, completion: { success in
            println("sendText to friend: \(success)")

            //self?.showFriendRequestViewIfNeed()
        })

        /*
         if self?.needDetectMention ?? false {
         self?.mentionView.hide()
         }
         */
    }
}

// MARK: Image

extension ChatViewController {

    func send(image image: UIImage) {

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
                    }

                    self?.update(withMessageIDs: nil, messageAge: .New, scrollToBottom: true, success: { _ in
                    })
                }

            }, failureHandler: { reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                /*
                self?.promptSendMessageFailed(
                    reason: reason,
                    errorMessage: errorMessage,
                    reserveErrorMessage: NSLocalizedString("Failed to send image!\nTry tap on message to resend.", comment: "")
                )*/

            }, completion: { success in
                println("send image to friend: \(success)")

                //self?.showFriendRequestViewIfNeed()
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
                    }

                    self?.update(withMessageIDs: nil, messageAge: .New, scrollToBottom: true, success: { _ in
                    })
                }

            }, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                YepAlert.alertSorry(message: NSLocalizedString("Failed to send image!\nTry tap on message to resend.", comment: ""), inViewController: self)

            }, completion: { success in
                println("send image to group: \(success)")

                //self?.updateGroupToIncludeMe()
            })
        }
    }
}

// MARK: Video

extension ChatViewController {

    func send(videoWithVideoURL videoURL: NSURL) {

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
                                    }
                                }

                                message.localAttachmentName = messageVideoName

                                message.mediaType = MessageMediaType.Video.rawValue
                                if let metaDataString = metaData {
                                    message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                                }
                            }
                        }
                    }

                    self?.update(withMessageIDs: nil, messageAge: .New, scrollToBottom: true, success: { _ in
                    })
                }
            }
        }

        if let withFriend = conversation.withFriend {

            sendVideoInFilePath(videoURL.path!, orFileData: nil, metaData: metaData, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: afterCreatedMessageAction, failureHandler: { reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                /*
                self?.promptSendMessageFailed(
                    reason: reason,
                    errorMessage: errorMessage,
                    reserveErrorMessage: NSLocalizedString("Failed to send video!\nTry tap on message to resend.", comment: "")
                )*/
                
            }, completion: { success in
                println("send video to friend: \(success)")
                
                //self?.showFriendRequestViewIfNeed()
            })
            
        } else if let withGroup = conversation.withGroup {
            
            sendVideoInFilePath(videoURL.path!, orFileData: nil, metaData: metaData, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: afterCreatedMessageAction, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)
                
                YepAlert.alertSorry(message: NSLocalizedString("Failed to send video!\nTry tap on message to resend.", comment: ""), inViewController: self)
                
            }, completion: { success in
                println("send video to group: \(success)")
                
                //self?.updateGroupToIncludeMe()
            })
        }
    }
}

// MARK: Location

extension ChatViewController {

    func send(locationInfo locationInfo: PickLocationViewControllerLocation.Info, toUser user: User) {

        sendLocationWithLocationInfo(locationInfo, toRecipient: user.userID, recipientType: "User", afterCreatedMessage: { message in

            SafeDispatch.async { [weak self] in
                self?.update(withMessageIDs: nil, messageAge: .New, scrollToBottom: true, success: { _ in
                })
            }

        }, failureHandler: { reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            /*
            self?.promptSendMessageFailed(
                reason: reason,
                errorMessage: errorMessage,
                reserveErrorMessage: NSLocalizedString("Failed to send location!\nTry tap on message to resend.", comment: "")
            )*/

        }, completion: { success in
            println("send location to friend: \(success)")

            //self?.showFriendRequestViewIfNeed()
        })
    }

    func send(locationInfo locationInfo: PickLocationViewControllerLocation.Info, toGroup group: Group) {

        sendLocationWithLocationInfo(locationInfo, toRecipient: group.groupID, recipientType: "Circle", afterCreatedMessage: { message in
            SafeDispatch.async { [weak self] in
                self?.update(withMessageIDs: nil, messageAge: .New, scrollToBottom: true, success: { _ in
                })
            }

        }, failureHandler: { [weak self] reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            YepAlert.alertSorry(message: NSLocalizedString("Failed to send location!\nTry tap on message to resend.", comment: ""), inViewController: self)
            
        }, completion: { success in
            println("send location to group: \(success)")
            
            //self?.updateGroupToIncludeMe()
        })
    }
}

// MARK: Update

extension ChatViewController {

    func update(withMessageIDs messageIDs: [String]?, messageAge: MessageAge, scrollToBottom: Bool, success: (Bool) -> Void) {

        // 重要
        guard navigationController?.topViewController == self else { // 防止 pop/push 后，原来未释放的 VC 也执行这下面的代码
            return
        }

        if messageIDs != nil {
            //batchMarkMessagesAsReaded()
        }

        //let subscribeViewHeight = isSubscribeViewShowing ? SubscribeView.height : 0
        //let keyboardAndToolBarHeight = messageToolbarBottomConstraint.constant + CGRectGetHeight(messageToolbar.bounds) + subscribeViewHeight
        let keyboardAndToolBarHeight: CGFloat = 0

        adjustUI(withMessageIDs: messageIDs, messageAge: messageAge, adjustHeight: keyboardAndToolBarHeight, scrollToBottom: scrollToBottom) { finished in
            success(finished)
        }

        if messageAge == .New {
            //conversationIsDirty = true
        }

        if messageIDs == nil {
            //afterSentMessageAction?()

            /*
            if isSubscribeViewShowing {

                realm.beginWrite()
                conversation.withGroup?.includeMe = true
                let _ = try? realm.commitWrite()

                delay(0.5) { [weak self] in
                    self?.subscribeView.hide()
                }
                
                moreViewManager.updateForGroupAffair()
            }
             */
        }
    }

    private func adjustUI(withMessageIDs messageIDs: [String]?, messageAge: MessageAge, adjustHeight: CGFloat, scrollToBottom: Bool, success: (Bool) -> Void) {

        let _lastTimeMessagesCount = lastTimeMessagesCount
        lastTimeMessagesCount = messages.count

        // 保证是增加消息
        if messages.count <= _lastTimeMessagesCount {
            return
        }

        let newMessagesCount = Int(messages.count - _lastTimeMessagesCount)

        // 异常：两种计数不相等，治标：reload，避免插入
        if let messageIDs = messageIDs {
            if newMessagesCount != messageIDs.count {
                reload()
                println("newMessagesCount != messageIDs.count")
                #if DEBUG
                    YepAlert.alertSorry(message: "请截屏报告!\nnewMessagesCount: \(newMessagesCount)\nmessageIDs.count: \(messageIDs.count)", inViewController: self)
                #endif
                return
            }
        }

        let lastDisplayedMessagesRange = displayedMessagesRange

        displayedMessagesRange.length += newMessagesCount

        if newMessagesCount > 0 {

            if let messageIDs = messageIDs {

                var indexPaths = [NSIndexPath]()

                for messageID in messageIDs {
                    if let
                        message = messageWithMessageID(messageID, inRealm: realm),
                        index = messages.indexOf(message) {
                        let indexPath = NSIndexPath(forItem: index - displayedMessagesRange.location, inSection: Section.Messages.rawValue)
                        //println("insert item: \(indexPath.item), \(index), \(displayedMessagesRange.location)")

                        indexPaths.append(indexPath)

                    } else {
                        println("unknown message")

                        #if DEBUG
                            YepAlert.alertSorry(message: "unknown message: \(messageID)", inViewController: self)
                        #endif

                        reload()
                        return
                    }
                }

                switch messageAge {

                case .New:

                    tableNode.view?.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Bottom)

                case .Old:

                    tableNode.view?.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Top)
                }

                println("insert other messages")

            } else {
                // 这里做了一个假设：本地刚创建的消息比所有的已有的消息都要新，这在创建消息里做保证（服务器可能传回创建在“未来”的消息）

                var indexPaths = [NSIndexPath]()

                for i in 0..<newMessagesCount {
                    let indexPath = NSIndexPath(forItem: lastDisplayedMessagesRange.length + i, inSection: Section.Messages.rawValue)
                    indexPaths.append(indexPath)
                }

                tableNode.view?.beginUpdates()
                tableNode.view?.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .None)
                tableNode.view?.endUpdatesAnimated(false) { success in
                    if let lastIndexPath = indexPaths.last {
                        doInNextRunLoop { [weak self] in
                            self?.tableNode.view?.scrollToRowAtIndexPath(lastIndexPath, atScrollPosition: .Bottom, animated: true)
                        }
                    }
                }

                println("insert self messages")
            }
        }

        success(true)
        // TODO: scroll
    }

    private func reload() {
        SafeDispatch.async { [weak self] in
            self?.tableNode.view?.reloadData()
        }
    }
}

