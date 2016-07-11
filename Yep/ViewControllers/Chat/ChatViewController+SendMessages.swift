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

extension ChatViewController {

    func send(text text: String) {

        guard let recipient = conversation.recipient else {
            return
        }

        println("try sendText to recipient: \(recipient)")

        sendText(text, toRecipient: recipient.ID, recipientType: recipient.type.nameForServer, afterCreatedMessage: { message in

            /*
             SafeDispatch.async {
             self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
             })
             }*/

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

