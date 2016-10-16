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

    func promptSendMessageFailed(reason: Reason, errorMessage: String?, reserveErrorMessage: String) {

        if case .noSuccessStatusCode(_, let errorCode) = reason, errorCode == .blockedByRecipient {
            indicateBlockedByRecipient()

        } else {
            let message = errorMessage ?? reserveErrorMessage
            YepAlert.alertSorry(message: message, inViewController: self)
        }
    }

    fileprivate func indicateBlockedByRecipient() {

        func indicateBlockedByRecipientInConversation(_ conversation: Conversation) {

            guard let realm = conversation.realm else {
                return
            }

            let message = Message()
            let messageID = "BlockedByRecipient." + UUID().uuidString
            message.messageID = messageID
            message.blockedByRecipient = true
            message.conversation = conversation
            let _ = try? realm.write {
                realm.add(message)
            }

            updateConversationCollectionViewWithMessageIDs([messageID], messageAge: .new, scrollToBottom: true)
        }

        SafeDispatch.async { [weak self] in
            guard let strongSelf = self else { return }
            guard !strongSelf.conversation.isInvalidated else { return }
            indicateBlockedByRecipientInConversation(strongSelf.conversation)
        }
    }
}

