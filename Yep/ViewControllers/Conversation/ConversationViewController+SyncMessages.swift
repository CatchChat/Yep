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
}

