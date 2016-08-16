//
//  ConversationViewController+TextIndicator.swift
//  Yep
//
//  Created by NIX on 16/4/14.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift
import YepKit
import YepNetworking

extension ConversationViewController {

    func promptSendMessageFailed(reason reason: Reason, errorMessage: String?, reserveErrorMessage: String) {

        if case .NoSuccessStatusCode(_, let errorCode) = reason where errorCode == ErrorCode.BlockedByRecipient {
            indicateBlockedByRecipient()
        } else {
            let message = errorMessage ?? reserveErrorMessage
            YepAlert.alertSorry(message: message, inViewController: self)
        }
    }

    private func indicateBlockedByRecipient() {
        SafeDispatch.async { [weak self] in
            if let conversation = self?.conversation {
                self?.indicateBlockedByRecipientInConversation(conversation)
            }
        }
    }

    private func indicateBlockedByRecipientInConversation(conversation: Conversation) {

        guard let realm = conversation.realm else {
            return
        }

        let message = Message()
        let messageID = "BlockedByRecipient." + NSUUID().UUIDString
        message.messageID = messageID
        message.blockedByRecipient = true
        message.conversation = conversation
        let _ = try? realm.write {
            realm.add(message)
        }

        updateConversationCollectionViewWithMessageIDs([messageID], messageAge: .New, scrollToBottom: true, success: { _ in
        })
    }
}
