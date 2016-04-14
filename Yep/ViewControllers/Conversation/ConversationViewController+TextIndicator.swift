//
//  ConversationViewController+TextIndicator.swift
//  Yep
//
//  Created by NIX on 16/4/14.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift

extension ConversationViewController {

    func indicateBlockedByRecipient() {
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
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
