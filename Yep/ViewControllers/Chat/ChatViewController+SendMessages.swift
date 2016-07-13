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
                tableNode.view?.endUpdatesAnimated(false) { [weak self] success in
                    if let lastIndexPath = indexPaths.last {
                        self?.tableNode.view?.scrollToRowAtIndexPath(lastIndexPath, atScrollPosition: .Bottom, animated: true)
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

