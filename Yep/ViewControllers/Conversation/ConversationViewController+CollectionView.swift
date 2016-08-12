//
//  ConversationViewController+CollectionView.swift
//  Yep
//
//  Created by NIX on 16/6/28.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import MapKit
import YepKit
import YepNetworking
import YepPreview
import OpenGraph
import RealmSwift

extension ConversationViewController {

    private func tryShowConversationWithFeed(feed: DiscoveredFeed?) {

        if let feed = feed {
            performSegueWithIdentifier("showConversationWithFeed", sender: Box<DiscoveredFeed>(feed))

        } else {
            YepAlert.alertSorry(message: NSLocalizedString("Feed not found!", comment: ""), inViewController: self)
        }
    }
}

extension ConversationViewController {

    func prepareConversationCollectionView() {

        conversationCollectionView.keyboardDismissMode = .OnDrag
        conversationCollectionView.alwaysBounceVertical = true
        conversationCollectionView.bounces = true

        conversationCollectionView.registerNibOf(LoadMoreCollectionViewCell)
        conversationCollectionView.registerNibOf(ChatSectionDateCell)

        conversationCollectionView.registerClassOf(ChatTextIndicatorCell)

        conversationCollectionView.registerClassOf(ChatLeftTextCell)
        conversationCollectionView.registerClassOf(ChatLeftTextURLCell)
        conversationCollectionView.registerClassOf(ChatLeftImageCell)
        conversationCollectionView.registerClassOf(ChatLeftAudioCell)
        conversationCollectionView.registerClassOf(ChatLeftVideoCell)
        conversationCollectionView.registerClassOf(ChatLeftLocationCell)
        conversationCollectionView.registerNibOf(ChatLeftSocialWorkCell)

        conversationCollectionView.registerClassOf(ChatRightTextCell)
        conversationCollectionView.registerClassOf(ChatRightTextURLCell)
        conversationCollectionView.registerClassOf(ChatRightImageCell)
        conversationCollectionView.registerClassOf(ChatRightAudioCell)
        conversationCollectionView.registerClassOf(ChatRightVideoCell)
        conversationCollectionView.registerClassOf(ChatRightLocationCell)
    }
}

extension ConversationViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    @objc func didRecieveMenuWillHideNotification(notification: NSNotification) {

        println("Menu Will hide")

        selectedIndexPathForMenu = nil
    }

    @objc func didRecieveMenuWillShowNotification(notification: NSNotification) {

        println("Menu Will show")

        guard let menu = notification.object as? UIMenuController, selectedIndexPathForMenu = selectedIndexPathForMenu, cell = conversationCollectionView.cellForItemAtIndexPath(selectedIndexPathForMenu) as? ChatBaseCell else {
            return
        }

        var bubbleFrame = CGRectZero

        if let cell = cell as? ChatLeftTextCell {
            bubbleFrame = cell.convertRect(cell.textContentTextView.frame, toView: view)

        } else if let cell = cell as? ChatRightTextCell {
            bubbleFrame = cell.convertRect(cell.textContainerView.frame, toView: view)

        } else if let cell = cell as? ChatLeftTextURLCell {
            bubbleFrame = cell.convertRect(cell.textContentTextView.frame, toView: view)

        } else if let cell = cell as? ChatRightTextURLCell {
            bubbleFrame = cell.convertRect(cell.textContainerView.frame, toView: view)

        } else if let cell = cell as? ChatLeftImageCell {
            bubbleFrame = cell.convertRect(cell.messageImageView.frame, toView: view)

        } else if let cell = cell as? ChatRightImageCell {
            bubbleFrame = cell.convertRect(cell.messageImageView.frame, toView: view)

        } else if let cell = cell as? ChatLeftAudioCell {
            bubbleFrame = cell.convertRect(cell.audioContainerView.frame, toView: view)

        } else if let cell = cell as? ChatRightAudioCell {
            bubbleFrame = cell.convertRect(cell.audioContainerView.frame, toView: view)

        } else if let cell = cell as? ChatLeftVideoCell {
            bubbleFrame = cell.convertRect(cell.thumbnailImageView.frame, toView: view)

        } else if let cell = cell as? ChatRightVideoCell {
            bubbleFrame = cell.convertRect(cell.thumbnailImageView.frame, toView: view)

        } else if let cell = cell as? ChatLeftLocationCell {
            bubbleFrame = cell.convertRect(cell.mapImageView.frame, toView: view)

        } else if let cell = cell as? ChatRightLocationCell {
            bubbleFrame = cell.convertRect(cell.mapImageView.frame, toView: view)

        } else {
            return
        }

        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIMenuControllerWillShowMenuNotification, object: nil)

        menu.setTargetRect(bubbleFrame, inView: view)
        menu.setMenuVisible(true, animated: true)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConversationViewController.didRecieveMenuWillShowNotification(_:)), name: UIMenuControllerWillShowMenuNotification, object: nil)
    }

    func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {

        selectedIndexPathForMenu = indexPath

        if let _ = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatBaseCell {

            // must configure it before show

            var canReport = false

            let title: String
            if let message = messages[safe: (displayedMessagesRange.location + indexPath.item)] {
                let isMyMessage = message.fromFriend?.isMe ?? false
                if isMyMessage {
                    title = NSLocalizedString("Recall", comment: "")
                } else {
                    title = NSLocalizedString("Hide", comment: "")
                    canReport = true
                }
            } else {
                title = NSLocalizedString("Delete", comment: "")
            }

            var menuItems = [
                UIMenuItem(title: title, action: #selector(ChatBaseCell.deleteMessage(_:))),
            ]

            if canReport {
                let reportItem = UIMenuItem(title: NSLocalizedString("Report", comment: ""), action: #selector(ChatBaseCell.reportMessage(_:)))
                menuItems.append(reportItem)
            }

            UIMenuController.sharedMenuController().menuItems = menuItems

            return true

        } else {
            selectedIndexPathForMenu = nil
        }

        return false
    }

    func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {

        if let _ = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatRightTextCell {
            if action == #selector(NSObject.copy(_:)) {
                return true
            }

        } else if let _ = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatLeftTextCell {
            if action == #selector(NSObject.copy(_:)) {
                return true
            }
        }

        if action == #selector(ChatBaseCell.deleteMessage(_:)) {
            return true
        }

        if action == #selector(ChatBaseCell.reportMessage(_:)) {
            return true
        }

        return false
    }

    func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {

        if let cell = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatRightTextCell {
            if action == #selector(NSObject.copy(_:)) {
                UIPasteboard.generalPasteboard().string = cell.textContentTextView.text
            }

        } else if let cell = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatLeftTextCell {
            if action == #selector(NSObject.copy(_:)) {
                UIPasteboard.generalPasteboard().string = cell.textContentTextView.text
            }
        }
    }

    private func deleteMessageAtIndexPath(message: Message, indexPath: NSIndexPath) {
        SafeDispatch.async { [weak self] in

            guard let strongSelf = self, realm = message.realm else {
                return
            }

            defer {
                realm.refresh()
            }

            let isMyMessage = message.fromFriend?.isMe ?? false

            var sectionDateMessage: Message?

            if let currentMessageIndex = strongSelf.messages.indexOf(message) {

                let previousMessageIndex = currentMessageIndex - 1

                if let previousMessage = strongSelf.messages[safe: previousMessageIndex] {

                    if previousMessage.mediaType == MessageMediaType.SectionDate.rawValue {
                        sectionDateMessage = previousMessage
                    }
                }
            }

            let currentIndexPath: NSIndexPath
            if let index = strongSelf.messages.indexOf(message) {
                currentIndexPath = NSIndexPath(forItem: index - strongSelf.displayedMessagesRange.location, inSection: indexPath.section)
            } else {
                currentIndexPath = indexPath
            }

            if let sectionDateMessage = sectionDateMessage {

                var canDeleteTwoMessages = false // 考虑刚好的边界情况，例如消息为本束的最后一条，而 sectionDate 在上一束中
                if strongSelf.displayedMessagesRange.length >= 2 {
                    strongSelf.displayedMessagesRange.length -= 2
                    canDeleteTwoMessages = true

                } else {
                    if strongSelf.displayedMessagesRange.location >= 1 {
                        strongSelf.displayedMessagesRange.location -= 1
                    }
                    strongSelf.displayedMessagesRange.length -= 1
                }

                let _ = try? realm.write {
                    message.deleteAttachmentInRealm(realm)

                    realm.delete(sectionDateMessage)

                    if isMyMessage {

                        let messageID = message.messageID

                        realm.delete(message)

                        deleteMessageFromServer(messageID: messageID, failureHandler: nil, completion: {
                            println("deleteMessageFromServer: \(messageID)")
                        })

                    } else {
                        message.hidden = true
                    }
                }

                if canDeleteTwoMessages {
                    let previousIndexPath = NSIndexPath(forItem: currentIndexPath.item - 1, inSection: currentIndexPath.section)
                    strongSelf.conversationCollectionView.deleteItemsAtIndexPaths([previousIndexPath, currentIndexPath])
                } else {
                    strongSelf.conversationCollectionView.deleteItemsAtIndexPaths([currentIndexPath])
                }

            } else {
                strongSelf.displayedMessagesRange.length -= 1

                let _ = try? realm.write {
                    message.deleteAttachmentInRealm(realm)

                    if isMyMessage {

                        let messageID = message.messageID

                        realm.delete(message)

                        deleteMessageFromServer(messageID: messageID, failureHandler: nil, completion: {
                            println("deleteMessageFromServer: \(messageID)")
                        })

                    } else {
                        message.hidden = true
                    }
                }

                strongSelf.conversationCollectionView.deleteItemsAtIndexPaths([currentIndexPath])
            }

            // 必须更新，插入时需要
            strongSelf.lastTimeMessagesCount = strongSelf.messages.count
        }
    }

    enum Section: Int {
        case LoadPrevious
        case Message
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else {
            return 0
        }

        switch section {

        case .LoadPrevious:
            return 1

        case .Message:
            return displayedMessagesRange.length
        }
    }

    private func tryShowMessageMediaFromMessage(message: Message) {

        if let messageIndex = messages.indexOf(message) {

            let indexPath = NSIndexPath(forRow: messageIndex - displayedMessagesRange.location , inSection: Section.Message.rawValue)

            if let cell = conversationCollectionView.cellForItemAtIndexPath(indexPath) {

                var frame = CGRectZero
                var image: UIImage?
                var transitionView: UIView?

                if let sender = message.fromFriend {
                    if sender.friendState != UserFriendState.Me.rawValue {
                        switch message.mediaType {

                        case MessageMediaType.Image.rawValue:
                            let cell = cell as! ChatLeftImageCell
                            image = cell.messageImageView.image
                            transitionView = cell.messageImageView
                            frame = cell.convertRect(cell.messageImageView.frame, toView: view)

                        case MessageMediaType.Video.rawValue:
                            let cell = cell as! ChatLeftVideoCell
                            image = cell.thumbnailImageView.image
                            transitionView = cell.thumbnailImageView
                            frame = cell.convertRect(cell.thumbnailImageView.frame, toView: view)

                        default:
                            break
                        }

                    } else {
                        switch message.mediaType {

                        case MessageMediaType.Image.rawValue:
                            let cell = cell as! ChatRightImageCell
                            image = cell.messageImageView.image
                            transitionView = cell.messageImageView
                            frame = cell.convertRect(cell.messageImageView.frame, toView: view)

                        case MessageMediaType.Video.rawValue:
                            let cell = cell as! ChatRightVideoCell
                            image = cell.thumbnailImageView.image
                            transitionView = cell.thumbnailImageView
                            frame = cell.convertRect(cell.thumbnailImageView.frame, toView: view)

                        default:
                            break
                        }
                    }
                }

                guard image != nil else {
                    return
                }

                if message.mediaType == MessageMediaType.Video.rawValue {

                    let vc = UIStoryboard.Scene.mediaPreview

                    vc.previewMedias = [PreviewMedia.MessageType(message: message)]
                    vc.startIndex = 0

                    vc.previewImageViewInitalFrame = frame
                    vc.topPreviewImage = message.thumbnailImage
                    vc.bottomPreviewImage = image

                    vc.transitionView = transitionView

                    doInNextRunLoop { // 避免太快消失产生闪烁
                        transitionView?.alpha = 0
                    }

                    vc.afterDismissAction = { [weak self] in
                        transitionView?.alpha = 1
                        self?.view.window?.makeKeyAndVisible()
                    }

                    mediaPreviewWindow.rootViewController = vc
                    mediaPreviewWindow.windowLevel = UIWindowLevelAlert - 1
                    mediaPreviewWindow.makeKeyAndVisible()

                } else if message.mediaType == MessageMediaType.Image.rawValue {

                    let predicate = NSPredicate(format: "mediaType = %d", MessageMediaType.Image.rawValue)
                    let mediaMessagesResult = messages.filter(predicate)
                    let mediaMessages = mediaMessagesResult.map({ $0 })

                    guard let index = mediaMessagesResult.indexOf(message) else {
                        return
                    }

                    let transitionViews: [UIView?] = mediaMessages.map({
                        if let index = messages.indexOf($0) {
                            if index == messageIndex {
                                let cellIndex = index - displayedMessagesRange.location
                                let cell = conversationCollectionView.cellForItemAtIndexPath(NSIndexPath(forItem: cellIndex, inSection: Section.Message.rawValue))

                                if let leftImageCell = cell as? ChatLeftImageCell {
                                    return leftImageCell.messageImageView
                                } else if let rightImageCell = cell as? ChatRightImageCell {
                                    return rightImageCell.messageImageView
                                }
                            } else {
                                return nil
                            }
                        }
                        
                        return nil
                    })

                    self.previewTransitionViews = transitionViews

                    let previewMessagePhotos = mediaMessages.map({ PreviewMessagePhoto(message: $0) })
                    if let
                        imageFileURL = message.imageFileURL,
                        image = UIImage(contentsOfFile: imageFileURL.path!) {
                        previewMessagePhotos[index].image = image
                    }
                    self.previewMessagePhotos = previewMessagePhotos

                    let photos: [Photo] = previewMessagePhotos.map({ $0 })
                    let initialPhoto = photos[index]

                    let photosViewController = PhotosViewController(photos: photos, initialPhoto: initialPhoto, delegate: self)
                    self.presentViewController(photosViewController, animated: true, completion: nil)
                }
            }
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .LoadPrevious:

            let cell: LoadMoreCollectionViewCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
            return cell

        case .Message:

            guard let message = messages[safe: (displayedMessagesRange.location + indexPath.item)] else {
                println("🐌 Conversation: message NOT found!")

                let cell: ChatSectionDateCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                cell.sectionDateLabel.text = "🐌"

                return cell
            }

            if message.mediaType == MessageMediaType.SectionDate.rawValue {

                let cell: ChatSectionDateCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                cell.configureWithMessage(message)

                return cell
            }

            let tapUsernameAction: (username: String) -> Void = { [weak self] username in
                self?.tryShowProfileWithUsername(username)
            }

            guard let sender = message.fromFriend else {

                if message.blockedByRecipient {
                    let cell: ChatTextIndicatorCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    cell.configureWithMessage(message, indicateType: .BlockedByRecipient)

                    return cell
                }

                println("🐌🐌 Conversation: message has NOT fromFriend!")

                let cell: ChatSectionDateCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                cell.sectionDateLabel.text = "🐌🐌"

                return cell
            }

            func prepareCell(cell: ChatBaseCell) {

                if let _ = self.conversation.withGroup {
                    cell.inGroup = true
                } else {
                    cell.inGroup = false
                }

                cell.tapAvatarAction = { [weak self] user in
                    self?.performSegueWithIdentifier("showProfile", sender: user)
                }

                cell.deleteMessageAction = { [weak self] in
                    self?.deleteMessageAtIndexPath(message, indexPath: indexPath)
                }

                cell.reportMessageAction = { [weak self] in
                    self?.report(.Message(messageID: message.messageID))
                }
            }

            if sender.friendState != UserFriendState.Me.rawValue { // from Friend

                switch message.mediaType {

                case MessageMediaType.Image.rawValue:

                    let cell: ChatLeftImageCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                    prepareCell(cell)
                    cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                        if message.downloadState == MessageDownloadState.Downloaded.rawValue {

                            if let messageTextView = self?.messageToolbar.messageTextView {
                                if messageTextView.isFirstResponder() {
                                    self?.messageToolbar.state = .Default
                                    return
                                }
                            }

                            self?.tryShowMessageMediaFromMessage(message)

                        } else {
                            //YepAlert.alertSorry(message: NSLocalizedString("Please wait while the image is not ready!", comment: ""), inViewController: self)
                        }
                    })

                    return cell

                case MessageMediaType.Audio.rawValue:

                    let cell: ChatLeftAudioCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                    prepareCell(cell)
                    let audioPlayedDuration = audioPlayedDurationOfMessage(message)
                    cell.configureWithMessage(message, audioPlayedDuration: audioPlayedDuration, audioBubbleTapAction: { [weak self] in

                        if message.downloadState == MessageDownloadState.Downloaded.rawValue {
                            self?.playMessageAudioWithMessage(message)

                        } else {
                            //YepAlert.alertSorry(message: NSLocalizedString("Please wait while the audio is not ready!", comment: ""), inViewController: self)
                        }
                    })

                    return cell

                case MessageMediaType.Video.rawValue:

                    let cell: ChatLeftVideoCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                    prepareCell(cell)
                    cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                        if message.downloadState == MessageDownloadState.Downloaded.rawValue {

                            if let messageTextView = self?.messageToolbar.messageTextView {
                                if messageTextView.isFirstResponder() {
                                    self?.messageToolbar.state = .Default
                                    return
                                }
                            }

                            self?.tryShowMessageMediaFromMessage(message)

                        } else {
                            //YepAlert.alertSorry(message: NSLocalizedString("Please wait while the video is not ready!", comment: ""), inViewController: self)
                        }

                    })

                    return cell

                case MessageMediaType.Location.rawValue:

                    let cell: ChatLeftLocationCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                    prepareCell(cell)
                    cell.configureWithMessage(message, mediaTapAction: {
                        if let coordinate = message.coordinate {
                            let locationCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
                            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: locationCoordinate, addressDictionary: nil))
                            mapItem.name = message.textContent
                            /*
                             let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                             mapItem.openInMapsWithLaunchOptions(launchOptions)
                             */
                            mapItem.openInMapsWithLaunchOptions(nil)
                        }
                    })

                    return cell

                case MessageMediaType.SocialWork.rawValue:

                    let cell: ChatLeftSocialWorkCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                    cell.configureWithMessage(message)
                    cell.createFeedAction = { [weak self] socialWork in
                        self?.performSegueWithIdentifier("presentNewFeed", sender: socialWork)
                    }

                    return cell

                default:

                    if message.deletedByCreator {
                        let cell: ChatTextIndicatorCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                        cell.configureWithMessage(message, indicateType: .RecalledMessage)
                        return cell

                    } else {
                        if message.openGraphInfo != nil {
                            let cell: ChatLeftTextURLCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                            prepareCell(cell)

                            let layoutCache = chatTextCellLayoutCacheOfMessage(message)

                            cell.configureWithMessage(message, layoutCache: layoutCache)

                            cell.tapUsernameAction = tapUsernameAction

                            cell.tapFeedAction = { [weak self] feed in
                                self?.tryShowConversationWithFeed(feed)
                            }

                            cell.tapOpenGraphURLAction = { [weak self] URL in
                                if !URL.yep_matchSharedFeed({ [weak self] feed in self?.tryShowConversationWithFeed(feed) }) {
                                    self?.yep_openURL(URL)
                                }
                            }
                            
                            return cell

                        } else {
                            let cell: ChatLeftTextCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                            prepareCell(cell)

                            let layoutCache = chatTextCellLayoutCacheOfMessage(message)

                            cell.configureWithMessage(message, layoutCache: layoutCache)

                            cell.tapUsernameAction = tapUsernameAction

                            cell.tapFeedAction = { [weak self] feed in
                                self?.tryShowConversationWithFeed(feed)
                            }

                            return cell
                        }
                    }
                }

            } else { // from Me

                switch message.mediaType {

                case MessageMediaType.Image.rawValue:

                    let cell: ChatRightImageCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                    prepareCell(cell)

                    cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                        if message.sendState == MessageSendState.Failed.rawValue {

                            YepAlert.confirmOrCancel(title: NSLocalizedString("title.action", comment: ""), message: NSLocalizedString("Resend image?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                                resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                                    self?.promptSendMessageFailed(
                                        reason: reason,
                                        errorMessage: errorMessage,
                                        reserveErrorMessage: NSLocalizedString("Failed to resend image!\nPlease make sure your device is connected to the Internet.", comment: "")
                                    )

                                }, completion: { success in
                                    println("resendImage: \(success)")
                                })

                            }, cancelAction: {
                            })

                        } else {
                            if let messageTextView = self?.messageToolbar.messageTextView {
                                if messageTextView.isFirstResponder() {
                                    self?.messageToolbar.state = .Default
                                    return
                                }
                            }

                            self?.tryShowMessageMediaFromMessage(message)
                        }
                    })

                    return cell

                case MessageMediaType.Audio.rawValue:

                    let cell: ChatRightAudioCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                    prepareCell(cell)

                    let audioPlayedDuration = audioPlayedDurationOfMessage(message)

                    cell.configureWithMessage(message, audioPlayedDuration: audioPlayedDuration, audioBubbleTapAction: { [weak self] in

                        if message.sendState == MessageSendState.Failed.rawValue {

                            YepAlert.confirmOrCancel(title: NSLocalizedString("title.action", comment: ""), message: NSLocalizedString("Resend audio?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                                resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                                    self?.promptSendMessageFailed(
                                        reason: reason,
                                        errorMessage: errorMessage,
                                        reserveErrorMessage: NSLocalizedString("Failed to resend audio!\nPlease make sure your device is connected to the Internet.", comment: "")
                                    )

                                }, completion: { success in
                                    println("resendAudio: \(success)")
                                })

                                }, cancelAction: {
                            })

                            return
                        }
                        
                        self?.playMessageAudioWithMessage(message)
                    })

                    return cell

                case MessageMediaType.Video.rawValue:

                    let cell: ChatRightVideoCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                    prepareCell(cell)
                    cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                        if message.sendState == MessageSendState.Failed.rawValue {

                            YepAlert.confirmOrCancel(title: NSLocalizedString("title.action", comment: ""), message: NSLocalizedString("Resend video?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                                resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                                    self?.promptSendMessageFailed(
                                        reason: reason,
                                        errorMessage: errorMessage,
                                        reserveErrorMessage: NSLocalizedString("Failed to resend video!\nPlease make sure your device is connected to the Internet.", comment: "")
                                    )

                                }, completion: { success in
                                    println("resendVideo: \(success)")
                                })

                            }, cancelAction: {
                            })

                        } else {
                            if let messageTextView = self?.messageToolbar.messageTextView {
                                if messageTextView.isFirstResponder() {
                                    self?.messageToolbar.state = .Default
                                    return
                                }
                            }

                            self?.tryShowMessageMediaFromMessage(message)
                        }
                    })

                    return cell

                case MessageMediaType.Location.rawValue:

                    let cell: ChatRightLocationCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                    prepareCell(cell)
                    cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                        if message.sendState == MessageSendState.Failed.rawValue {

                            YepAlert.confirmOrCancel(title: NSLocalizedString("title.action", comment: ""), message: NSLocalizedString("Resend location?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                                resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                                    self?.promptSendMessageFailed(
                                        reason: reason,
                                        errorMessage: errorMessage,
                                        reserveErrorMessage: NSLocalizedString("Failed to resend location!\nPlease make sure your device is connected to the Internet.", comment: "")
                                    )

                                }, completion: { success in
                                    println("resendLocation: \(success)")
                                })

                                }, cancelAction: {
                            })

                        } else {
                            if let coordinate = message.coordinate {
                                let locationCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
                                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: locationCoordinate, addressDictionary: nil))
                                mapItem.name = message.textContent
                                /*
                                 let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                                 mapItem.openInMapsWithLaunchOptions(launchOptions)
                                 */
                                mapItem.openInMapsWithLaunchOptions(nil)
                            }
                        }
                    })

                    return cell

                default:

                    let mediaTapAction: () -> Void = { [weak self] in

                        guard message.sendState == MessageSendState.Failed.rawValue else {
                            return
                        }

                        YepAlert.confirmOrCancel(title: NSLocalizedString("title.action", comment: ""), message: NSLocalizedString("Resend text?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                            resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                                self?.promptSendMessageFailed(
                                    reason: reason,
                                    errorMessage: errorMessage,
                                    reserveErrorMessage: NSLocalizedString("Failed to resend text!\nPlease make sure your device is connected to the Internet.", comment: "")
                                )

                            }, completion: { success in
                                println("resendText: \(success)")
                            })
                            
                        }, cancelAction: {
                        })
                    }

                    if message.openGraphInfo != nil {
                        let cell: ChatRightTextURLCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                        prepareCell(cell)

                        let layoutCache = chatTextCellLayoutCacheOfMessage(message)

                        cell.configureWithMessage(message, layoutCache: layoutCache, mediaTapAction: mediaTapAction)

                        cell.tapUsernameAction = tapUsernameAction

                        cell.tapFeedAction = { [weak self] feed in
                            self?.tryShowConversationWithFeed(feed)
                        }

                        cell.tapOpenGraphURLAction = { [weak self] URL in
                            if !URL.yep_matchSharedFeed({ [weak self] feed in self?.tryShowConversationWithFeed(feed) }) {
                                self?.yep_openURL(URL)
                            }
                        }

                        return cell
                        
                    } else {
                        let cell: ChatRightTextCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                        prepareCell(cell)

                        let layoutCache = chatTextCellLayoutCacheOfMessage(message)

                        cell.configureWithMessage(message, layoutCache: layoutCache, mediaTapAction: mediaTapAction)

                        cell.tapUsernameAction = tapUsernameAction

                        cell.tapFeedAction = { [weak self] feed in
                            self?.tryShowConversationWithFeed(feed)
                        }

                        return cell
                    }
                }
            }
        }
    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .LoadPrevious:
            break

        case .Message:
            guard let message = messages[safe: (displayedMessagesRange.location + indexPath.item)] else {
                return
            }

            if message.mediaType == MessageMediaType.Text.rawValue {
                tryDetectOpenGraphForMessage(message)
            }
        }
    }

    /*
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .LoadPrevious:
            let cell: LoadMoreCollectionViewCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
            return cell

        case .Message:

            guard let message = messages[safe: (displayedMessagesRange.location + indexPath.item)] else {
                println("🐌 Conversation: message NOT found!")

                let cell: ChatSectionDateCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                cell.sectionDateLabel.text = "🐌"

                return cell
            }

            if message.mediaType == MessageMediaType.SectionDate.rawValue {

                let cell: ChatSectionDateCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                return cell
            }

            guard let sender = message.fromFriend else {

                if message.blockedByRecipient {
                    let cell: ChatTextIndicatorCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    return cell
                }

                println("🐌🐌 Conversation: message has NOT fromFriend!")

                let cell: ChatSectionDateCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                cell.sectionDateLabel.text = "🐌🐌"

                return cell
            }

            if sender.friendState != UserFriendState.Me.rawValue { // from Friend

                switch message.mediaType {

                case MessageMediaType.Image.rawValue:

                    let cell: ChatLeftImageCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    return cell

                case MessageMediaType.Audio.rawValue:

                    let cell: ChatLeftAudioCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    return cell

                case MessageMediaType.Video.rawValue:

                    let cell: ChatLeftVideoCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    return cell

                case MessageMediaType.Location.rawValue:

                    let cell: ChatLeftLocationCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    return cell

                case MessageMediaType.SocialWork.rawValue:

                    let cell: ChatLeftSocialWorkCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    return cell
                    
//                case MessageMediaType.ShareFeed.rawValue:
//                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftShareFeedCellIdentifier, forIndexPath: indexPath) as! LeftShareFeedCell
//                    return cell
                    
                default:

                    if message.deletedByCreator {
                        let cell: ChatTextIndicatorCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                        return cell

                    } else {
                        if message.openGraphInfo != nil {
                            let cell: ChatLeftTextURLCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                            return cell

                        } else {
                            let cell: ChatLeftTextCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                            return cell
                        }
                    }
                }

            } else { // from Me

                switch message.mediaType {

                case MessageMediaType.Image.rawValue:

                    let cell: ChatRightImageCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    return cell

                case MessageMediaType.Audio.rawValue:

                    let cell: ChatRightAudioCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    return cell

                case MessageMediaType.Video.rawValue:

                    let cell: ChatRightVideoCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    return cell

                case MessageMediaType.Location.rawValue:

                    let cell: ChatRightLocationCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    return cell

                default:

                    if message.openGraphInfo != nil {
                        let cell: ChatRightTextURLCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                        return cell

                    } else {
                        let cell: ChatRightTextCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                        return cell
                    }
                }
            }
        }
    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .LoadPrevious:
            break

        case .Message:
            guard let message = messages[safe: (displayedMessagesRange.location + indexPath.item)] else {
                return
            }

            if message.mediaType == MessageMediaType.SectionDate.rawValue {

                if let cell = cell as? ChatSectionDateCell {
                    cell.configureWithMessage(message)
                }

                return
            }

            guard let sender = message.fromFriend else {

                if message.blockedByRecipient {
                    if let cell = cell as? ChatTextIndicatorCell {
                        cell.configureWithMessage(message, indicateType: .BlockedByRecipient)
                    }
                }

                return
            }

            if let cell = cell as? ChatBaseCell {

                if let _ = self.conversation.withGroup {
                    cell.inGroup = true
                } else {
                    cell.inGroup = false
                }

                cell.tapAvatarAction = { [weak self] user in
                    self?.performSegueWithIdentifier("showProfile", sender: user)
                }

                cell.deleteMessageAction = { [weak self] in
                    self?.deleteMessageAtIndexPath(message, indexPath: indexPath)
                }

                cell.reportMessageAction = { [weak self] in
                    self?.report(.Message(messageID: message.messageID))
                }
            }

            if sender.friendState != UserFriendState.Me.rawValue { // from Friend

                switch message.mediaType {

                case MessageMediaType.Image.rawValue:

                    if let cell = cell as? ChatLeftImageCell {

                        cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                            if message.downloadState == MessageDownloadState.Downloaded.rawValue {

                                if let messageTextView = self?.messageToolbar.messageTextView {
                                    if messageTextView.isFirstResponder() {
                                        self?.messageToolbar.state = .Default
                                        return
                                    }
                                }

                                self?.tryShowMessageMediaFromMessage(message)

                            } else {
                                //YepAlert.alertSorry(message: NSLocalizedString("Please wait while the image is not ready!", comment: ""), inViewController: self)
                            }
                        })
                    }

                case MessageMediaType.Audio.rawValue:

                    if let cell = cell as? ChatLeftAudioCell {

                        let audioPlayedDuration = audioPlayedDurationOfMessage(message)

                        cell.configureWithMessage(message, audioPlayedDuration: audioPlayedDuration, audioBubbleTapAction: { [weak self] in

                            if message.downloadState == MessageDownloadState.Downloaded.rawValue {
                                self?.playMessageAudioWithMessage(message)

                            } else {
                                //YepAlert.alertSorry(message: NSLocalizedString("Please wait while the audio is not ready!", comment: ""), inViewController: self)
                            }
                        })
                    }

                case MessageMediaType.Video.rawValue:

                    if let cell = cell as? ChatLeftVideoCell {

                        cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                            if message.downloadState == MessageDownloadState.Downloaded.rawValue {

                                if let messageTextView = self?.messageToolbar.messageTextView {
                                    if messageTextView.isFirstResponder() {
                                        self?.messageToolbar.state = .Default
                                        return
                                    }
                                }

                                self?.tryShowMessageMediaFromMessage(message)

                            } else {
                                //YepAlert.alertSorry(message: NSLocalizedString("Please wait while the video is not ready!", comment: ""), inViewController: self)
                            }
                        })
                    }

                case MessageMediaType.Location.rawValue:

                    if let cell = cell as? ChatLeftLocationCell {

                        cell.configureWithMessage(message, mediaTapAction: {
                            if let coordinate = message.coordinate {
                                let locationCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
                                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: locationCoordinate, addressDictionary: nil))
                                mapItem.name = message.textContent
                                /*
                                let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                                mapItem.openInMapsWithLaunchOptions(launchOptions)
                                */
                                mapItem.openInMapsWithLaunchOptions(nil)
                            }
                        })
                    }

                case MessageMediaType.SocialWork.rawValue:

                    if let cell = cell as? ChatLeftSocialWorkCell {
                        cell.configureWithMessage(message)

                        cell.createFeedAction = { [weak self] socialWork in

                            self?.performSegueWithIdentifier("presentNewFeed", sender: socialWork)
                        }
                    }

                default:

                    if message.deletedByCreator {
                        if let cell = cell as? ChatTextIndicatorCell {
                            cell.configureWithMessage(message, indicateType: .RecalledMessage)
                        }

                    } else {
                        if message.openGraphInfo != nil {

                            if let cell = cell as? ChatLeftTextURLCell {

                                let layoutCache = chatTextCellLayoutCacheOfMessage(message)

                                cell.configureWithMessage(message, layoutCache: layoutCache)

                                cell.tapUsernameAction = tapUsernameAction

                                cell.tapFeedAction = { [weak self] feed in
                                    self?.tryShowConversationWithFeed(feed)
                                }

                                cell.tapOpenGraphURLAction = { [weak self] URL in
                                    if !URL.yep_matchSharedFeed({ [weak self] feed in self?.tryShowConversationWithFeed(feed) }) {
                                        self?.yep_openURL(URL)
                                    }
                                }
                            }

                        } else {

                            if let cell = cell as? ChatLeftTextCell {

                                let layoutCache = chatTextCellLayoutCacheOfMessage(message)

                                cell.configureWithMessage(message, layoutCache: layoutCache)

                                cell.tapUsernameAction = tapUsernameAction

                                cell.tapFeedAction = { [weak self] feed in
                                    self?.tryShowConversationWithFeed(feed)
                                }
                            }
                        }

                        tryDetectOpenGraphForMessage(message)
                    }
                }

            } else { // from Me

                switch message.mediaType {

                case MessageMediaType.Image.rawValue:

                    if let cell = cell as? ChatRightImageCell {

                        cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                            if message.sendState == MessageSendState.Failed.rawValue {

                                YepAlert.confirmOrCancel(title: NSLocalizedString("title.action", comment: ""), message: NSLocalizedString("Resend image?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                                    resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                                        self?.promptSendMessageFailed(
                                            reason: reason,
                                            errorMessage: errorMessage,
                                            reserveErrorMessage: NSLocalizedString("Failed to resend image!\nPlease make sure your device is connected to the Internet.", comment: "")
                                        )

                                    }, completion: { success in
                                        println("resendImage: \(success)")
                                    })

                                }, cancelAction: {
                                })

                            } else {
                                if let messageTextView = self?.messageToolbar.messageTextView {
                                    if messageTextView.isFirstResponder() {
                                        self?.messageToolbar.state = .Default
                                        return
                                    }
                                }

                                self?.tryShowMessageMediaFromMessage(message)
                            }
                        })
                    }

                case MessageMediaType.Audio.rawValue:

                    if let cell = cell as? ChatRightAudioCell {

                        let audioPlayedDuration = audioPlayedDurationOfMessage(message)

                        cell.configureWithMessage(message, audioPlayedDuration: audioPlayedDuration, audioBubbleTapAction: { [weak self] in

                            if message.sendState == MessageSendState.Failed.rawValue {

                                YepAlert.confirmOrCancel(title: NSLocalizedString("title.action", comment: ""), message: NSLocalizedString("Resend audio?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                                    resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                                        self?.promptSendMessageFailed(
                                            reason: reason,
                                            errorMessage: errorMessage,
                                            reserveErrorMessage: NSLocalizedString("Failed to resend audio!\nPlease make sure your device is connected to the Internet.", comment: "")
                                        )

                                    }, completion: { success in
                                        println("resendAudio: \(success)")
                                    })

                                }, cancelAction: {
                                })

                                return
                            }

                            self?.playMessageAudioWithMessage(message)
                        })
                    }

                case MessageMediaType.Video.rawValue:

                    if let cell = cell as? ChatRightVideoCell {

                        cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                            if message.sendState == MessageSendState.Failed.rawValue {

                                YepAlert.confirmOrCancel(title: NSLocalizedString("title.action", comment: ""), message: NSLocalizedString("Resend video?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                                    resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                                        self?.promptSendMessageFailed(
                                            reason: reason,
                                            errorMessage: errorMessage,
                                            reserveErrorMessage: NSLocalizedString("Failed to resend video!\nPlease make sure your device is connected to the Internet.", comment: "")
                                        )

                                    }, completion: { success in
                                        println("resendVideo: \(success)")
                                    })

                                }, cancelAction: {
                                })

                            } else {
                                if let messageTextView = self?.messageToolbar.messageTextView {
                                    if messageTextView.isFirstResponder() {
                                        self?.messageToolbar.state = .Default
                                        return
                                    }
                                }

                                self?.tryShowMessageMediaFromMessage(message)
                            }
                        })
                    }

                case MessageMediaType.Location.rawValue:

                    if let cell = cell as? ChatRightLocationCell {

                        cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                            if message.sendState == MessageSendState.Failed.rawValue {

                                YepAlert.confirmOrCancel(title: NSLocalizedString("title.action", comment: ""), message: NSLocalizedString("Resend location?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                                    resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                                        self?.promptSendMessageFailed(
                                            reason: reason,
                                            errorMessage: errorMessage,
                                            reserveErrorMessage: NSLocalizedString("Failed to resend location!\nPlease make sure your device is connected to the Internet.", comment: "")
                                        )

                                    }, completion: { success in
                                        println("resendLocation: \(success)")
                                    })

                                }, cancelAction: {
                                })

                            } else {
                                if let coordinate = message.coordinate {
                                    let locationCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
                                    let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: locationCoordinate, addressDictionary: nil))
                                    mapItem.name = message.textContent
                                    /*
                                    let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                                    mapItem.openInMapsWithLaunchOptions(launchOptions)
                                    */
                                    mapItem.openInMapsWithLaunchOptions(nil)
                                }
                            }
                        })
                    }

                default:

                    let mediaTapAction: () -> Void = { [weak self] in

                        guard message.sendState == MessageSendState.Failed.rawValue else {
                            return
                        }

                        YepAlert.confirmOrCancel(title: NSLocalizedString("title.action", comment: ""), message: NSLocalizedString("Resend text?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                            resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                                self?.promptSendMessageFailed(
                                    reason: reason,
                                    errorMessage: errorMessage,
                                    reserveErrorMessage: NSLocalizedString("Failed to resend text!\nPlease make sure your device is connected to the Internet.", comment: "")
                                )

                            }, completion: { success in
                                println("resendText: \(success)")
                            })

                        }, cancelAction: {
                        })
                    }

                    if message.openGraphInfo != nil {

                        if let cell = cell as? ChatRightTextURLCell {

                            let layoutCache = chatTextCellLayoutCacheOfMessage(message)

                            cell.configureWithMessage(message, layoutCache: layoutCache, mediaTapAction: mediaTapAction)

                            cell.tapUsernameAction = tapUsernameAction

                            cell.tapFeedAction = { [weak self] feed in
                                self?.tryShowConversationWithFeed(feed)
                            }

                            cell.tapOpenGraphURLAction = { [weak self] URL in
                                if !URL.yep_matchSharedFeed({ [weak self] feed in self?.tryShowConversationWithFeed(feed) }) {
                                    self?.yep_openURL(URL)
                                }
                            }
                        }

                    } else {

                        if let cell = cell as? ChatRightTextCell {

                            let layoutCache = chatTextCellLayoutCacheOfMessage(message)

                            cell.configureWithMessage(message, layoutCache: layoutCache, mediaTapAction: mediaTapAction)

                            cell.tapUsernameAction = tapUsernameAction

                            cell.tapFeedAction = { [weak self] feed in
                                self?.tryShowConversationWithFeed(feed)
                            }
                        }
                    }

                    tryDetectOpenGraphForMessage(message)
                }
            }
        }
    }
     */

    private func tryDetectOpenGraphForMessage(message: Message) {

        guard !message.openGraphDetected else {
            return
        }

        func markMessageOpenGraphDetected() {
            guard !message.invalidated else {
                return
            }

            let _ = try? realm.write {
                message.openGraphDetected = true
            }
        }

        let text = message.textContent
        guard let fisrtURL = text.yep_embeddedURLs.first else {
            markMessageOpenGraphDetected()
            return
        }

        openGraphWithURL(fisrtURL, failureHandler: { reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            SafeDispatch.async {
                markMessageOpenGraphDetected()
            }

        }, completion: { _openGraph in
            println("message_openGraph: \(_openGraph)")

            guard _openGraph.isValid else {
                return
            }

            SafeDispatch.async { [weak self] in

                guard let strongSelf = self else {
                    return
                }

                let openGraphInfo = OpenGraphInfo(URLString: _openGraph.URL.absoluteString, siteName: _openGraph.siteName ?? "", title: _openGraph.title ?? "", infoDescription: _openGraph.description ?? "", thumbnailImageURLString: _openGraph.previewImageURLString ?? "")

                let _ = try? strongSelf.realm.write {
                    strongSelf.realm.add(openGraphInfo, update: true)
                    message.openGraphInfo = openGraphInfo
                }

                markMessageOpenGraphDetected()

                // update UI
                strongSelf.clearHeightOfMessageWithKey(message.messageID)

                if let index = strongSelf.messages.indexOf(message) {
                    let realIndex = index - strongSelf.displayedMessagesRange.location
                    let indexPath = NSIndexPath(forItem: realIndex, inSection: Section.Message.rawValue)
                    strongSelf.conversationCollectionView.reloadItemsAtIndexPaths([indexPath])

                    // only for latest one need to scroll
                    if index == (strongSelf.displayedMessagesRange.location + strongSelf.displayedMessagesRange.length - 1) {
                        strongSelf.conversationCollectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
                    }
                }
            }
        })
    }

    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .LoadPrevious:
            guard let cell = cell as? LoadMoreCollectionViewCell else {
                break
            }

            cell.loadingActivityIndicator.stopAnimating()
            
        case .Message:
            break
        }
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .LoadPrevious:
            return CGSize(width: collectionViewWidth, height: 20)

        case .Message:
            guard let message = messages[safe: (displayedMessagesRange.location + indexPath.item)] else {
                return CGSize(width: collectionViewWidth, height: 0)
            }

            let height = heightOfMessage(message)

            return CGSize(width: collectionViewWidth, height: height)
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        guard let section = Section(rawValue: section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .LoadPrevious:
            return UIEdgeInsetsZero

        case .Message:
            return UIEdgeInsets(top: 5, left: 0, bottom: sectionInsetBottom, right: 0)
        }
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        switch messageToolbar.state {

        case .BeginTextInput, .TextInputing:
            messageToolbar.state = .Default

        default:
            break
        }
    }

    // MARK: UIScrollViewDelegate

    func scrollViewWillBeginDragging(scrollView: UIScrollView) {

        let location = scrollView.panGestureRecognizer.locationInView(view)
        dragBeginLocation = location
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {

        //println("contentInset: \(scrollView.contentInset)")
        //println("contentOffset: \(scrollView.contentOffset)")

        if let dragBeginLocation = dragBeginLocation {
            let location = scrollView.panGestureRecognizer.locationInView(view)
            let deltaY = location.y - dragBeginLocation.y

            if deltaY < -30 {
                tryFoldFeedView()
            }
        }

        func tryTriggerLoadPrevious() {

            guard !noMorePreviousMessages else {
                return
            }

            guard scrollView.yep_isAtTop && (scrollView.dragging || scrollView.decelerating) else {
                return
            }

            let indexPath = NSIndexPath(forItem: 0, inSection: Section.LoadPrevious.rawValue)
            guard conversationCollectionViewHasBeenMovedToBottomOnce, let cell = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? LoadMoreCollectionViewCell else {
                return
            }

            guard !isLoadingPreviousMessages else {
                cell.loadingActivityIndicator.stopAnimating()
                return
            }

            cell.loadingActivityIndicator.startAnimating()

            delay(0.5) { [weak self] in
                self?.tryLoadPreviousMessages { [weak cell] in
                    cell?.loadingActivityIndicator.stopAnimating()
                }
            }
        }

        tryTriggerLoadPrevious()
    }

    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {

        dragBeginLocation = nil
    }
}

