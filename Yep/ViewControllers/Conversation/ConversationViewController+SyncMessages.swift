//
//  ConversationViewController+SyncMessages.swift
//  Yep
//
//  Created by NIX on 16/6/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import YepKit
import YepNetworking
import RealmSwift

extension ConversationViewController {

    func trySyncMessages() {

        let syncMessages: (failedAction: (() -> Void)?, successAction: (() -> Void)?) -> Void = { failedAction, successAction in

            SafeDispatch.async { [weak self] in

                guard let recipient = self?.recipient else {
                    return
                }

                let timeDirection: TimeDirection
                if let minMessageID = self?.messages.last?.messageID {
                    timeDirection = .Future(minMessageID: minMessageID)
                } else {
                    timeDirection = .None

                    self?.activityIndicator.startAnimating()
                }

                dispatch_async(realmQueue) { [weak self] in

                    messagesFromRecipient(recipient, withTimeDirection: timeDirection, failureHandler: { reason, errorMessage in
                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                        failedAction?()

                    }, completion: { [weak self] messageIDs, noMore in
                        println("messagesFromRecipient: \(messageIDs.count)")

                        if case .None = timeDirection {
                            self?.noMorePreviousMessages = noMore
                        }

                        SafeDispatch.async { [weak self] in
                            tryPostNewMessagesReceivedNotificationWithMessageIDs(messageIDs, messageAge: timeDirection.messageAge)
                            //self?.fayeRecievedNewMessages(messageIDs, messageAgeRawValue: timeDirection.messageAge.rawValue)

                            self?.activityIndicator.stopAnimating()
                        }

                        successAction?()
                    })
                }
            }
        }

        guard let conversationType = ConversationType(rawValue: conversation.type) else {
            return
        }

        switch conversationType {

        case .OneToOne:

            syncMessages(failedAction: nil, successAction: { [weak self] in
                self?.syncMessagesReadStatus()
            })
            
        case .Group:
            
            if let _ = conversation.withGroup {
                // 直接同步消息
                syncMessages(failedAction: nil, successAction: nil)
            }
        }
    }

    func syncMessagesReadStatus() {

        guard let recipient = recipient else {
            return
        }

        lastMessageReadByRecipient(recipient, failureHandler: nil, completion: { [weak self] lastMessageRead in

            if let lastMessageRead = lastMessageRead {
                self?.markAsReadAllSentMesagesBeforeUnixTime(lastMessageRead.unixTime, lastReadMessageID: lastMessageRead.messageID)
            }
        })
    }

    func markAsReadAllSentMesagesBeforeUnixTime(unixTime: NSTimeInterval, lastReadMessageID: String? = nil) {

        guard let recipient = recipient else {
            return
        }

        dispatch_async(realmQueue) {

            guard let realm = try? Realm(), conversation = recipient.conversationInRealm(realm) else {
                return
            }

            var lastMessageCreatedUnixTime = unixTime
            //println("markAsReadAllSentMesagesBeforeUnixTime: \(unixTime), \(lastReadMessageID)")
            if let lastReadMessageID = lastReadMessageID, message = messageWithMessageID(lastReadMessageID, inRealm: realm) {
                let createdUnixTime = message.createdUnixTime
                //println("lastMessageCreatedUnixTime: \(createdUnixTime)")
                if createdUnixTime > lastMessageCreatedUnixTime {
                    println("NOTICE: markAsReadAllSentMesagesBeforeUnixTime: \(unixTime), lastMessageCreatedUnixTime: \(createdUnixTime)")
                    lastMessageCreatedUnixTime = createdUnixTime
                }
            }

            let predicate = NSPredicate(format: "sendState = %d AND fromFriend != nil AND fromFriend.friendState = %d AND createdUnixTime <= %lf", MessageSendState.Successed.rawValue, UserFriendState.Me.rawValue, lastMessageCreatedUnixTime)

            let sendSuccessedMessages = messagesOfConversation(conversation, inRealm: realm).filter(predicate)

            println("sendSuccessedMessages.count: \(sendSuccessedMessages.count)")

            let _ = try? realm.write {
                sendSuccessedMessages.forEach {
                    $0.readed = true
                    $0.sendState = MessageSendState.Read.rawValue
                }
            }

            delay(0.5) {
                NSNotificationCenter.defaultCenter().postNotificationName(Config.Message.Notification.MessageStateChanged, object: nil)
            }
        }
    }

    func batchMarkMessagesAsReaded(updateOlderMessagesIfNeeded updateOlderMessagesIfNeeded: Bool = true) {

        SafeDispatch.async { [weak self] in

            guard let strongSelf = self else {
                return
            }

            guard let recipient = strongSelf.recipient, latestMessage = strongSelf.messages.last else {
                return
            }

            var needMarkInServer = false

            if updateOlderMessagesIfNeeded {

                var predicate = NSPredicate(format: "readed = false")

                if case .OneToOne = recipient.type {
                    predicate = NSPredicate(format: "readed = false AND fromFriend != nil AND fromFriend.friendState != %d", UserFriendState.Me.rawValue)
                }

                let filteredMessages = strongSelf.messages.filter(predicate)

                println("filteredMessages.count: \(filteredMessages.count)")
                println("conversation.unreadMessagesCount: \(strongSelf.conversation.unreadMessagesCount)")

                needMarkInServer = (!filteredMessages.isEmpty || (strongSelf.conversation.unreadMessagesCount > 0))

                filteredMessages.forEach { message in
                    let _ = try? strongSelf.realm.write {
                        message.readed = true
                    }
                }

            } else {
                let _ = try? strongSelf.realm.write {
                    latestMessage.readed = true
                }

                needMarkInServer = true

                println("mark latestMessage readed")
            }

            // 群组里没有我，不需要标记
            if recipient.type == .Group {
                if let group = strongSelf.conversation.withGroup where !group.includeMe {

                    // 此情况强制所有消息“已读”
                    let _ = try? strongSelf.realm.write {
                        strongSelf.messages.forEach { message in
                            message.readed = true
                        }
                    }

                    needMarkInServer = false
                }
            }

            if needMarkInServer {

                SafeDispatch.async {
                    NSNotificationCenter.defaultCenter().postNotificationName(Config.Notification.markAsReaded, object: nil)
                }

                if latestMessage.isReal {
                    batchMarkAsReadOfMessagesToRecipient(recipient, beforeMessage: latestMessage, failureHandler: nil, completion: {
                        println("batchMarkAsReadOfMessagesToRecipient OK")
                    })

                } else {
                    println("not need batchMarkAsRead fake message")
                }

            } else {
                println("don't needMarkInServer")
            }
        }

        let _ = try? realm.write { [weak self] in
            self?.conversation.unreadMessagesCount = 0
            self?.conversation.hasUnreadMessages = false
            self?.conversation.mentionedMe = false
        }
    }
}

