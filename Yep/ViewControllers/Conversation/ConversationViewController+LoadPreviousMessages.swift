//
//  ConversationViewController+LoadPreviousMessages.swift
//  Yep
//
//  Created by NIX on 16/6/28.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

extension ConversationViewController {

    func loadMessagesFromServer(with timeDirection: TimeDirection, excludeMessagesIn invalidMessageIDSet: Set<String>? = nil, failed: (() -> Void)? = nil, completion: ((_ messageIDs: [String], _ noMore: Bool) -> Void)? = nil) {

        messagesFromRecipient(recipient, withTimeDirection: timeDirection, failureHandler: { reason, errorMessage in

            SafeDispatch.async {
                failed?()
            }

        }, completion: { _messageIDs, noMore in
            println("@ messagesFromRecipient: \(_messageIDs.count)")
            var messageIDs: [String] = []
            if let invalidMessageIDSet = invalidMessageIDSet {
                for messageID in _messageIDs {
                    if !invalidMessageIDSet.contains(messageID) {
                        messageIDs.append(messageID)
                    }
                }
            } else {
                messageIDs = _messageIDs
            }
            println("# messagesFromRecipient: \(messageIDs.count)")

            SafeDispatch.async {
                completion?(messageIDs, noMore)
            }
        })
    }

    func tryLoadPreviousMessages(_ completion: @escaping () -> Void) {

        if isLoadingPreviousMessages {
            completion()
            return
        }

        guard !conversation.isInvalidated else {
            return
        }

        isLoadingPreviousMessages = true

        println("tryLoadPreviousMessages")

        if displayedMessagesRange.location == 0 {

            guard conversation.hasOlderMessages else {
                noMorePreviousMessages = true

                isLoadingPreviousMessages = false
                completion()
                return
            }

            let timeDirection: TimeDirection
            var invalidMessageIDSet: Set<String>?
            if let (message, headInvalidMessageIDSet) = firstValidMessageInMessageResults(messages) {
                let maxMessageID = message.messageID
                timeDirection = .past(maxMessageID: maxMessageID)
                invalidMessageIDSet = headInvalidMessageIDSet
            } else {
                timeDirection = .none
            }

            loadMessagesFromServer(with: timeDirection, excludeMessagesIn: invalidMessageIDSet, failed: { [weak self] in
                self?.isLoadingPreviousMessages = false
                completion()

            }, completion: { [weak self] messageIDs, noMore in
                if case .past = timeDirection {
                    self?.noMorePreviousMessages = noMore
                }

                tryPostNewMessagesReceivedNotificationWithMessageIDs(messageIDs, messageAge: timeDirection.messageAge)
                //self?.fayeRecievedNewMessages(messageIDs, messageAgeRawValue: timeDirection.messageAge.rawValue)

                self?.isLoadingPreviousMessages = false
                completion()
            })

        } else {
            var newMessagesCount = self.messagesBunchCount

            if (self.displayedMessagesRange.location - newMessagesCount) < 0 {
                newMessagesCount = self.displayedMessagesRange.location
            }

            guard newMessagesCount > 0 else {
                isLoadingPreviousMessages = false
                completion()
                return
            }

            self.displayedMessagesRange.location -= newMessagesCount
            self.displayedMessagesRange.length += newMessagesCount

            self.lastTimeMessagesCount = self.messages.count // 同样需要纪录它

            var indexPaths = [IndexPath]()
            for i in 0..<newMessagesCount {
                let indexPath = IndexPath(item: Int(i), section: Section.message.rawValue)
                indexPaths.append(indexPath)
            }

            let bottomOffset = self.conversationCollectionView.contentSize.height - self.conversationCollectionView.contentOffset.y

            CATransaction.begin()
            CATransaction.setDisableActions(true)

            self.conversationCollectionView.performBatchUpdates({ [weak self] in
                self?.conversationCollectionView.insertItems(at: indexPaths)

            }, completion: { [weak self] finished in
                if let strongSelf = self {
                    var contentOffset = strongSelf.conversationCollectionView.contentOffset
                    contentOffset.y = strongSelf.conversationCollectionView.contentSize.height - bottomOffset

                    strongSelf.conversationCollectionView.setContentOffset(contentOffset, animated: false)
                    
                    CATransaction.commit()
                    
                    // 上面的 CATransaction 保证了 CollectionView 在插入后不闪动

                    strongSelf.isLoadingPreviousMessages = false
                    completion()
                }
            })
        }
    }
}

