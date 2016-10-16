//
//  ConversationViewController+YepFayeServiceDelegate.swift
//  Yep
//
//  Created by NIX on 16/6/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

extension ConversationViewController: YepFayeServiceDelegate {

    func fayeRecievedInstantStateType(_ instantStateType: YepFayeService.InstantStateType, userID: String) {

        guard !conversation.isInvalidated else {
            return
        }
        guard let user = conversation.withFriend, user.userID == userID else {
            return
        }

        let content = String(format: NSLocalizedString("doing%@", comment: ""), "\(instantStateType)")

        titleView.stateInfoLabel.text = content
        titleView.stateInfoLabel.textColor = UIColor.yepTintColor()

        switch instantStateType {

        case .text:
            self.typingResetDelay = 2

        case .audio:
            self.typingResetDelay = 2.5
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

