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

// MARK: Image

extension ConversationViewController {

    func sendImage(image: UIImage) {

        // Prepare meta data

        let metaDataString = metaDataStringOfImage(image, needBlurThumbnail: true)

        // Do send

        let imageData = UIImageJPEGRepresentation(image, YepConfig.messageImageCompressionQuality())!

        let messageImageName = NSUUID().UUIDString

        if let withFriend = conversation.withFriend {

            sendImageInFilePath(nil, orFileData: imageData, metaData: metaDataString, toRecipient: withFriend.userID, recipientType: "User", afterCreatedMessage: { [weak self] message in

                SafeDispatch.async {

                    if let _ = NSFileManager.saveMessageImageData(imageData, withName: messageImageName) {
                        if let realm = message.realm {
                            let _ = try? realm.write {
                                message.localAttachmentName = messageImageName
                                message.mediaType = MessageMediaType.Image.rawValue
                                if let metaDataString = metaDataString {
                                    message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                                }
                            }
                        }
                    }

                    self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                    })
                }

            }, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                self?.promptSendMessageFailed(
                    reason: reason,
                    errorMessage: errorMessage,
                    reserveErrorMessage: NSLocalizedString("Failed to send image!\nTry tap on message to resend.", comment: "")
                )

            }, completion: { [weak self] success in
                println("send image to friend: \(success)")

                self?.showFriendRequestViewIfNeed()
            })

        } else if let withGroup = conversation.withGroup {

            sendImageInFilePath(nil, orFileData: imageData, metaData: metaDataString, toRecipient: withGroup.groupID, recipientType: "Circle", afterCreatedMessage: { [weak self] message in

                SafeDispatch.async {
                    if let _ = NSFileManager.saveMessageImageData(imageData, withName: messageImageName) {
                        if let realm = message.realm {
                            let _ = try? realm.write {
                                message.localAttachmentName = messageImageName
                                message.mediaType = MessageMediaType.Image.rawValue
                                if let metaDataString = metaDataString {
                                    message.mediaMetaData = mediaMetaDataFromString(metaDataString, inRealm: realm)
                                }
                            }
                        }
                    }

                    self?.updateConversationCollectionViewWithMessageIDs(nil, messageAge: .New, scrollToBottom: true, success: { _ in
                    })
                }

            }, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                YepAlert.alertSorry(message: NSLocalizedString("Failed to send image!\nTry tap on message to resend.", comment: ""), inViewController: self)

            }, completion: { [weak self] success in
                println("send image to group: \(success)")

                self?.updateGroupToIncludeMe()
            })
        }
    }
}

// MARK: Location

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

        }, completion: { [weak self] success in
            println("send location to friend: \(success)")

            self?.showFriendRequestViewIfNeed()
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

        }, completion: { [weak self] success in
            println("send location to group: \(success)")

            self?.updateGroupToIncludeMe()
        })
    }
}

