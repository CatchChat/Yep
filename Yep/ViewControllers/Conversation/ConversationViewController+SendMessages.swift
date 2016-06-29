//
//  ConversationViewController+SendMessages.swift
//  Yep
//
//  Created by NIX on 16/6/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import YepKit
import YepNetworking

extension ConversationViewController {

    func sendLocationInfo(locationInfo: PickLocationViewControllerLocation.Info, toUser user: User) {

        sendLocationWithLocationInfo(locationInfo, toRecipient: user.userID, recipientType: "User", afterCreatedMessage: { message in

            SafeDispatch.async { [weak self] in
                self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                })
            }

        }, failureHandler: { [weak self] reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            self?.promptSendMessageFailed(
                reason: reason,
                errorMessage: errorMessage,
                reserveErrorMessage: NSLocalizedString("Failed to send location!\nTry tap on message to resend.", comment: "")
            )

        }, completion: { success -> Void in
            println("sendLocation to friend: \(success)")
        })
    }

    func sendLocationInfo(locationInfo: PickLocationViewControllerLocation.Info, toGroup group: Group) {

        sendLocationWithLocationInfo(locationInfo, toRecipient: group.groupID, recipientType: "Circle", afterCreatedMessage: { message in
            SafeDispatch.async { [weak self] in
                self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                })
            }

        }, failureHandler: { [weak self] reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            YepAlert.alertSorry(message: NSLocalizedString("Failed to send location!\nTry tap on message to resend.", comment: ""), inViewController: self)

        }, completion: { success -> Void in
            println("sendLocation to group: \(success)")
        })
    }
}

