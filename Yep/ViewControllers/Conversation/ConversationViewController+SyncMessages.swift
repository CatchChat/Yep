//
//  ConversationViewController+SyncMessages.swift
//  Yep
//
//  Created by NIX on 16/6/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import YepKit
import RealmSwift

extension ConversationViewController {

    func trySyncMessages() {

        guard !conversation.isInvalidated else {
            return
        }
        guard let recipient = self.recipient else {
            return
        }

        let syncMessages: (_ failedAction: (() -> Void)?, _ successAction: (() -> Void)?) -> Void = { failedAction, successAction in

            SafeDispatch.async { [weak self] in

                let timeDirection: TimeDirection
                if let minMessageID = self?.messages.last?.messageID {
                    timeDirection = .future(minMessageID: minMessageID)
                } else {
                    timeDirection = .none
                }

                if case .none = timeDirection {
                    self?.activityIndicator.startAnimating()
                }

                realmQueue.async { [weak self] in

                    messagesFromRecipient(recipient, withTimeDirection: timeDirection, failureHandler: { reason, errorMessage in

                        failedAction?()

                    }, completion: { [weak self] messageIDs, noMore in
                        println("messagesFromRecipient: \(messageIDs.count)")

                        if case .none = timeDirection {
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

        switch recipient.type {

        case .oneToOne:

            syncMessages(nil, { [weak self] in
                self?.syncMessagesReadStatus()
            })
            
        case .group:
            
            if let _ = conversation.withGroup {
                // 直接同步消息
                syncMessages(nil, nil)
            }
        }
    }

    func syncMessagesReadStatus() {

        lastMessageReadByRecipient(recipient, failureHandler: nil, completion: { [weak self] lastMessageRead in

            if let lastMessageRead = lastMessageRead {
                self?.markAsReadAllSentMesagesBeforeUnixTime(lastMessageRead.unixTime, lastReadMessageID: lastMessageRead.messageID)
            }
        })
    }

    func markAsReadAllSentMesagesBeforeUnixTime(_ unixTime: TimeInterval, lastReadMessageID: String? = nil) {

        guard let recipient = self.recipient else {
            return
        }

        realmQueue.async {

            guard let realm = try? Realm(), let conversation = recipient.conversationInRealm(realm) else {
                return
            }

            var lastMessageCreatedUnixTime = unixTime
            //println("markAsReadAllSentMesagesBeforeUnixTime: \(unixTime), \(lastReadMessageID)")
            if let lastReadMessageID = lastReadMessageID, let message = messageWithMessageID(lastReadMessageID, inRealm: realm) {
                let createdUnixTime = message.createdUnixTime
                //println("lastMessageCreatedUnixTime: \(createdUnixTime)")
                if createdUnixTime > lastMessageCreatedUnixTime {
                    println("NOTICE: markAsReadAllSentMesagesBeforeUnixTime: \(unixTime), lastMessageCreatedUnixTime: \(createdUnixTime)")
                    lastMessageCreatedUnixTime = createdUnixTime
                }
            }

            let predicate = NSPredicate(format: "sendState = %d AND fromFriend != nil AND fromFriend.friendState = %d AND createdUnixTime <= %lf", MessageSendState.successed.rawValue, UserFriendState.me.rawValue, lastMessageCreatedUnixTime)

            let sendSuccessedMessages = messagesOfConversation(conversation, inRealm: realm).filter(predicate)

            println("sendSuccessedMessages.count: \(sendSuccessedMessages.count)")

            let _ = try? realm.write {
                sendSuccessedMessages.forEach {
                    $0.readed = true
                    $0.sendState = MessageSendState.read.rawValue
                }
            }

            _ = delay(0.5) {
                NotificationCenter.default.post(name: Config.NotificationName.messageStateChanged, object: nil)
            }
        }
    }

    func batchMarkMessagesAsReaded(updateOlderMessagesIfNeeded: Bool = true) {

        guard let recipient = self.recipient else {
            return
        }

        SafeDispatch.async { [weak self] in

            guard let strongSelf = self else {
                return
            }
            guard let latestMessage = strongSelf.messages.last else {
                return
            }

            var needMarkInServer = false

            if updateOlderMessagesIfNeeded {

                var predicate = NSPredicate(format: "readed = false")

                if case .oneToOne = recipient.type {
                    predicate = NSPredicate(format: "readed = false AND fromFriend != nil AND fromFriend.friendState != %d", UserFriendState.me.rawValue)
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
            if recipient.type == .group {
                if let group = strongSelf.conversation.withGroup, !group.includeMe {

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
                    NotificationCenter.default.post(name: Config.NotificationName.markAsReaded, object: nil)
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

