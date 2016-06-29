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
}

