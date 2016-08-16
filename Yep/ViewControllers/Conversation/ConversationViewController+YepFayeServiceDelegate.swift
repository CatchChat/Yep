//
//  ConversationViewController+YepFayeServiceDelegate.swift
//  Yep
//
//  Created by NIX on 16/6/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

extension ConversationViewController: YepFayeServiceDelegate {

    func fayeRecievedInstantStateType(instantStateType: YepFayeService.InstantStateType, userID: String) {

        if let withFriend = conversation.withFriend {

            if userID == withFriend.userID {

                let content = String(format: NSLocalizedString("doing%@", comment: ""), "\(instantStateType)")

                titleView.stateInfoLabel.text = content
                titleView.stateInfoLabel.textColor = UIColor.yepTintColor()

                switch instantStateType {

                case .Text:
                    self.typingResetDelay = 2

                case .Audio:
                    self.typingResetDelay = 2.5
                }
            }
        }
    }

    /*
    func fayeRecievedNewMessages(messageIDs: [String], messageAgeRawValue: MessageAge.RawValue) {

        guard let
            messageAge = MessageAge(rawValue: messageAgeRawValue) else {
                println("Can NOT handleReceivedNewMessagesNotification")
                return
        }

        handleRecievedNewMessages(messageIDs, messageAge: messageAge)
    }

    func fayeMessagesMarkAsReadByRecipient(lastReadAt: NSTimeInterval, recipientType: String, recipientID: String) {

        if recipientID == recipient?.ID && recipientType == recipient?.type.nameForServer {
            self.markAsReadAllSentMesagesBeforeUnixTime(lastReadAt)
        }
    }
    */
}

